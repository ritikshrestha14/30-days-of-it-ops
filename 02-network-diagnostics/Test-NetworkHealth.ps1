[CmdletBinding()]
param()

function Write-StatusBadge {
    param (
        [string]$TestName,
        [bool]$Success,
        [string]$Details
    )
    $statusText  = if ($Success) { "[PASS]" } else { "[FAIL]" }
    $statusColor = if ($Success) { "Green" } else { "Red" }
    Write-Host -NoNewline "$statusText " -ForegroundColor $statusColor
    Write-Host -NoNewline "${TestName}: " -ForegroundColor Cyan
    Write-Host "$Details"
}

Write-Host "`n=== Enterprise Network Health Diagnostic Suite ===" -ForegroundColor Yellow
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# 1. Local Adapter Check
$netConfig = Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object -First 1

if ($netConfig -and $netConfig.IPv4Address) {
    $alias = $netConfig.InterfaceAlias
    $ip    = $netConfig.IPv4Address.IPAddress
    Write-StatusBadge -TestName "Local Adapter" -Success $true -Details "$alias (IP: $ip)"
} else {
    Write-StatusBadge -TestName "Local Adapter" -Success $false -Details "No active adapter with a default gateway found"
}

# 2. Default Gateway Check
$gateway = if ($defaultRoute) { $defaultRoute.NextHop } else {$null }
if ($gateway -and$gateway -ne "0.0.0.0") {
    $gwPing = Test-Connection -ComputerName $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue
    Write-StatusBadge -TestName "Default Gateway" -Success ([bool]$gwPing) -Details "Gateway IP: $gateway"
} else {
    Write-StatusBadge -TestName "Default Gateway" -Success $false -Details "No default route found"
}

# 3. External WAN Ping
$wanPing = Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
Write-StatusBadge -TestName "Internet (ICMP)" -Success ([bool]$wanPing) -Details "Target: 1.1.1.1 (Cloudflare Anycast)"

# 4. DNS Resolution Check
$dnsResult = Resolve-DnsName -Name "google.com" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dnsResult) {
    $resolvedIP = if ($dnsResult.IPAddress) { $dnsResult.IPAddress } else {$dnsResult.NameHost }
    Write-StatusBadge -TestName "DNS Resolution" -Success $true -Details "Resolved google.com to $resolvedIP"
} else {
    Write-StatusBadge -TestName "DNS Resolution" -Success $false -Details "Failed to resolve external hostnames via DNS"
}

# 5. Outbound Port Egress
$ports = @(80, 443)
foreach ($p in $ports) {
    $tcpCheck = Test-NetConnection -ComputerName "google.com" -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-StatusBadge -TestName "Port Egress (TCP $p)" -Success ([bool]$tcpCheck) -Details "Target: google.com:$p"
}

Write-Host "`n=== Diagnostic Run Complete ===`n" -ForegroundColor Yellow


Write-Host "`n=== Cross-Platform Network Diagnostic Suite ===" -ForegroundColor Yellow
Write-Host "Runtime OS : $($PSVersionTable.OS)`n"

# We test a known good domain, and a fake one to ensure our error handling works
$targets = @("github.com", "google.com", "fake-bad-domain.local")
$port = 443

foreach ($target in $targets) {
    
    $resolvedIP = "Unresolved"
    $portStatus = "Closed/Blocked"

    # 1. Test DNS Resolution
    try {
        $dns = [System.Net.Dns]::GetHostAddresses($target)
        if ($dns.Count -gt 0) {
            $resolvedIP = $dns[0].IPAddressToString
        }
    } catch {
        $resolvedIP = "DNS_FAILED"
    }

    # 2. Test TCP Socket (Only attempt if DNS didn't fail)
    if ($resolvedIP -ne "DNS_FAILED") {
        try {
            $tcp = [System.Net.Sockets.TcpClient]::new($target, $port)
            if ($tcp.Connected) {
                $portStatus = "OPEN"
                $tcp.Close()
            }
        } catch {
            $portStatus = "BLOCKED"
        }
    }

    # 3. Output structured telemetry
    [PSCustomObject]@{
        TargetHost = $target
        ResolvedIP = $resolvedIP
        TcpPort    = $port
        Status     = $portStatus
    }
}
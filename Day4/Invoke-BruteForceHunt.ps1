Write-Host "`n=== Security Log Brute-Force Detector ===`n" -ForegroundColor Yellow

$logPath = "./Day4/auth_logs.csv"
$threshold = 3

# 1. Sandbox Generator: Create a mock CSV log file to test against
if (-not (Test-Path $logPath)) {
    $mockData = @"
Time,User,IP,Status
08:00,admin,192.168.1.5,Failed
08:05,admin,192.168.1.5,Failed
08:10,root,10.0.0.8,Success
08:15,guest,192.168.1.5,Failed
08:20,admin,172.16.0.10,Failed
08:25,admin,192.168.1.5,Failed
08:30,admin,172.16.0.10,Success
"@
    Set-Content -Path $logPath -Value $mockData
    Write-Host "Created mock auth log at $logPath`n" -ForegroundColor Cyan
}

# 2. Ingest the raw CSV data into native PowerShell objects
$logs = Import-Csv -Path $logPath

# 3. Filter for Failed attempts only
$failedLogs = $logs | Where-Object { $_.Status -eq "Failed" }

# 4. Group the failures by Source IP
$groupedIPs = $failedLogs | Group-Object -Property IP

# 5. Process the groups and hunt for threshold breaches
foreach ($group in $groupedIPs) {
    
    $ip = $group.Name
    $failCount = $group.Count
    
    # Check if the failure count meets or exceeds our defined threshold
    $isBruteForce = $failCount -ge $threshold
    
    # Output structured threat intelligence
    [PSCustomObject]@{
        SourceIP       = $ip
        FailedAttempts = $failCount
        ThresholdMet   = $isBruteForce
        Action         = if ($isBruteForce) { "BLOCK_IP" } else { "MONITOR" }
    }
}
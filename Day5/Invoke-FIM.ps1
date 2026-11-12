Write-Host "`n=== File Integrity Monitor (FIM) ===`n" -ForegroundColor Yellow

$targetFile = "./Day5/system_config.ini"
$baselineFile = "./Day5/system_config.hash"

# 1. Sandbox Generator: Create a mock config file if it doesn't exist
if (-not (Test-Path $targetFile)) {
    Set-Content -Path $targetFile -Value "AdminAccess=Restricted`nMaxConnections=100"
    Write-Host "Created mock config file at $targetFile" -ForegroundColor Cyan
}

# 2. Calculate the Current Cryptographic Hash
$currentHash = (Get-FileHash -Path $targetFile -Algorithm SHA256).Hash

$status = "UNKNOWN"
$baselineHash = "NONE"

# 3. FIM Logic: Compare against Baseline OR Create Baseline
if (Test-Path $baselineFile) {
    # Baseline exists: Read it and compare
    $baselineHash = Get-Content -Path $baselineFile
    
    if ($currentHash -eq $baselineHash) {
        $status = "INTACT"
        $statusColor = "Green"
    } else {
        $status = "TAMPERED - HASH MISMATCH"
        $statusColor = "Red"
        Write-Host "WARNING: INTEGRITY BREACH DETECTED ON $targetFile!" -ForegroundColor Red
    }
} else {
    # No baseline exists: This is the first run. Create the baseline.
    Set-Content -Path $baselineFile -Value $currentHash
    $status = "BASELINE_CREATED"
    $statusColor = "Cyan"
    $baselineHash = $currentHash
}

# 4. Output structured telemetry
# We use .Substring(0,15) to truncate the giant hash so it fits nicely in your terminal table
[PSCustomObject]@{
    TargetFile    = $targetFile.Split('/')[-1]
    Status        = $status
    CurrentHash   = $currentHash.Substring(0, 15) + "..."
    BaselineHash  = $baselineHash.Substring(0, 15) + "..."
}
Write-Host "`n=== Endpoint Cache Remediation ===`n" -ForegroundColor Yellow

$cacheDir = "./Day3/mock-cache"

# 1. Sandbox Generator: Create fake junk files to test safely
if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir | Out-Null
    New-Item -Path "$cacheDir/old_data.tmp" -Value ("X" * 2MB) | Out-Null
    New-Item -Path "$cacheDir/debug.log" -Value ("Y" * 1MB) | Out-Null
    New-Item -Path "$cacheDir/database.lock" -Value "ACTIVE" | Out-Null
    Write-Host "Created 3MB of mock cache files in $cacheDir" -ForegroundColor Cyan
}

# 2. Gather all files in the target directory
$allFiles = Get-ChildItem -Path $cacheDir -File

# 3. Filter safely based on extensions
$removableFiles = $allFiles | Where-Object { $_.Extension -in @(".tmp", ".log", ".cache") }
$lockedFiles    = $allFiles | Where-Object { $_.Extension -eq ".lock" }

$bytesReclaimed = 0
$filesDeleted   = 0

# 4. Safely delete only the removable files
foreach ($file in $removableFiles) {
    Remove-Item -Path $file.FullName -Force
    $bytesReclaimed += $file.Length
    $filesDeleted++
}

# 5. Math: Convert bytes to MB rounded to 2 decimal places
$reclaimedMB = [math]::Round($bytesReclaimed / 1MB, 2)

# 6. Output structured telemetry report
[PSCustomObject]@{
    TargetDirectory  = $cacheDir
    FilesScanned     = $allFiles.Count
    ProtectedLocks   = $lockedFiles.Count
    FilesDeleted     = $filesDeleted
    ReclaimedSpaceMB = $reclaimedMB
}
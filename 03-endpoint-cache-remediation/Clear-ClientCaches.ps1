<#
.SYNOPSIS
    Automated Endpoint Cache Remediation and Print Spooler Recovery Tool.
.DESCRIPTION
    Performs standard Tier 1/2 endpoint maintenance:
    1. Flushes the local DNS client resolver cache.
    2. Safely stops the Print Spooler, purges stuck print jobs, and restarts the service.
    3. Cleans unlocked user temporary files and calculates reclaimed disk space.
.EXAMPLE
    .\Clear-ClientCaches.ps1 -WhatIf
.EXAMPLE
    .\Clear-ClientCaches.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [switch]$IncludePrintSpooler =$true
)

function Write-RemediationStep {
    param (
        [string]$Action,
        [string]$Status,
        [string]$Color = "Green"
    )
    Write-Host -NoNewline "[$Status] " -ForegroundColor $Color
    Write-Host "$Action"
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "`n=== Endpoint Cache & Spooler Remediation Utility ===" -ForegroundColor Yellow
Write-Host "Timestamp : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Elevation : $(if ($isAdmin) { 'Administrator (Full Remediation)' } else { 'Standard User (Limited Mode)' })`n"

# --- STEP 1: Flush DNS Resolver Cache ---
if ($PSCmdlet.ShouldProcess("Local DNS Client Cache", "Clear-DnsClientCache")) {
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-RemediationStep -Action "Flushed local DNS resolver cache." -Status "DONE" -Color "Green"
    } catch {
        Write-RemediationStep -Action "Failed to flush DNS cache: $($_.Exception.Message)" -Status "ERROR" -Color "Red"
    }
} else {
    Write-RemediationStep -Action "Would flush local DNS resolver cache." -Status "WHATIF" -Color "Cyan"
}

# --- STEP 2: Print Spooler Queue Recovery ---
if ($IncludePrintSpooler) {
    if (-not $isAdmin) {
        Write-RemediationStep -Action "Skipped Print Spooler reset (Requires Administrator privileges)." -Status "SKIP" -Color "DarkYellow"
    } else {
        $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
        if ($PSCmdlet.ShouldProcess($spoolPath, "Stop Spooler, purge stuck jobs, and restart service")) {
            try {
                Stop-Service -Name Spooler -Force -ErrorAction Stop
                Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Start-Service -Name Spooler -ErrorAction Stop
                Write-RemediationStep -Action "Reset Print Spooler service and purged stuck print queue." -Status "DONE" -Color "Green"
            } catch {
                Write-RemediationStep -Action "Print Spooler recovery encountered an error: $($_.Exception.Message)" -Status "ERROR" -Color "Red"
            }
        } else {
            Write-RemediationStep -Action "Would stop Spooler, clear '$spoolPath', and restart Spooler." -Status "WHATIF" -Color "Cyan"
        }
    }
}

# --- STEP 3: User Temp Directory Cleanup ---
$userTemp =$env:TEMP
$filesBefore = Get-ChildItem -Path $userTemp -Recurse -File -ErrorAction SilentlyContinue
$bytesBefore = ($filesBefore | Measure-Object -Property Length -Sum).Sum

if ($PSCmdlet.ShouldProcess($userTemp, "Remove unlocked temporary files")) {
    Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $filesAfter = Get-ChildItem -Path $userTemp -Recurse -File -ErrorAction SilentlyContinue
    $bytesAfter = ($filesAfter | Measure-Object -Property Length -Sum).Sum
    $reclaimedMB = [math]::Round(($bytesBefore -$bytesAfter) / 1MB, 2)
    if ($reclaimedMB -lt 0) {$reclaimedMB = 0 }
    Write-RemediationStep -Action "Cleaned User Temp ($userTemp). Reclaimed: $reclaimedMB MB (Locked files skipped)." -Status "DONE" -Color "Green"
} else {
    $potentialMB = [math]::Round($bytesBefore / 1MB, 2)
    Write-RemediationStep -Action "Would clean User Temp ($userTemp). Total current size: $potentialMB MB." -Status "WHATIF" -Color "Cyan"
}

Write-Host "`n=== Remediation Complete ===`n" -ForegroundColor Yellow


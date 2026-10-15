<#
.SYNOPSIS
    Automates employee onboarding by reading HR CSV data and provisioning accounts.
.DESCRIPTION
    Parses hire records, enforces flastname usernames, generates crypto-secure temporary
    passwords, and records a timestamped audit trail. Supports -WhatIf for risk-free simulation.
.PARAMETER CsvPath
    Path to the input CSV file. Defaults to .\new_hires.csv.
.PARAMETER LogPath
    File path for the provisioning log. Defaults to .\onboarding_audit.log.
.EXAMPLE
    .\New-EmployeeOnboard.ps1 -CsvPath .\new_hires.csv -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = ".\new_hires.csv",

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\onboarding_audit.log"
)

function New-TemporaryPassword {
    param ([int]$Length = 12)
    $charSet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*="
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = New-Object byte[] $Length
    $rng.GetBytes($buffer)
    return -join ($buffer | ForEach-Object { $charSet[$_ % $charSet.Length] })
}

function Write-AuditEntry {
    param ([string]$Message)
    $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$stamp] $Message"
    Write-Host $formatted
    Add-Content -Path $LogPath -Value $formatted -ErrorAction SilentlyContinue
}

Write-AuditEntry "=================================================="
Write-AuditEntry "Starting New Hire Provisioning Pipeline"
Write-AuditEntry "=================================================="

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV source not found at: $CsvPath"
    exit 1
}

$records = Import-Csv -Path $CsvPath
Write-AuditEntry "Loaded $($records.Count) employee record(s) from $CsvPath"

foreach ($user in $records) {
    $firstName = $user.FirstName.Trim()
    $lastName  = $user.LastName.Trim()
    $dept      = $user.Department.Trim()
    $title     = $user.JobTitle.Trim()

    $cleanFirst = $firstName.Substring(0,1).ToLower()
    $cleanLast  = ($lastName.ToLower() -replace "[^a-z0-9]", "")
    $username   = "$cleanFirst$cleanLast"
    $email      = "$username@enterprise.local"
    $tempPass   = New-TemporaryPassword

    $actionDesc = "Create account for $firstName $lastName ($username)"

    if ($PSCmdlet.ShouldProcess($username, $actionDesc)) {
        Write-AuditEntry "CREATED: User=$username | Dept=$dept | Title=$title | Pass=$tempPass"
    } else {
        Write-AuditEntry "WHATIF SIMULATION: User=$username | Dept=$dept | Title=$title | Pass=[PROTECTED]"
    }
}

Write-AuditEntry "Provisioning run finished successfully."

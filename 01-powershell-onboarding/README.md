# Day 01: Automated User Provisioning with REST API Data

## Problem Statement
Manual account creation across disparate IT directories is slow (averaging 15 minutes per endpoint/user), prone to typo errors, and lacks an audit trail required for compliance.

## Solution Architecture
- **Dynamic Data Source:** Ingests realistic employee rosters directly via REST API calls (andomuser.me).
- **Username Sanitization:** Strips non-alphanumeric characters and enforces standard `flastname` corporate conventions.
- **Cryptographic Credentials:** Generates temporary passwords using .NET RandomNumberGenerator to prevent entropy prediction.
- **Operational Safety:** Implements `[CmdletBinding(SupportsShouldProcess)]` for native `-WhatIf` dry-runs.
- **Audit Compliance:** Logs timestamped entries to `onboarding_audit.log`.

## Usage
``powershell
# Dry-run simulation (Safe)
.\New-EmployeeOnboard.ps1 -CsvPath .\new_hires.csv -WhatIf

# Production execution
.\New-EmployeeOnboard.ps1 -CsvPath .\new_hires.csv
``
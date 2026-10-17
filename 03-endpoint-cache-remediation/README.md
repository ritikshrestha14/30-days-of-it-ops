# Day 03: Endpoint Cache & Print Spooler Remediation Utility

## Problem Statement
Stale DNS resolver caches, hung print queues (`Spooler` service locks), and bloated temporary directories (`%TEMP%`) account for a significant portion of routine IT service desk volume. Manual troubleshooting across individual machines is slow and inconsistent.

## Engineering Design
`Clear-ClientCaches.ps1` automates standard client remediation safely:
1. **Privilege-Aware Execution (RBAC):** Detects whether the current session holds local administrator rights. If running standard user credentials, it executes user-space cleanup while cleanly skipping privileged service operations (`Spooler`).
2. **Simulation Mode (`-WhatIf`):** Leverages `SupportsShouldProcess` to preview actions and quantify reclaimable storage without modifying the filesystem.
3. **Resilient Cleanup & Metrics:** Uses `-ErrorAction SilentlyContinue` to safely bypass in-use/locked application files in `%TEMP%` while computing and logging actual disk space reclaimed in MB.

## Usage
```powershell
# Dry-run preview
.\Clear-ClientCaches.ps1 -WhatIf

# Live remediation
.\Clear-ClientCaches.ps1
```

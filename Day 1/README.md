# Day 01: Zero-Touch Identity Onboarding

## Objective
Automate user account provisioning by pulling JSON records from a REST API and sanitizing strings for Active Directory compatibility.

## Technical Concepts Applied
- **REST API Ingestion:** Used `Invoke-RestMethod` to convert JSON endpoints into native PowerShell objects.
- **Regex Input Sanitization:** Handled messy human data by stripping honorific titles (`-replace '^(Mr\.|Mrs\.)\s+'`) and isolating core name strings.
- **Pipeline Output:** Generated structured `[PSCustomObject]` records for pipeline sorting and exporting.

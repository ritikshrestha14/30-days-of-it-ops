# \# Day 02: Enterprise Network Health Diagnostic Suite

# 

# \## Problem Statement

# End-users frequently report network connectivity failures with vague complaints like "The internet is down." Technicians often waste time troubleshooting high-level applications before verifying foundational OSI Layer 1â€“3 connectivity.

# 

# \## Diagnostic Methodology (OSI Model Alignment)

# This tool executes an inside-out triage strategy mapped to the OSI network stack:

# 

# 1\. \*\*Local Layer 2/3 (Adapter \& IP):\*\* Identifies the active network interface via `Get-NetIPConfiguration` and checks for valid IPv4 allocation (ruling out `169.254.x.x` APIPA/DHCP failures).

# 2\. \*\*LAN Layer 3 (Default Gateway):\*\* Queries the routing table (`0.0.0.0/0`) and pings the local router gateway to confirm LAN/Wi-Fi integrity.

# 3\. \*\*WAN Layer 3 (External IP):\*\* Sends an ICMP echo request directly to public Anycast IP (`1.1.1.1`) to verify outbound routing independent of DNS.

# 4\. \*\*Layer 7 (DNS Resolution):\*\* Resolves external FQDNs (`google.com`) via `Resolve-DnsName` to isolate DNS server issues.

# 5\. \*\*Layer 4 (Transport / Port Egress):\*\* Performs TCP 3-way handshakes on ports `80` (HTTP) and `443` (HTTPS) using `Test-NetConnection` to verify firewall egress.

# 

# \## Usage

# ```powershell

# .\\Test-NetworkHealth.ps1




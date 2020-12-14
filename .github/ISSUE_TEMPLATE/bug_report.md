---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Please describe the steps to reproduce the behavior, for example:

1. Run command or script "..."
2. Click on or go to "..."
3. Enable or toggle "..."
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Actual behavior**
Describe what is the actual result as opposed to "Expected behavior"

**Environment information:**
Please provide detailed information about your system as needed:

- Firewall version (look into: Config\ProjectSettings.ps1 and search for "ProjectVersion" variable)
- OS: [ex. Windows 10 Pro v1903] (run: Winver.exe)
- PowerShell: [ex. PowerShell core 7.1.0] (run: $PSVersionTable)
- Network Adapter: (run: Get-NetAdapter | ? HardwareInterface | select *)
- IP Configuration: (run: ipconfig /all)

Any other system information which you consider relevant for the problem, such as:

- firewall or audit logs
- ping output
- DNS query or tracert results etc.
- Network related software you use such as: VPN, DNS, proxy etc...

**Additional context**
Add any other context about the problem here.

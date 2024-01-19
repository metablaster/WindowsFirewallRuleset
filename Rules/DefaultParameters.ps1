
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS"] = WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

#
# Default parameters for functions used in rule scripts
#

$PSDefaultParameterValues["Confirm-Installation:CimSession"] = $CimServer
$PSDefaultParameterValues["Confirm-Installation:Session"] = $SessionInstance
$PSDefaultParameterValues["Test-ExecutableFile:Session"] = $SessionInstance
$PSDefaultParameterValues["Get-SDDL:CimSession"] = $CimServer
$PSDefaultParameterValues["Invoke-Process:NoNewWindow"] = $true
$PSDefaultParameterValues["Invoke-Process:ArgumentList"] = "/target:computer"
$PSDefaultParameterValues["Invoke-Process:Session"] = $SessionInstance
$PSDefaultParameterValues["Get-GroupPrincipal:CimSession"] = $CimServer
$PSDefaultParameterValues["Get-AppCapability:Session"] = $SessionInstance
$PSDefaultParameterValues["Get-UserApp:Session"] = $SessionInstance
$PSDefaultParameterValues["Get-SystemApp:Session"] = $SessionInstance

# NOTE: The following commands in rule scripts require session parameter or remoting
# Invoke-Command
# Get-ChildItem
# [System.Environment]::ExpandEnvironmentVariables
# Get-VSSetupInstance
# Get-InterfaceBroadcast

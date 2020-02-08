
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\Modules\System
Test-SystemRequirements $VersionCheck

# Includes
Import-Module -Name $PSScriptRoot\Modules\FirewallModule

# Setting up profile seem to be slow, tell user what is going on
Write-Host "Reseting Firewall to previous state..."

#
# Default setup for all profiles
#
Set-NetFirewallProfile -All -Confirm:$Execute -Whatif:$Debug -PolicyStore $PolicyStore `
-Enabled NotConfigured -DefaultInboundAction NotConfigured -DefaultOutboundAction NotConfigured -AllowInboundRules NotConfigured `
-AllowLocalFirewallRules NotConfigured -AllowLocalIPsecRules NotConfigured -AllowUnicastResponseToMulticast NotConfigured `
-NotifyOnListen NotConfigured -EnableStealthModeForIPsec NotConfigured `
-LogAllowed NotConfigured -LogBlocked NotConfigured -LogIgnored NotConfigured -LogMaxSizeKilobytes 4096 `
-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log"

#
# Remove all the rules
#
Remove-NetFirewallRule -All -PolicyStore $PolicyStore -ErrorAction SilentlyContinue

Write-Host "Firewall reset is done!"
Write-Note "If internet conectivity problem remains, please rebot system"


<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

#
# Import global variables
#
. "$PSScriptRoot\Modules\GlobalVariables.ps1"

# Setting up profile seem to be slow, tell user what is going on
Write-Host "Setting up Firewall profiles..."

#
# Default setup for all profiles
#
Set-NetFirewallProfile -All -Confirm:$Execute -Whatif:$Debug -PolicyStore $PolicyStore `
-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
-AllowLocalFirewallRules False -AllowLocalIPsecRules False -AllowUnicastResponseToMulticast True `
-NotifyOnListen True -EnableStealthModeForIPsec True `
-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log"

#
# Override for public profile
#
Set-NetFirewallProfile -Name Public -Confirm:$Execute -Whatif:$Debug -PolicyStore $PolicyStore `
-AllowUnicastResponseToMulticast False


<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

. $PSScriptRoot\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Firewall profile setup
#

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up public firewall profile..." @Logs

Set-NetFirewallProfile -Profile Public -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast False `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\PublicFirewall.log" @Logs

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up private firewall profile..." @Logs

Set-NetFirewallProfile -Profile Private -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\PrivateFirewall.log" @Logs

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags "User" -MessageData "INFO: Setting up domain firewall profile..." @Logs

Set-NetFirewallProfile -Profile Domain -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes 1024 `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "%SystemRoot%\System32\LogFiles\Firewall\DomainFirewall.log" @Logs

Write-Warning -MessageData "For maximum security choose 'Public' network profile" @Logs

Set-NetworkProfile @Logs

Update-Logs


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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

<#
.SYNOPSIS
Inbound firewall rules for Windows remoting programs and services

.DESCRIPTION
Rules which apply to Windows remoting programs and services,
which are not handled by predefined rules

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\RemoteWindows.ps1

.INPUTS
None. You cannot pipe objects to RemoteWindows.ps1

.OUTPUTS
None. RemoteWindows.ps1 does not generate any output

.NOTES
NOTE: The following rules from predefined groups are used:
1. Remote Desktop
2. Remote Desktop (WebSocket)
3. Windows remote management (PowerShell remoting)
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Remote Windows"
$Accept = "Inbound rules for remote Windows will be loaded, required for services such as remote desktop or remote registry"
$Deny = "Skip operation, inbound rules for remote Windows will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Predefined rules for remote desktop, here split for private and public profile
#

$Program = "%SystemRoot%\System32\RdpSa.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Remote desktop - Shadow" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy DeferToApp `
		-InterfaceType $DefaultInterface `
		-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing
Remote Desktop session. " | Format-RuleOutput

	New-NetFirewallRule -DisplayName "Remote desktop - Shadow" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress LocalSubnet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy DeferToApp `
		-InterfaceType $DefaultInterface `
		-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing
Remote Desktop session. " | Format-RuleOutput
}

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3387 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3387 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3392 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3392 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-RuleOutput

# NOTE: PS remoting, both IPv4 and IPv6
New-NetFirewallRule -DisplayName "PowerShell remoting HTTP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5985 -RemotePort Any `
	-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Rule for PowerShell remoting to allow connections from remote hosts" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "PowerShell remoting HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5986 -RemotePort Any `
	-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Rule for PowerShell remoting to allow connections from remote hosts" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "PowerShell remoting HTTP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5985 -RemotePort Any `
	-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Rule for PowerShell remoting to allow connections from remote hosts" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "PowerShell remoting HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5986 -RemotePort Any `
	-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Rule for PowerShell remoting to allow connections from remote hosts" |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

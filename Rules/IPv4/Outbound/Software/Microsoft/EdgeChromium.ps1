
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
Outbound firewall rules for EdgeChromium

.DESCRIPTION
Outbound firewall rules for Microsoft Edge Chromium browser

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.


.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\EdgeChromium.ps1

.INPUTS
None. You cannot pipe objects to EdgeChromium.ps1

.OUTPUTS
None. EdgeChromium.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft - Edge Chromium"
$Accept = "Outbound rules for Edge Chromium browser will be loaded, recommended if Edge Chromium is installed to let it access to network"
$Deny = "Skip operation, outbound rules for internet browsers will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Browser installation directories
# TODO: returned path will miss browser updater
#
$EdgeChromiumRoot = "%ProgramFiles(x86)%\Microsoft\Edge\Application"

#
# Microsoft Edge-Chromium
#

# Test if installation exists on system
if ((Confirm-Installation "EdgeChromium" ([ref] $EdgeChromiumRoot)) -or $ForceLoad)
{
	# TODO: no FTP rule
	$Program = "$EdgeChromiumRoot\msedge.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Edge-Chromium HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Edge-Chromium QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Edge-Chromium HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol over SSL." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Edge-Chromium speedtest" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5060, 8080 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for https://speedtest.net" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Edge-Chromium FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Edge-Chromium pokerist" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for pokerist casino game" | Format-RuleOutput

		if ($false)
		{
			# NOTE: Not applied because now handled by IPv4 multicast rules
			# TODO: Figure out why edge chromium needs this rule, do additional test and update description
			New-NetFirewallRule -DisplayName "Edge-Chromium SSDP" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
				-LocalAddress Any -RemoteAddress 239.255.255.250 `
				-LocalPort Any -RemotePort 1900 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "" | Format-RuleOutput
		}
	}

	# TODO: we should probably have a function for this and similar cases?
	$EdgeUpdateRoot = "$(Split-Path -Path $(Split-Path -Path $EdgeChromiumRoot -Parent) -Parent)\EdgeUpdate"
	$Program = "$EdgeUpdateRoot\MicrosoftEdgeUpdate.exe"

	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		$UpdateAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
		Merge-SDDL ([ref] $UpdateAccounts) -From $UsersGroupSDDL

		New-NetFirewallRule -DisplayName "Edge-Chromium Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UpdateAccounts `
			-InterfaceType $DefaultInterface `
			-Description "Update Microsoft Edge" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log

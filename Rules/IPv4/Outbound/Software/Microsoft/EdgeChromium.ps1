
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft - Edge Chromium"
$Accept = "Outbound rules for Edge Chromium browser will be loaded, recommended if Edge Chromium is installed to let it access to network"
$Deny = "Skip operation, outbound rules for internet browsers will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
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
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium HTTP" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-Description "Hyper text transfer protocol." | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium QUIC" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium HTTPS" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-Description "Hyper text transfer protocol over SSL." | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium speedtest" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 5060, 8080 `
			-LocalUser $UsersGroupSDDL `
			-Description "Ports needed for https://speedtest.net" | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium FTP" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-Description "File transfer protocol." | Format-Output

		if ($false)
		{
			# NOTE: Not applied because now handled by IPv4 multicast rules
			# TODO: Figure out why edge chromium needs this rule, do additional test and update description
			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Edge-Chromium SSDP" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
				-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort Any -RemotePort 1900 `
				-LocalUser $UsersGroupSDDL `
				-Description "" | Format-Output
		}
	}

	# TODO: we should probably have a function for this and similar cases?
	$EdgeUpdateRoot = "$(Split-Path -Path $(Split-Path -Path $EdgeChromiumRoot -Parent) -Parent)\EdgeUpdate"
	$Program = "$EdgeUpdateRoot\MicrosoftEdgeUpdate.exe"

	if (Test-ExecutableFile $Program)
	{
		$UpdateAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
		Merge-SDDL ([ref] $UpdateAccounts) -From $UsersGroupSDDL

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Edge-Chromium Update" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
			-LocalUser $UpdateAccounts `
			-Description "Update Microsoft Edge" | Format-Output
	}
}

Update-Log

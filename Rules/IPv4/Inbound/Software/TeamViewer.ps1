
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
Inbound firewall rules for TeamViewer

.DESCRIPTION
Inbound firewall rules for Team Viewer remote control

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\TeamViewer.ps1

.INPUTS
None. You cannot pipe objects to TeamViewer.ps1

.OUTPUTS
None. TeamViewer.ps1 does not generate any output

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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - TeamViewer"
$LocalProfile = "Any"
$Accept = "Inbound rules for Team Viewer software will be loaded, recommended if Team Viewer software is installed to let it access to network"
$Deny = "Skip operation, inbound rules for Team Viewer software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# TeamViewer installation directories
#
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"

#
# Rules for TeamViewer remote control
#

# Test if installation exists on system
if ((Confirm-Installation "TeamViewer" ([ref] $TeamViewerRoot)) -or $ForceLoad)
{
	$Program = "$TeamViewerRoot\TeamViewer.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Teamviewer Remote Control Application" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 80, 443, 5938 -RemotePort Any `
			-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
			-Description "" | Format-Output
	}

	$Program = "$TeamViewerRoot\TeamViewer_Service.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Teamviewer Remote Control Service" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 80, 443, 5938 -RemotePort Any `
			-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
			-Description "" | Format-Output
	}
}

Update-Log

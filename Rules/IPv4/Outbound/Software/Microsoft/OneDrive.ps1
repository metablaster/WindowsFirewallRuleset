
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
Outbound firewall rules for OneDrive

.DESCRIPTION
Outbound firewall rules for One Drive

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\OneDrive.ps1

.INPUTS
None. You cannot pipe objects to OneDrive.ps1

.OUTPUTS
None. OneDrive.ps1 does not generate any output

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
$Group = "Microsoft - One Drive"
$Accept = "Outbound rules for One Drive will be loaded, recommended if One Drive is installed to let it access to network"
$Deny = "Skip operation, outbound rules for One Drive will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# One Drive installation directories
# TODO: This path is wrong since one drive become part of system, but we need some path even if wrong
#
$OneDriveRoot = "%ProgramFiles(x86)%\Microsoft OneDrive"

#
# Rules for One Drive
# TODO: does not exist on server platforms
#

# Test if installation exists on system
if ((Confirm-Installation "OneDrive" ([ref] $OneDriveRoot)) -or $ForceLoad)
{
	$Program = "$OneDriveRoot\OneDriveStandaloneUpdater.exe"
	if (Test-ExecutableFile $Program)
	{
		# NOTE: According to scheduled task the updating user is SYSTEM
		# TODO: Rule (probably also) needed for user profile, path blocked in process explorer was:
		# C:\Users\<USERNAME>\AppData\Local\Microsoft\OneDrive\OneDriveStandaloneUpdater.exe
		# the rest of rule properties was the same, possibly run by schedules task, in which case SYSTEM not needed
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "OneDrive Update" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $LocalSystem `
			-Description "Updater for OneDrive" | Format-Output
	}

	# TODO: LocalUser should be explicit user because each user runs it's own instance
	# and if there are multiple instances returned we need multiple rules for each user
	$Program = "$OneDriveRoot\OneDrive.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "OneDrive" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-Description "One drive for syncing user data" | Format-Output
	}
}

Update-Log

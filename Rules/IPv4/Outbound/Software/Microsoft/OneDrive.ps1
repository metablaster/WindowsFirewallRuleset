
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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

. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft - One Drive"
$Accept = "Outbound rules for One Drive will be loaded, recommended if One Drive is installed to let it access to network"
$Deny = "Skip operation, outbound rules for One Drive will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# One Drive installation directories
#
$OneDriveRoot = "%ProgramFiles(x86)%\Microsoft OneDrive"

#
# Rules for One Drive
# TODO: does not exist on server platforms
#

# Test if installation exists on system
if ((Test-Installation "OneDrive" ([ref] $OneDriveRoot) @Logs) -or $ForceLoad)
{
	$Program = "$OneDriveRoot\OneDriveStandaloneUpdater.exe"
	Test-File $Program @Logs

	# NOTE: According to scheduled task the updating user is SYSTEM
	# TODO: Rule (probably also) needed for user profile, path blocked in process explorer was:
	# C:\Users\<USERNAME>\AppData\Local\Microsoft\OneDrive\OneDriveStandaloneUpdater.exe
	# the rest of rule properties was the same, possibly run by schedules task, in which case SYSTEM not needed
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "OneDrive Update" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $NT_AUTHORITY_System `
		-Description "Updater for OneDrive" @Logs | Format-Output @Logs

	# TODO: LocalUser should be explicit user because each user runs it's own instance
	# and if there are multiple instances returned we need multiple rules for each user
	$Program = "$OneDriveRoot\OneDrive.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "OneDrive" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "One drive for syncing user data" @Logs | Format-Output @Logs
}

Update-Log

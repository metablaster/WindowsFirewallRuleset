
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

<#
.SYNOPSIS
Outbound firewall rules for Github

.DESCRIPTION
Outbound firewall rules for git and Github

.EXAMPLE
PS> .\Github.ps1

.INPUTS
None. You cannot pipe objects to Github.ps1

.OUTPUTS
None. Github.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Github"
$Accept = "Outbound rules for Github and GitHub Desktop will be loaded, recommended if Github and GitHub Desktop is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Github and GitHub Desktop will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Git and Git Desktop installation directories
# TODO: Username?
#
$GitRoot = "%ProgramFiles%\Git"
$GithubRoot = "C:\Users\$DefaultUser\AppData\Local\Apps\2.0"

#
# Rules for git
#

# Test if installation exists on system
if ((Test-Installation "Git" ([ref] $GitRoot)) -or $ForceLoad)
{
	# Administrators are needed for scheduled task for git auto update
	$CurlUsers = Get-SDDL -Group "Administrators", "Users"
	$Program = "$GitRoot\mingw64\bin\curl.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Git - curl" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $CurlUsers `
		-Description "curl download tool, also used by Git for Windows Updater
curl is a commandline tool to transfer data from or to a server,
using one of the supported protocols:
(DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP,
RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP)" |
	Format-Output

	# TODO: unsure if it's 443 or 80
	$Program = "$GitRoot\mingw64\bin\git.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Git - git" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output

	$Program = "$GitRoot\mingw64\libexec\git-core\git-remote-https.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Git - remote-https" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "git HTTPS access (https cloning)" | Format-Output

	$Program = "$GitRoot\usr\bin\ssh.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Git - ssh" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
		-LocalUser $UsersGroupSDDL `
		-Description "git SSH access" | Format-Output
}

#
# Rules for Github desktop
#

# Test if installation exists on system
if ((Test-Installation "GithubDesktop" ([ref] $GithubRoot)) -or $ForceLoad)
{
	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($GithubRoot)
	$VersionFolders = Get-ChildItem -Directory -Path $ExpandedPath -Filter app-* -Name
	$VersionFoldersCount = ($VersionFolders | Measure-Object).Count

	if ($VersionFoldersCount -gt 0)
	{
		$VersionFolder = $VersionFolders | Select-Object -Last 1
		$Program = "$GithubRoot\$VersionFolder\GitHubDesktop.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GithubRoot\GitHubDesktop.exe"
	}

	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "GitHub Desktop - App" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output

	$Program = "$GithubRoot\Update.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "GitHub Desktop - Update" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "cloning repos" | Format-Output

	if ($VersionFoldersCount -gt 0)
	{
		# $VersionDirectory = $VersionFolders.Name
		$Program = "$GithubRoot\$VersionFolder\resources\app\git\mingw64\bin\git-remote-https.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GithubRoot\resources\app\git\mingw64\bin\git-remote-https.exe"
	}

	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "GitHub Desktop - remote-https" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "cloning repos" | Format-Output
}

Update-Log

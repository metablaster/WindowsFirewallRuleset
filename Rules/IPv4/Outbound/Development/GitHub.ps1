
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Outbound firewall rules for GitHub

.DESCRIPTION
Outbound firewall rules for git and GitHub Desktop

.PARAMETER Domain
Computer name onto which to deploy rules

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
PS> .\GitHub.ps1

.INPUTS
None. You cannot pipe objects to GitHub.ps1

.OUTPUTS
None. GitHub.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - GitHub"
$Accept = "Outbound rules for 'Git' and 'GitHub Desktop' are recommended if these programs are installed"
$Deny = "Skip operation, these rules will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Git and Git Desktop installation directories
#
$GitRoot = "%ProgramFiles%\Git"
$GitHubRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Apps\GitHubDesktop"

#
# Rules for git
#

# Test if installation exists on system
if ((Confirm-Installation "Git" ([ref] $GitRoot)) -or $ForceLoad)
{
	# Administrators are needed for git auto update scheduled task
	$CurlUsers = Get-SDDL -Group "Administrators", "Users" -Merge
	$Program = "$GitRoot\mingw64\bin\curl.exe"

	# Because curl.exe that comes with git is unsigned and has 1 positive report, very likely false positive
	$OldDefaultSkipPositivies = Get-Variable -Scope Global -Name DefaultSkipPositivies
	Set-Variable -Name DefaultSkipPositivies -Scope Global -Option ReadOnly -Force -Value 1

	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# NOTE: Scheculed task to update git will run and succeed only if Administrative user is logged in
		New-NetFirewallRule -DisplayName "Git - curl" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 110, 143, 443, 993, 995 `
			-LocalUser $CurlUsers `
			-InterfaceType $DefaultInterface `
			-Description "curl download tool, also used by Git for Windows updater
curl is a commandline tool to transfer data from or to a server,
using one of the supported protocols:
(DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP,
RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP)" |
		Format-RuleOutput
	}

	Set-Variable -Name DefaultSkipPositivies -Scope Global -Option ReadOnly -Force -Value $OldDefaultSkipPositivies.Value

	# TODO: unsure if it's 443 or 80, and not sure what's the purpose
	$Program = "$GitRoot\mingw64\bin\git.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Git - git" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	$Program = "$GitRoot\mingw64\libexec\git-core\git-remote-https.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Git - remote-https" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "git HTTPS for clone, fetch, push, commit etc." | Format-RuleOutput
	}

	$Program = "$GitRoot\usr\bin\ssh.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Git - ssh" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 22 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "SSH client for git clone, fetch, push, commit etc." | Format-RuleOutput
	}
}

#
# Rules for GitHub desktop
#

# Test if installation exists on system
if ((Confirm-Installation "GitHubDesktop" ([ref] $GitHubRoot)) -or $ForceLoad)
{
	$VersionFolders = Invoke-Command -Session $SessionInstance -ScriptBlock {
		$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($using:GitHubRoot)

		Get-ChildItem -Directory -Path $ExpandedPath -Filter app-* -Name -ErrorAction SilentlyContinue
	}

	$VersionFoldersCount = ($VersionFolders | Measure-Object).Count

	if ($VersionFoldersCount -gt 0)
	{
		$VersionFolder = $VersionFolders | Sort-Object | Select-Object -Last 1
		$Program = "$GitHubRoot\$VersionFolder\GitHubDesktop.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GitHubRoot\app-2.6.1\GitHubDesktop.exe"
	}

	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "GitHub Desktop - Client" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "At a minimum telemetry and authentication to GitHub" | Format-RuleOutput
	}

	$Program = "$GitHubRoot\Update.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "GitHub Desktop - Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Checking for client updates and client auto update" | Format-RuleOutput
	}

	if ($VersionFoldersCount -gt 0)
	{
		# $VersionDirectory = $VersionFolders.Name
		$Program = "$GitHubRoot\$VersionFolder\resources\app\git\mingw64\bin\git-remote-https.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GitHubRoot\app-2.6.1\resources\app\git\mingw64\bin\git-remote-https.exe"
	}

	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "GitHub Desktop - Git" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Used for clone, fetch, push, commit etc." | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

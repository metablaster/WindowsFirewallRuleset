
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
Outbound firewall rules for Windows system

.DESCRIPTION
Rules which apply to Windows programs and utilities, which are not handled by predefined rules

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
PS> .\WindowsSystem.ps1

.INPUTS
None. You cannot pipe objects to WindowsSystem.ps1

.OUTPUTS
None. WindowsSystem.ps1 does not generate any output

.NOTES
TODO: LocalUser for most rules is missing?
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
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Windows System"
$Accept = "Outbound rules for built in system software will be loaded, required for proper functioning of operating system"
$Deny = "Skip operation, outbound rules for built in system software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Installation directories
#
# NOTE: for windows defender and .NET we must omit exact folder to prevent creating rule for outdated executable
# TODO: Unknown default installation directory
$WindowsDefenderRoot = "" # "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Platform"
$NETFrameworkRoot = "" # "%SystemRoot%\Microsoft.NET\Framework64"

#
# Rules for Windows system
#

# TODO: Should be global variable, there is also one defined in
# Ruleset.Remote and other rule scripts
$ServerTarget = (Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
		-ClassName Win32_OperatingSystem -EA Stop |
	Select-Object -ExpandProperty ProductType) -eq 3

if (!$ServerTarget)
{
	# TODO: remote port unknown, protocol assumed
	# NOTE: does not exist in Windows Server 2019 and 2022
	# TODO: does not exist in Windows 11, there must be replacement executable
	# NOTE: user can by any local human user
	$Program = "%SystemRoot%\System32\DataUsageLiveTileTask.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "DataSenseLiveTileTask" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-Description "Probably related to keeping bandwidth usage information up-to-date." |
		Format-RuleOutput
	}
}

# Test if installation exists on system
if ((Confirm-Installation "NETFramework" ([ref] $NETFrameworkRoot)) -or $ForceLoad)
{
	# TODO: are these really user accounts we need here
	$Program = "$NETFrameworkRoot\mscorsvw.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "CLR Optimization Service" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Block -Direction $Direction -Protocol Any `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "mscorsvw.exe is precompiling .NET assemblies in the background.
Once it's done, it will go away. Typically, after you install the .NET Redist,
it will be done with the high priority assemblies in 5 to 10 minutes and then will wait until
your computer is idle to process the low priority assemblies." |
		Format-RuleOutput
	}
}

if ((Confirm-Installation "WindowsDefender" ([ref] $WindowsDefenderRoot)) -or $ForceLoad)
{
	$Program = "$WindowsDefenderRoot\MsMpEng.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Windows Defender" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "Anti malware service executable." |
		Format-RuleOutput
	}

	$Program = "$WindowsDefenderRoot\MpCmdRun.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Windows Defender CLI" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "This utility can be useful when you want to automate Windows Defender
Antivirus use." |
		Format-RuleOutput
	}
}

# TODO: Missing description
$Program = "%SystemRoot%\System32\MRT.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Malicious Software Removal Tool" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $LocalSystem `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\slui.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Activation Client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Used to activate Windows." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\SppExtComObj.Exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# Port 1688 is used for Microsoft Key Management Service (KMS) for Windows Activation
	New-NetFirewallRule -DisplayName "KMS Connection Broker" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 1688 `
		-LocalUser $NetworkService `
		-InterfaceType $DefaultInterface `
		-Description "Activate Office and KMS based software.
sppextcomobj.exe is used for Key Management Service (KMS) Licensing for
Microsoft Products, the KMS Connection Broker or sppextcomobj.exe is responsible for the activation
of Microsoft products." |
	Format-RuleOutput
}

# TODO: this app no longer exists on system, MS changed executable name?
# $Program = "%SystemRoot%\System32\CompatTel\QueryAppBlock.exe"
# Test-ExecutableFile $Program

# New-NetFirewallRule -DisplayName "Application Block Detector" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
# 	-Service Any -Program $Program -Group $Group `
# 	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
# 	-LocalAddress Any -RemoteAddress Internet4 `
# 	-LocalPort Any -RemotePort 80 `
# 	-LocalUser Any `
# 	-InterfaceType $DefaultInterface `
# 	-Description "Its purpose is to scans your hardware, devices, and installed programs for
# known compatibility issues
# with a newer Windows version by comparing them against a specific database." |
# Format-RuleOutput

$Program = "%SystemRoot%\System32\backgroundTaskHost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# TODO: need to check if port 22 is OK.
	# TODO: Dropped connection (for admin), likely reason for app downarrows
	# NOTE: Testing with profile "Any"
	New-NetFirewallRule -DisplayName "Background task host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 22, 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "backgroundTaskHost.exe is the process that starts background tasks.
So Cortana and the other Microsoft app registered a background task which is now started by Windows.
Port 22 is most likely used for installation.
https://docs.microsoft.com/en-us/windows/uwp/launch-resume/support-your-app-with-background-tasks" |
	Format-RuleOutput
}

# NOTE: Was active while setting up MS account
$Program = "%SystemRoot%\System32\BackgroundTransferHost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Background transfer host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "Download/Upload Host" |
	Format-RuleOutput
}

# TODO: Not sure if also needed to allow Administrators for MS account here
$Program = "%SystemRoot%\System32\UserAccountBroker.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	$MSAccountUsers = $UsersGroupSDDL
	Merge-SDDL ([ref] $MSAccountUsers) -From $AdminGroupSDDL

	New-NetFirewallRule -DisplayName "Microsoft Account" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $MSAccountUsers `
		-InterfaceType $DefaultInterface `
		-Description "UserAccountBroker is needed to create Microsoft account" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\Speech_OneCore\common\SpeechRuntime.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# TODO: no comment
	New-NetFirewallRule -DisplayName "Cortana Speech Runtime" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\Speech_OneCore\common\SpeechModelDownload.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Cortana Speech Model" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $NetworkService `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\wsqmcons.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Customer Experience Improvement Program" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "This program collects and sends usage data to Microsoft,
can be disabled in GPO." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\CompatTelRunner.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Microsoft Compatibility Telemetry" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $LocalSystem `
		-InterfaceType $DefaultInterface `
		-Description "The CompatTelRunner.exe process is used by Windows to perform system diagnostics
to determine if there are any compatibility issues.
It also collects program telemetry information (if that option is selected) for the
Microsoft Customer Experience Improvement Program.
This allows Microsoft to ensure compatibility when installing the latest version of the
Windows operating system.
This process also takes place when upgrading the operating system.
To disable this program: Task Scheduler Library > Microsoft > Windows > Application Experience
In the middle pane, you will see all the scheduled tasks, such as Microsoft Compatibility Appraiser,
ProgramDataUpdater and StartupAppTask.
Right-click on the Microsoft Compatibility Appraiser and select Disable." |
	Format-RuleOutput
}

# TODO: TCP port 80 NT AUTHORITY\SYSTEM seen in dev channel, testing SYSTEM account
$Program = "%SystemRoot%\System32\SearchProtocolHost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Indexing Service" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $LocalSystem `
		-InterfaceType $DefaultInterface `
		-Description "SearchProtocolHost.exe is part of the Windows Indexing Service,
an application that indexes files on the local drive making them easier to search." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\WerFault.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Error Reporting" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Report Windows errors back to Microsoft." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\wermgr.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Error Reporting" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Report Windows errors back to Microsoft." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\explorer.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# TODO: remote to local subnet seen for shared folder access
	New-NetFirewallRule -DisplayName "File Explorer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "File explorer checks for digital signatures verification, windows update." |
	Format-RuleOutput

	# TODO: possibly deprecated since Windows 10
	# Seen outbound 443 while setting up MS account on fresh Windows account
	New-NetFirewallRule -DisplayName "File Explorer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Smart Screen Filter" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\ftp.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# TODO: need to test and adjust for passive vs active and various types of protocol:
	# FTP, SFPT, FTPS etc... All this have to be updated also for other FTP programs
	New-NetFirewallRule -DisplayName "FTP Client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4, LocalSubnet4 `
		-LocalPort Any -RemotePort 21 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "File transfer protocol client." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\HelpPane.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Help pane" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Get online help, looks like windows 10+ no longer uses this,
it opens edge now to show help." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\rundll32.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# TODO: program possibly no longer uses networking since windows 10
	New-NetFirewallRule -DisplayName "DLL host process" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Loads and runs 32-bit dynamic-link libraries (DLLs),
There are no configurable settings for Rundll32.
possibly no longer uses networking since windows 10." |
	Format-RuleOutput
}

# TODO: this app no longer exists on system, MS changed executable name?
# $Program = "%SystemRoot%\System32\CompatTel\wicainventory.exe"
# Test-ExecutableFile $Program

# TODO: no comment
# New-NetFirewallRule -DisplayName "Install Compatibility Advisor Inventory Tool" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
# 	-Service Any -Program $Program -Group $Group `
# 	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
# 	-LocalAddress Any -RemoteAddress Internet4 `
# 	-LocalPort Any -RemotePort 80 `
# 	-LocalUser Any `
# 	-InterfaceType $DefaultInterface `
# 	-Description "" |
# Format-RuleOutput

$Program = "%SystemRoot%\System32\msiexec.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Installer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "msiexec automatically check for updates for the program it is installing." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\lsass.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Local Security Authority Process" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Lsas.exe a process in Microsoft Windows operating systems that is responsible
for enforcing the security policy on the system.
It specifically deals with local security and login policies.It verifies users logging on to a
Windows computer or server, handles password changes, and creates access tokens.
It is also used for certificate revocation checks" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\mmc.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "MMC Help Viewer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Display webpages in Microsoft MMC help view." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\nslookup.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "nslookup (Name server lookup)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4, DefaultGateway4 `
		-LocalPort Any -RemotePort 53 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Displays information that you can use to diagnose Domain Name System (DNS) infrastructure.
The nslookup command-line tool is available only if you have installed the TCP/IP protocol." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\curl.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	# NOTE: Ports are specified only for some protocols
	New-NetFirewallRule -DisplayName "curl" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4, LocalSubnet4 `
		-LocalPort Any -RemotePort 80, 110, 143, 443, 993, 995 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "curl is a commandline tool to transfer data from or to a server,
using one of the supported protocols:
(DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP,
RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP)" |
	Format-RuleOutput
}

# TODO: Not available in Windows Server 2022
# TODO: does not exist in Windows 11, there must be replacement executable
$Program = "%SystemRoot%\System32\SettingSyncHost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Settings sync" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Host process for setting synchronization. Open your PC Settings and go to the
'Sync your Settings' section.
There are on/off switches for all the different things you can choose to sync.
Just turn off the ones you don't want. Or you can just turn them all off at once at the top." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\smartscreen.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Smartscreen" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\ImmersiveControlPanel\SystemSettings.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "SystemSettings" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "Seems like it's connecting to display some 'useful tips' on the right hand side
of the settings menu, NOTE: Configure the gpo 'Control Panel\allow online tips' to 'disabled'
to stop generating this traffic." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\taskhostw.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "taskhostw" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "The main function of taskhostw.exe is to start the Windows Services based on
DLLs whenever the computer boots up.
It is a host for processes that are responsible for executing a DLL rather than an Exe." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\sihclient.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Service Initiated Healing" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "sihclient.exe SIH Client is the client for fixing system components that are
important for automatic Windows updates.
This daily task runs the SIHC client (initiated by the healing server) to detect and
repair system components that are vital to
automatically update Windows and the Microsoft software installed on the computer.
The task can go online, assess the usefulness of the healing effect,
download the necessary equipment to perform the action, and perform therapeutic actions.)" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\DeviceCensus.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Update (Devicecensus)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Devicecensus is used to gather information about your PC to target
builds through Windows Update,
In order to target builds to your machine, we need to know a few important things:
- OS type (home, pro, enterprise, etc.)
- region
- language
- x86 or x64
- selected Insider ring
- etc." |
	Format-RuleOutput
}

# TODO: USOAccounts testing with users, should be SYSTEM
$USOAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
Merge-SDDL ([ref] $USOAccounts) -From $UsersGroupSDDL

if (!$ServerTarget)
{
	# NOTE: does not exist in Windows Server 2019 and 2022
	# TODO: does not exist in Windows 11, there must be replacement executable
	$Program = "%SystemRoot%\System32\usocoreworker.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Update Session Orchestrator" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $USOAccounts `
			-InterfaceType $DefaultInterface `
			-Description "wuauclt.exe is deprecated on Windows 10 (and Server 2016 and newer).
The command line tool has been replaced by usoclient.exe.
When the system starts an update session, it launches usoclient.exe,
which in turn launches usocoreworker.exe.
Usocoreworker is the worker process for usoclient.exe and essentially it does all the work that
the USO component needs done." |
		Format-RuleOutput
	}
}

# TODO: This one is present since Windows 10 v2004, needs description, not available in Server 2019
# TODO: does not exist in Windows 11, there must be replacement executable
$Program = "%SystemRoot%\System32\MoUsoCoreWorker.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Mo Update Session Orchestrator" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $USOAccounts `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\usoclient.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Update Session Orchestrator" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $LocalSystem `
		-InterfaceType $DefaultInterface `
		-Description "wuauclt.exe is deprecated on Windows 10 (and Server 2016 and newer).
The command line tool has been replaced by usoclient.exe.
When the system starts an update session, it launches usoclient.exe,
which in turn launches usocoreworker.exe.
Usocoreworker is the worker process for usoclient.exe and essentially it does all the work that the
USO component needs done." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\wbem\WmiPrvSE.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "WMI Provider Host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 22 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\OpenSSH\ssh.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Open SSH" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort 22 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "OpenSSH is connectivity tool for remote login with the SSH protocol,
This rule applies to open source version of OpenSSH that is built into Windows." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\conhost.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Console Host" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "" |
	Format-RuleOutput
}

# NOTE: Was active while setting up MS account
# NOTE: description from: https://www.tenforums.com/tutorials/110230-enable-disable-windows-security-windows-10-a.html
$Program = "%SystemRoot%\System32\SecurityHealthService.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Security Health Service" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $LocalSystem `
		-InterfaceType $DefaultInterface `
		-Description "Windows Defender AV and the Windows Security app use similarly named services for specific purposes.
The Windows Security app uses the Windows Security Service (SecurityHealthService or Windows Security Health Service),
which in turn utilizes the Security Center service (wscsvc) to ensure the app provides the most
up-to-date information about the protection status on the endpoint,
including protection offered by third-party antivirus products, Windows Defender Firewall,
third-party firewalls, and other security protection.
These services do not affect the state of Windows Defender AV.
Disabling or modifying these services will not disable Windows Defender AV,
and will lead to a lowered protection state on the endpoint,
even if you are using a third-party antivirus product." |
	Format-RuleOutput
}

# TODO: Needs testings, current user which runs application which starts consent.exe need to
# be added to -LocalUser parameter, test with pokerstars game when out of date
$ConsentUsers = $LocalSystem
Merge-SDDL ([ref] $ConsentUsers) -From $UsersGroupSDDL

$Program = "%SystemRoot%\System32\consent.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows UAC" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80 `
		-LocalUser $ConsentUsers `
		-InterfaceType $DefaultInterface `
		-Description "consent.exe connects to the internet to verify the digital signature
(certification expiry) of applications that needs administrative privilege,
from the certification issuer." |
	Format-RuleOutput
}

#
# Windows Device Management (predefined rules)
#

$Program = "%SystemRoot%\System32\dmcertinst.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Device Management Certificate Installer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Allow outbound TCP traffic from Windows Device Management
Certificate Installer." |
	Format-RuleOutput
}

$Program = "%SystemRoot%\System32\deviceenroller.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Device Management Device Enroller" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Allow outbound TCP traffic from Windows Device Management Device Enroller" |
	Format-RuleOutput
}

New-NetFirewallRule -DisplayName "Windows Device Management Enrollment Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service DmEnrollmentSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Allow outbound TCP traffic from Windows Device Management Enrollment Service." |
Format-RuleOutput

$Program = "%SystemRoot%\System32\omadmclient.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "Windows Device Management Sync Client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "Allow outbound TCP traffic from Windows Device Management Sync Client." |
	Format-RuleOutput
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log


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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Windows System"
$FirewallProfile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Installation directories
#
$WindowsDefenderRoot = ""
$NETFrameworkRoot = ""

#
# Windows system rules
# Rules that apply to Windows programs and utilities, which are not handled by predefined rules
# TODO: LocalUser for most rules is missing?
#

# TODO: remote port unknown, protocol assumed
# NOTE: user can by any local human user
$Program = "%SystemRoot%\System32\DataUsageLiveTileTask.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "DataSenseLiveTileTask" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Probably related to keeping bandwidth usage information up-to-date." `
	@Logs | Format-Output @Logs

# Test if installation exists on system
if ((Test-Installation "NETFramework" ([ref] $NETFrameworkRoot) @Logs) -or $ForceLoad)
{
	# TODO: are these really user accounts we need here
	$Program = "$NETFrameworkRoot\mscorsvw.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "CLR Optimization Service" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "mscorsvw.exe is precompiling .NET assemblies in the background.
Once it's done, it will go away. Typically, after you install the .NET Redist,
it will be done with the high priority assemblies in 5 to 10 minutes and then will wait until
your computer is idle to process the low priority assemblies." `
		@Logs | Format-Output @Logs
}

if ((Test-Installation "WindowsDefender" ([ref] $WindowsDefenderRoot) @Logs) -or $ForceLoad)
{
	$Program = "$WindowsDefenderRoot\MsMpEng.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "Windows Defender" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $NT_AUTHORITY_System `
		-InterfaceType $Interface `
		-Description "Anti malware service executable." `
		@Logs | Format-Output @Logs

	$Program = "$WindowsDefenderRoot\MpCmdRun.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "Windows Defender CLI" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $NT_AUTHORITY_System `
		-InterfaceType $Interface `
		-Description "This utility can be useful when you want to automate Windows Defender
Antivirus use." `
		@Logs | Format-Output @Logs
}

$Program = "%SystemRoot%\System32\slui.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Activation Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Used to activate Windows." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\SppExtComObj.Exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Activation KMS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 1688 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Activate Office and KMS based software." `
	@Logs | Format-Output @Logs

# TODO: this app no longer exists on system, MS changed executable name?
# $Program = "%SystemRoot%\System32\CompatTel\QueryAppBlock.exe"
# Test-File $Program @Logs

# New-NetFirewallRule -DisplayName "Application Block Detector" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
# 	-Service Any -Program $Program -Group $Group `
# 	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
# 	-LocalAddress Any -RemoteAddress Internet4 `
# 	-LocalPort Any -RemotePort 80 `
# 	-LocalUser Any `
# 	-InterfaceType $Interface `
# 	-Description "Its purpose is to scans your hardware, devices, and installed programs for
# known compatibility issues
# with a newer Windows version by comparing them against a specific database." `
# 	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\backgroundTaskHost.exe"
Test-File $Program @Logs

# TODO: need to check if port 22 is OK.
New-NetFirewallRule -DisplayName "Background task host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 22, 80 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "backgroundTaskHost.exe is the process that starts background tasks.
So Cortana and the other Microsoft app registered a background task which is now started by Windows.
Port 22 is most likely used for installation.
https://docs.microsoft.com/en-us/windows/uwp/launch-resume/support-your-app-with-background-tasks" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\Speech_OneCore\common\SpeechRuntime.exe"
Test-File $Program @Logs

# TODO: no comment
New-NetFirewallRule -DisplayName "Cortana Speech Runtime" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\Speech_OneCore\common\SpeechModelDownload.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Cortana Speech Model" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_NetworkService `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\wsqmcons.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Customer Experience Improvement Program" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "This program collects and sends usage data to Microsoft,
can be disabled in GPO." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\CompatTelRunner.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Microsoft Compatibility Telemetry" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
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
Right-click on the Microsoft Compatibility Appraiser and select Disable." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\SearchProtocolHost.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Windows Indexing Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "SearchProtocolHost.exe is part of the Windows Indexing Service,
an application that indexes files on the local drive making them easier to search." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\WerFault.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Error Reporting" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Report Windows errors back to Microsoft." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\wermgr.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Error Reporting" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Report Windows errors back to Microsoft." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\explorer.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "File Explorer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "File explorer checks for digital signatures verification, windows update." `
	@Logs | Format-Output @Logs

# TODO: possible deprecate
New-NetFirewallRule -DisplayName "File Explorer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Smart Screen Filter, possible no longer needed since windows 10." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\ftp.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "FTP Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4, LocalSubnet4 `
	-LocalPort Any -RemotePort 21 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "File transfer protocol client." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\HelpPane.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Help pane" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Get online help, looks like windows 10+ no longer uses this,
it opens edge now to show help." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\rundll32.exe"
Test-File $Program @Logs

# TODO: program possibly no longer uses networking since windows 10
New-NetFirewallRule -DisplayName "DLL host process" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Loads and runs 32-bit dynamic-link libraries (DLLs),
There are no configurable settings for Rundll32.
possibly no longer uses networking since windows 10." `
	@Logs | Format-Output @Logs

# TODO: this app no longer exists on system, MS changed executable name?
# $Program = "%SystemRoot%\System32\CompatTel\wicainventory.exe"
# Test-File $Program @Logs

# TODO: no comment
# New-NetFirewallRule -DisplayName "Install Compatibility Advisor Inventory Tool" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
# 	-Service Any -Program $Program -Group $Group `
# 	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
# 	-LocalAddress Any -RemoteAddress Internet4 `
# 	-LocalPort Any -RemotePort 80 `
# 	-LocalUser Any `
# 	-InterfaceType $Interface `
# 	-Description "" `
# 	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\msiexec.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Installer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "msiexec automatically check for updates for the program it is installing." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\lsass.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Local Security Authority Process" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Lsas.exe a process in Microsoft Windows operating systems that is responsible
for enforcing the security policy on the system.
It specifically deals with local security and login policies.It verifies users logging on to a
Windows computer or server, handles password changes, and creates access tokens." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\mmc.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "MMC Help Viewer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Display webpages in Microsoft MMC help view." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\nslookup.exe"
Test-File $Program @Logs

# TODO: no comment
New-NetFirewallRule -DisplayName "Name server lookup" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Internet4, DefaultGateway4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\SettingSyncHost.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Settings sync" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Host process for setting synchronization. Open your PC Settings and go to the
'Sync your Settings' section.
There are on/off switches for all the different things you can choose to sync.
Just turn off the ones you don't want. Or you can just turn them all off at once at the top." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\smartscreen.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Smartscreen" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\ImmersiveControlPanel\SystemSettings.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "SystemSettings" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $Interface `
	-Description "Seems like it's connecting to display some 'useful tips' on the right hand side
 of the settings menu, NOTE: Configure the gpo 'Control Panel\allow online tips' to 'disabled'
 to stop generating this traffic." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\taskhostw.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "taskhostw" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "The main function of taskhostw.exe is to start the Windows Services based on
DLLs whenever the computer boots up.
It is a host for processes that are responsible for executing a DLL rather than an Exe." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\sihclient.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Service Initiated Healing" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "sihclient.exe SIH Client is the client for fixing system components that are
important for automatic Windows updates.
This daily task runs the SIHC client (initiated by the healing server) to detect and
repair system components that are vital to
automatically update Windows and the Microsoft software installed on the computer.
The task can go online, assess the usefulness of the healing effect,
download the necessary equipment to perform the action, and perform therapeutic actions.)" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\DeviceCensus.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Windows Update (Devicecensus)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Devicecensus is used to gather information about your PC to target
builds through Windows Update,
In order to target builds to your machine, we need to know a few important things:
- OS type (home, pro, enterprise, etc.)
- region
- language
- x86 or x64
- selected Insider ring
- etc." `
	@Logs | Format-Output @Logs

# TODO: USOAccounts testing with users, should be SYSTEM
$USOAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM" @Logs
Merge-SDDL ([ref] $USOAccounts) (Get-SDDL -Group "Users") @Logs

# NOTE: probably not available in Windows Server
$Program = "%SystemRoot%\System32\usocoreworker.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Update Session Orchestrator" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $USOAccounts `
	-InterfaceType $Interface `
	-Description "wuauclt.exe is deprecated on Windows 10 (and Server 2016 and newer).
The command line tool has been replaced by usoclient.exe.
When the system starts an update session, it launches usoclient.exe,
which in turn launches usocoreworker.exe.
Usocoreworker is the worker process for usoclient.exe and essentially it does all the work that
the USO component needs done." `
	@Logs | Format-Output @Logs

# TODO: This one is present since Windows 10 v2004, needs description
$Program = "%SystemRoot%\System32\MoUsoCoreWorker.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Mo Update Session Orchestrator" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $USOAccounts `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\usoclient.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Update Session Orchestrator" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "wuauclt.exe is deprecated on Windows 10 (and Server 2016 and newer).
The command line tool has been replaced by usoclient.exe.
When the system starts an update session, it launches usoclient.exe,
which in turn launches usocoreworker.exe.
Usocoreworker is the worker process for usoclient.exe and essentially it does all the work that the
USO component needs done." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\wbem\WmiPrvSE.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "WMI Provider Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 22 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\OpenSSH\ssh.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "OpenSSH" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 22 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "OpenSSH is connectivity tool for remote login with the SSH protocol,
This rule applies to open source version of OpenSSH that is built into Windows." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\conhost.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Console Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "" `
	@Logs | Format-Output @Logs

#
# Windows Device Management (predefined rules)
#

$Program = "%SystemRoot%\System32\dmcertinst.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Windows Device Management Certificate Installer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Allow outbound TCP traffic from Windows Device Management
Certificate Installer." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\deviceenroller.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Windows Device Management Device Enroller" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Allow outbound TCP traffic from Windows Device Management Device Enroller" `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Windows Device Management Enrollment Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service DmEnrollmentSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Allow outbound TCP traffic from Windows Device Management Enrollment Service." `
	@Logs | Format-Output @Logs

$Program = "%SystemRoot%\System32\omadmclient.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Windows Device Management Sync Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Allow outbound TCP traffic from Windows Device Management Sync Client." `
	@Logs | Format-Output @Logs

Update-Log


#setup variables:
$Platform = "10.0+" #Windows 10 and above
$Group = "Windows System"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$PolicyStore = "localhost"
$OnError = "Stop"
$Deubg = $false

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Windows system rules
# Rules that apply to Windows programs and utilities
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Activation Client" -Program "%SystemRoot%\System32\slui.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Used to activate Windows."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Activation KMS" -Program "%SystemRoot%\System32\SppExtComObj.Exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 1688 `
-Description "Activate Office and KMS based software."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Application Block Detector" -Program "%SystemRoot%\System32\CompatTel\QueryAppBlock.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "Its purpose is to scans your hardware, devices, and installed programs for known compatibility issues
with a newer Windows version by comparing them against a specific database."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Background task host" -Program "%SystemRoot%\System32\backgroundTaskHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "backgroundTaskHost.exe is the process that starts background tasks.
So Cortana and the other Microsoft app registered a background task which is now started by Windows.
https://docs.microsoft.com/en-us/windows/uwp/launch-resume/support-your-app-with-background-tasks"

# TODO: no comment
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cortana Speach Runtime" -Program "%SystemRoot%\System32\Speech_OneCore\common\SpeechRuntime.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Customer Experience Improvement Program" -Program "%SystemRoot%\System32\wsqmcons.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "This program collects and sends usage data to Microsoft, can be disabled in GPO."

# TODO: missing protocol and port
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Device Association Framework Provider Host" -Program "%SystemRoot%\System32\dasHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol Any -LocalAddress Any -RemoteAddress LocalSubnet -LocalPort Any -RemotePort Any `
-Description "Host enables pairing between the system and wired or wireless devices. This service is new since Windows 8."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Indexing Service" -Program "%SystemRoot%\System32\SearchProtocolHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "SearchProtocolHost.exe is part of the Windows Indexing Service,
an application that indexes files on the local drive making them easier to search."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Driver Foundation - User-mode Driver Framework Host Process" -Program "%SystemRoot%\System32\WUDFHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Error Reporting" -Program "%SystemRoot%\System32\WerFault.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Report Windows errors back to Microsoft."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Error Reporting" -Program "%SystemRoot%\System32\wermgr.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Report Windows errors back to Microsoft."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "File Explorer" -Program "%SystemRoot%\explorer.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "File explorer checks for digital signatures verification, windows update."

# TODO: possible deprecate
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "File Explorer" -Program "%SystemRoot%\explorer.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Smart Screen Filter, possible no longer needed since windows 10."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "FTP Client" -Program "%SystemRoot%\System32\ftp.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet, LocalSubnet -LocalPort Any -RemotePort 21 `
-Description "File transfer protocol client."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Help pane" -Program "%SystemRoot%\HelpPane.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "Get online help, looks like windows 10+ no longer uses this, it opens edge now to show help."

# TODO: program possibly no longer uses networking since windows 10
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "DLL host process" -Program "%SystemRoot%\System32\rundll32.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Loads and runs 32-bit dynamic-link libraries (DLLs), There are no configurable settings for Rundll32.
possibly no longer uses networking since windows 10."

# TODO: no comment
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Install Compability Advisor Inventory Tool" -Program "%SystemRoot%\System32\CompatTel\wicainventory.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Installer" -Program "%SystemRoot%\System32\msiexec.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "msiexec automatically check for updates for the program it is installing."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Local Security Authority Process" -Program "%SystemRoot%\System32\lsass.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80 `
-Description "Lsas.exe a process in Microsoft Windows operating systems that is responsible for enforcing the security policy on the system.
It specifically deals with local security and login policies.It verifies users logging on to a Windows computer or server,
handles password changes, and creates access tokens."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "MMC Help Viewer" -Program "%SystemRoot%\System32\mmc.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Display webpages in Microsoft MMC help view."

# TODO: no comment
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Name server lookup" -Program "%SystemRoot%\System32\nslookup.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet, DefaultGateway -LocalPort Any -RemotePort 53 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Remote desktop" -Program "%SystemRoot%\System32\mstsc.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet, LocalSubnet -LocalPort Any -RemotePort 3389 `
-Description "Remote desktop connection."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Remote desktop" -Program "%SystemRoot%\System32\mstsc.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet, LocalSubnet -LocalPort Any -RemotePort 3389 `
-Description "Remote desktop connection."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Settings sync" -Program "%SystemRoot%\System32\SettingSyncHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Host process for setting synchronization. Open your PC Settings and go to the 'Sync your Settings' section.
There are on/off switches for all the different things you can choose to sync.
Just turn off the ones you don't want. Or you can just turn them all off at once at the top."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Smartscreen" -Program "%SystemRoot%\System32\smartscreen.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "SystemSettings" -Program "%SystemRoot%\ImmersiveControlPanel\SystemSettings.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Seems like it's connecting to display some 'useful tips' on the right hand side of the settings menu,
NOTE: Configured the gpo 'Control Panel\allow online tips' to 'disabled'."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "taskhostw" -Program "%SystemRoot%\System32\taskhostw.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "The main function of taskhostw.exe is to start the Windows Services based on DLLs whenever the computer boots up.
It is a host for processes that are responsible for executing a DLL rather than an Exe."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Update (Devicecensus)" -Program "%SystemRoot%\System32\DeviceCensus.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Devicecensus is used to gather information about your PC to target builds through Windows Update,
In order to target builds to your machine, we need to know a few important things:
- OS type (home, pro, enterprise, etc.)
- region
- language
- x86 or x64
- selected Insider ring
- etc."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Update Session Orchestrator" -Program "%SystemRoot%\System32\usocoreworker.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "wuauclt.exe is deprecated on Windows 10 (and Server 2016 and newer). The command line tool has been replaced by usoclient.exe.
When the system starts an update session, it launches usoclient.ex, which in turn launches usocoreworker.exe.
Usocoreworker is the worker process for usoclient.exe and essentially it does all the work that the USO component needs done."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Defender" -Program "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Platform\4.18.1911.3-0\MsMpEng.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Anti malware service executable."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Defender" -Program "%ALLUSERSPROFILE%\Microsoft\Windows Defender\Platform\4.18.1910.4-0\MsMpEng.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Anti malware service executable."

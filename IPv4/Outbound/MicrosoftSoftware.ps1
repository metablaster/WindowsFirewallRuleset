
#setup variables:
$Platform = "10.0+" #Windows 10 and above
$Group = "Microsoft Software"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$PolicyStore = "localhost"
$OnError = "Stop"
$Deubg = $false

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Microsoft office rules
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Visual Studio Code" -Program "%ProgramFiles%\Microsoft VS Code\Code.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "WinDbg Symbol Server x86" -Program "%ProgramFiles% (x86)\Windows Kits\10\Debuggers\x86\windbg.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "WinDbg access to Symbols Server."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "WinDbg Symbol Server x64" -Program "%ProgramFiles% (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "WinDbg access to Symbols Server"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Symchk Symbol Server x86" -Program "%ProgramFiles% (x86)\Windows Kits\10\Debuggers\x86\symchk.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "WinDbg Symchk access to Symbols Server."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Symchk Symbol Server x64" -Program "%ProgramFiles% (x86)\Windows Kits\10\Debuggers\x64\symchk.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "WinDbg Symchk access to Symbols Server"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Web Platform Installer" -Program "%ProgramFiles%\Microsoft\Web Platform Installer\WebPlatformInstaller.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "SQL Server Management Studio" -Program "%ProgramFiles% (x86)\Microsoft SQL Server\140\Tools\Binn\ManagementStudio\Ssms.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "SQL Server Import and Export Wizard" -Program "%ProgramFiles% (x86)\Microsoft SQL Server\140\DTS\Binn\DTSWizard.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell ISE x64" -Program "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell_ise.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Rule to allow update of powershell"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell x64" -Program "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Rule to allow update of powershell"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell ISE x86" -Program "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell_ise.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Rule to allow update of powershell"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "PowerShell x86" -Program "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Rule to allow update of powershell"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "OneDrive Update" -Program "%ProgramFiles% (x86)\Microsoft OneDrive\OneDriveStandaloneUpdater.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Updater for OneDrive"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "OneDrive" -Program "%ProgramFiles% (x86)\Microsoft OneDrive\OneDrive.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Help Viewer (Content manager)" -Program "%ProgramFiles% (x86)\Microsoft Help Viewer\v2.3\HlpCtntMgr.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Help Viewer" -Program "%ProgramFiles% (x86)\Microsoft Help Viewer\v2.3\HlpViewer.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description "Review downloadable content."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "CLR Optimization Service" -Program "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\mscorsvw.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol Any -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort Any `
-Description "mscorsvw.exe is precompiling .NET assemblies in the background.
Once it's done, it will go away. Typically, after you install the .NET Redist,
it will be done with the high priority assemblies in 5 to 10 minutes and then will wait until your computer is idle to process the low priority assemblies."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg" -Program "%SystemDrive%\Users\User\source\repos\vcpkg\vcpkg.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "install package source code"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "vcpkg (powershell)" -Program "%SystemDrive%\Users\User\source\repos\vcpkg\downloads\tools\powershell-core-6.2.1-windows\powershell.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "vcpkg has it's own powershell"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Nuget CLI" -Program "%SystemDrive%\tools\nuget.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 80, 443 `
-Description ""

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals Autoruns" -Program "%SystemDrive%\tools\Autoruns\Autoruns64.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Access to VirusTotal"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals ProcessExplorer" -Program "%SystemDrive%\tools\ProcessExplorer\procexp64.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Access to VirusTotal"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals ProcessMonitor" -Program "%SystemDrive%\tools\ProcessMonitor\Procmon.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 443 `
-Description "Access to symbols server"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals TcpView" -Program "%SystemDrive%\tools\TCPView\Tcpview.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 43 `
-Description "WhoIs access"

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Sysinternals WhoIs" -Program "%SystemDrive%\tools\WhoIs\whois64.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet -LocalPort Any -RemotePort 43 `
-Description ""

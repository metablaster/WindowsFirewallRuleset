
# Import global variables
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Setup local variables:
$Group = "Visual Studio"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Visual Studio rules
# Rules that apply to Microsoft Visual Studio
#

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 git HTTPS" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\bin\git-remote-https.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "git bundled with Visual Studio over HTTPS."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 git SSH" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
-LocalUser Any `
-Description "Team explorer Git (looks like it's not used if using custom git installation)."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 HTTPS/S" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Check for updates, symbols download and built in browser."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 Liveshare" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "liveshare extension."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 PerfWatson2" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\PerfWatson2.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "PerfWatson monitors delays on the UI thread, and submits error reports on these delays with the user’s consent."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Run when updating or using add features to VS in installer."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Used when 'Automatically download updates' in VS2019?
Tools->Options->Environment->Product Updates->Automatically download updates."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Run when Installing update or using add features to VS."

# TODO: same comment in 4 rules
New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "ServiceHub programs  provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Managed language service (Roslyn)."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "ServiceHub services  provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 Installer setup" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\setup.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Used for updates since 16.0.3."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VCTIP telemetry" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.22.27905\bin\Hostx86\x64\vctip.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools experience improvement data uploader'"

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 vs_Installer" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser Any `
-Description "Looks like it's not used anymore, but vs_installerservice is used instead"

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 vs_Installershell" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\vs_installershell.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Run when running VS Installer for add new features"

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIX" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description ""

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIXAutoUpdate" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description ""

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIXConfigurationUpdater" -Service Any -Program "%ProgramFiles% (x86)\Microsoft Visual Studio\Installer\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description ""

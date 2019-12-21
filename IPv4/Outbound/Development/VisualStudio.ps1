
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

#
# Import global variables
#
. "$PSScriptRoot\..\..\..\Modules\GlobalVariables.ps1"

# Ask user if he wants to load these rules
if (!(RunThis)) { exit }

#
# Setup local variables:
#
$Group = "Development - Visual Studio"
$Profile = "Private, Public"
$Direction = "Outbound"

#
# Visual Studio installation directories
#
$VSRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
$VSInstallerRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Visual Studio rules
# Rules that apply to Microsoft Visual Studio
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 git HTTPS" -Service Any -Program "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\bin\git-remote-https.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "git bundled with Visual Studio over HTTPS."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 git SSH" -Service Any -Program "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
-LocalUser $User `
-Description "Team explorer Git (looks like it's not used if using custom git installation)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 HTTPS/S" -Service Any -Program "$VSRoot\Common7\IDE\devenv.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $User `
-Description "Check for updates, symbols download and built in browser."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 Liveshare" -Service Any -Program "$VSRoot\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "liveshare extension."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 PerfWatson2" -Service Any -Program "$VSRoot\Common7\IDE\PerfWatson2.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "PerfWatson monitors delays on the UI thread, and submits error reports on these delays with the user’s consent."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "$VSInstallerRoot\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $User `
-Description "Run when updating or using add features to VS in installer."

# TODO: testing:  # (Get-SDDLFromAccounts @("NT AUTHORITY\SYSTEM", "$UserAccount")) `
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $NT_AUTHORITY_System `
-Description "Run in background probably for some updates"

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "$VSInstallerRoot\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Used when 'Automatically download updates' in VS2019?
Tools->Options->Environment->Product Updates->Automatically download updates."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program "$VSInstallerRoot\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Run when Installing update or using add features to VS."

# TODO: same comment in 4 rules
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\controller\Microsoft.ServiceHub.Controller.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "ServiceHub programs  provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Managed language service (Roslyn)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 ServiceHub" -Service Any -Program "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "ServiceHub services  provide identity (sign-in for VS),
and support for internal services (like extension managenent, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 Installer setup" -Service Any -Program "$VSInstallerRoot\setup.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Used for updates since 16.0.3."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VCTIP telemetry" -Service Any -Program "$VSRoot\VC\Tools\MSVC\14.22.27905\bin\Hostx86\x64\vctip.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools experience improvement data uploader'"

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 vs_Installer" -Service Any -Program "$VSInstallerRoot\vs_installer.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser $User `
-Description "Looks like it's not used anymore, but vs_installerservice is used instead"

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 vs_Installershell" -Service Any -Program "$VSInstallerRoot\vs_installershell.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Run when running VS Installer for add new features"

# TODO: needs testing if user account is needed for VSIX rules
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIX" -Service Any -Program "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $NT_AUTHORITY_System `
-Description ""

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIXAutoUpdate" -Service Any -Program "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $NT_AUTHORITY_System `
-Description ""

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "VS 2019 VSIXConfigurationUpdater" -Service Any -Program "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $NT_AUTHORITY_System `
-Description ""

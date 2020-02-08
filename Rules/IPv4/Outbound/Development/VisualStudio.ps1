
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\System
Test-SystemRequirements $VersionCheck

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\VSSetup
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Development - Visual Studio"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Visual Studio installation directories
#

# NOTE: VSSetup will return full path, no environment variables
$VSRoot = Get-VSSetupInstance | Select-VSSetupInstance -Latest | Select-Object -ExpandProperty InstallationPath
$VSInstallerRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"

#
# Visual Studio rules for executables from root directory
# Rules that apply to Microsoft Visual Studio
#

# Test if installation exists on system
if ((Test-Installation "VisualStudio" ([ref] $VSRoot)) -or $Force)
{
    $Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\bin\git-remote-https.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 git HTTPS" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "git bundled with Visual Studio over HTTPS." | Format-Output

    $Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 git SSH" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
    -LocalUser $UserAccountsSDDL `
    -Description "Team explorer Git (looks like it's not used if using custom git installation)." | Format-Output

    $Program = "$VSRoot\Common7\IDE\devenv.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 HTTPS/S" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Check for updates, symbols download and built in browser." | Format-Output

    $Program = "$VSRoot\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 Liveshare" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "liveshare extension." | Format-Output

    $Program = "$VSRoot\Common7\IDE\PerfWatson2.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 PerfWatson2" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "PerfWatson monitors delays on the UI thread, and submits error reports on these delays with the user’s consent." | Format-Output

    # TODO: same comment in 4 rules
    $Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "ServiceHub services provide identity (sign-in for VS),
    and support for internal services (like extension managenent, compiler support, etc).
    These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

    $Program = "$VSRoot\Common7\ServiceHub\controller\Microsoft.ServiceHub.Controller.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "ServiceHub services provide identity (sign-in for VS),
    and support for internal services (like extension managenent, compiler support, etc).
    These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

    $Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "ServiceHub programs  provide identity (sign-in for VS),
    and support for internal services (like extension managenent, compiler support, etc).
    These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

    $Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "ServiceHub services provide identity (sign-in for VS),
    and support for internal services (like extension managenent, compiler support, etc).
    These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

    $Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Managed language service (Roslyn)." | Format-Output

    $Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "ServiceHub services  provide identity (sign-in for VS),
    and support for internal services (like extension managenent, compiler support, etc).
    These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

    $Program = "$VSRoot\VC\Tools\MSVC\14.24.28314\bin\Hostx86\x64\vctip.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 VCTIP telemetry" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools experience improvement data uploader'" | Format-Output
}

#
# Visual Studio rules for executables from installer directory
# Rules that apply to Microsoft Visual Studio
#

# Test if installation exists on system
if ((Test-Installation "VisualStudioInstaller" ([ref] $VSInstallerRoot)) -or $Force)
{
    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Run when updating or using add features to VS in installer." | Format-Output

    # TODO: testing:  # (Get-SDDLFromAccounts @("NT AUTHORITY\SYSTEM", "$UserAccount")) `
    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $NT_AUTHORITY_System `
    -Description "Used when 'Automatically download updates' in VS2019?
    Tools->Options->Environment->Product Updates->Automatically download updates." | Format-Output

    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 ServiceHub Installer" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Run when Installing update or using add features to VS, also for sign in, in report problem window." | Format-Output

    $Program = "$VSInstallerRoot\setup.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 Installer setup" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Used for updates since 16.0.3." | Format-Output

    $Program = "$VSInstallerRoot\vs_installer.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 vs_Installer" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
    -LocalUser $UserAccountsSDDL `
    -Description "Looks like it's not used anymore, but vs_installerservice is used instead" | Format-Output

    $Program = "$VSInstallerRoot\vs_installershell.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 vs_Installershell" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "Run when running VS Installer for add new features" | Format-Output

    # TODO: needs testing what users are needed for VSIX rules
    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 VSIX" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "" | Format-Output

    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 VSIXAutoUpdate" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $NT_AUTHORITY_System `
    -Description "" | Format-Output

    $Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "VS 2019 VSIXConfigurationUpdater" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
    -LocalUser $UserAccountsSDDL `
    -Description "" | Format-Output
}

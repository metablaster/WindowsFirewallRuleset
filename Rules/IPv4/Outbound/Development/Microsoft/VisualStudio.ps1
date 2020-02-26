
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

. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Development - Microsoft Visual Studio"
$Profile = "Private, Public"
$VSUpdateUsers = Get-SDDL -Group "Users", "Administrators"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Visual Studio installation directories
#

# TODO: use empty "" for all cases for testing
$VSRoot = ""
$VSInstallerRoot = "" # "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"

#
# Visual Studio rules for executables from root directory
# Rules that apply to Microsoft Visual Studio
# TODO: Take Display name partially from Get-VSSetupInstance
# TODO: run rules for each instance
#

# Test if installation exists on system
if ((Test-Installation "VisualStudio" ([ref] $VSRoot)) -or $ForceLoad)
{
	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\bin\git-remote-https.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest git HTTPS" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "git bundled with Visual Studio over HTTPS." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest git SSH" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
	-LocalUser $UsersSDDL `
	-Description "Team explorer Git (looks like it's not used if using custom git installation)." @Logs | Format-Output @Logs

	# TODO: need better approach for administrators, ie. powershell, VS, services etc. maybe separate group, or put into "temporary" group?
	$Program = "$VSRoot\Common7\IDE\devenv.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest HTTPS/S" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $VSUpdateUsers `
	-Description "Check for updates, symbols download and built in browser." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest Liveshare" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "liveshare extension." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\IDE\PerfWatson2.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest PerfWatson2" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "PerfWatson monitors delays on the UI thread, and submits error reports on these delays with the user’s consent." @Logs | Format-Output @Logs

	# TODO: same comment in 4 rules
	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension managenent, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\ServiceHub\controller\Microsoft.ServiceHub.Controller.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension managenent, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "ServiceHub programs  provide identity (sign-in for VS),
	and support for internal services (like extension managenent, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension managenent, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "Managed language service (Roslyn)." @Logs | Format-Output @Logs

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "ServiceHub services  provide identity (sign-in for VS),
	and support for internal services (like extension managenent, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." @Logs | Format-Output @Logs

	$Program = "$VSRoot\VC\Tools\MSVC\14.24.28314\bin\Hostx86\x64\vctip.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest VCTIP telemetry" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools experience improvement data uploader'" @Logs | Format-Output @Logs
}

#
# Visual Studio rules for executables from installer directory
# Rules that apply to Microsoft Visual Studio
#

# Test if installation exists on system
if ((Test-Installation "VisualStudioInstaller" ([ref] $VSInstallerRoot)) -or $ForceLoad)
{
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub Installer" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "Run when updating or using add features to VS in installer." @Logs | Format-Output @Logs

	# TODO: testing:  # (Get-SDDLFromAccounts @("NT AUTHORITY\SYSTEM", "$UserAccount")) `
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub Installer" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_System `
	-Description "Used when 'Automatically download updates' in VS2019?
	Tools->Options->Environment->Product Updates->Automatically download updates." @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest ServiceHub Installer" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "Run when Installing update or using add features to VS, also for sign in, in report problem window." @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\setup.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest Installer setup" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $VSUpdateUsers `
	-Description "Used for updates since 16.0.3." @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\vs_installer.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest vs_Installer" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersSDDL `
	-Description "Looks like it's not used anymore, but vs_installerservice is used instead" @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\vs_installershell.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest vs_Installershell" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "Run when running VS Installer for add new features" @Logs | Format-Output @Logs

	# TODO: needs testing what users are needed for VSIX rules
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest VSIX" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest VSIXAutoUpdate" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_System `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "VS Latest VSIXConfigurationUpdater" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs
}

Update-Logs

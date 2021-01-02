
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Outbound firewall rules for VisualStudio

.DESCRIPTION
Outbound firewall rules for Visual Studio IDE

.EXAMPLE
PS> .\VisualStudio.ps1

.INPUTS
None. You cannot pipe objects to VisualStudio.ps1

.OUTPUTS
None. VisualStudio.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Microsoft Visual Studio"
# Only Administrators can update VS
$VSUpdateUsers = Get-SDDL -Group "Users", "Administrators"

$ExtensionAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
Merge-SDDL ([ref] $ExtensionAccounts) -From $UsersGroupSDDL
$Accept = "Outbound rules for Microsoft Visual Studio will be loaded, recommended if Microsoft Visual Studio is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Microsoft Visual Studio will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Visual Studio installation directories
#

$VSRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
$VSInstallerRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"

#
# Visual Studio rules for executables from root directory
# Rules which apply to Microsoft Visual Studio
# TODO: Take Display name partially from Get-VSSetupInstance
# TODO: No rule for C:\ProgramData\Microsoft\VisualStudio\SetupWMI\MofCompiler.exe
#

# TODO: This is temporary hack, overriding the switch case in ProgramInfo module
# When updated the import module VSSetup should be removed in this file
$VSInstances = Get-VSSetupInstance -Prerelease

# Test if installation exists on system
# if ((Confirm-Installation "VisualStudio" ([ref] $VSRoot)) -or $ForceLoad)
foreach ($Instance in $VSInstances)
{
	$VSRoot = Format-Path $Instance.InstallationPath
	$DisplayName = $Instance.DisplayName

	# DisplayName is different only for different release years
	if ($VSRoot -like "*Preview*")
	{
		$DisplayName += " Preview"
	}

	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) CMake" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "CMake bundled with Visual Studio" | Format-Output

	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\bin\git-remote-https.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) git HTTPS" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "git bundled with Visual Studio over HTTPS." | Format-Output

	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) git SSH" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
		-LocalUser $UsersGroupSDDL `
		-Description "Team explorer Git (looks like it's not used if using custom git installation)." | Format-Output

	# TODO: need better approach for administrators, ie. powershell, VS, services etc. maybe separate group, or put into "temporary" group?
	$Program = "$VSRoot\Common7\IDE\devenv.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) HTTPS/S" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $VSUpdateUsers `
		-Description "Check for updates, symbols download and built in browser." | Format-Output

	$Program = "$VSRoot\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) Liveshare" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "liveshare extension." | Format-Output

	$Program = "$VSRoot\Common7\IDE\PerfWatson2.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) PerfWatson2" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "PerfWatson monitors delays on the UI thread, and submits error reports on these delays with the user's consent." | Format-Output

	# TODO: same comment in 4 rules
	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

	$Program = "$VSRoot\Common7\ServiceHub\controller\Microsoft.ServiceHub.Controller.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

	# NOTE: System account is needed for port 9354
	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443, 9354 `
		-LocalUser $ExtensionAccounts `
		-Description "ServiceHub programs provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Managed language service (Roslyn)." | Format-Output

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." | Format-Output

	# NOTE: subdirectory name consists of version number so let's get that:
	# NOTE: Get-ChildItem doesn't recognize environment variables
	$MSVCVersion = Get-ChildItem -Directory -Name -Path "$($Instance.InstallationPath)\VC\Tools\MSVC"

	# There should be only one directory, but just in case let's select highest version
	$MSVCVersion = $MSVCVersion | Select-Object -Last 1

	$Program = "$VSRoot\VC\Tools\MSVC\$script:MSVCVersion\bin\Hostx86\x64\vctip.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "$($DisplayName) VCTIP telemetry" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools experience improvement data uploader'" | Format-Output
}

#
# Visual Studio rules for executables from installer directory
# Rules which apply to Microsoft Visual Studio
# NOTE: these rules are global to all VS instances
#

# Test if installation exists on system
if ((Confirm-Installation "VisualStudioInstaller" ([ref] $VSInstallerRoot)) -or $ForceLoad)
{
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Run when updating or using add features to VS in installer." | Format-Output

	# NOTE: tested: $ExtensionAccounts, Administrator account was needed
	# TODO: testing: $VSUpdateUsers
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $VSUpdateUsers `
		-Description "Used when 'Automatically download updates' in VS2019?
	Tools->Options->Environment->Product Updates->Automatically download updates." | Format-Output

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - ServiceHub" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Run when Installing update or using add features to VS, also for sign in, in report problem window." | Format-Output

	$Program = "$VSInstallerRoot\setup.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - Setup" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $VSUpdateUsers `
		-Description "Used for updates since 16.0.3." | Format-Output

	$Program = "$VSInstallerRoot\vs_installer.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - vs_Installer" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "Looks like it's not used anymore, but vs_installerservice is used instead" | Format-Output

	$Program = "$VSInstallerRoot\vs_installershell.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - vs_Installershell" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $VSUpdateUsers `
		-Description "Run when running VS Installer for add new features" | Format-Output

	# TODO: needs testing what users are needed for VSIX rules
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - VSIX" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - VSIXAutoUpdate" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $LocalSystem `
		-Description "" | Format-Output

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "VS Installer - VSIXConfigurationUpdater" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output
}

Update-Log


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
Outbound firewall rules for VisualStudio

.DESCRIPTION
Outbound firewall rules for Visual Studio IDE

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
PS> .\VisualStudio.ps1

.INPUTS
None. You cannot pipe objects to VisualStudio.ps1

.OUTPUTS
None. VisualStudio.ps1 does not generate any output

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
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Microsoft Visual Studio"
# Only Administrators can update VS
$VSUpdateUsers = Get-SDDL -Group "Users", "Administrators" -Merge

$ExtensionAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
Merge-SDDL ([ref] $ExtensionAccounts) -From $UsersGroupSDDL
$Accept = "Outbound rules for Microsoft Visual Studio will be loaded, recommended if Microsoft Visual Studio is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Microsoft Visual Studio will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
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
$VSInstances = Invoke-Command -Session $SessionInstance -ScriptBlock {
	Get-VSSetupInstance -Prerelease
}

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
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) CMake" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "CMake bundled with Visual Studio" | Format-RuleOutput
	}

	# $VSRoot has environment variables
	$mingwDirectory = Invoke-Command -Session $SessionInstance -ArgumentList $Instance.InstallationPath -ScriptBlock {
		param ($InstallationPath)

		# TODO: Not ignoring "not found" error because Test-ExecutableFile may not be reached
		Get-ChildItem -Path "$InstallationPath\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git" -Directory |
		Where-Object {
			# This might be mingw32 or mingw64
			$_.Name -like "mingw*"
		} | Select-Object -ExpandProperty Name
	}

	# TODO: Will not force load if directory not found
	foreach ($mingw in $mingwDirectory)
	{
		$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\$mingw\bin\git-remote-https.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) git HTTPS" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "git bundled with Visual Studio over HTTPS." | Format-RuleOutput
		}
	}

	$Program = "$VSRoot\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\usr\bin\ssh.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) git SSH" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Block -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 22 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Team explorer Git (looks like it's not used if using custom git installation)." |
		Format-RuleOutput
	}

	# TODO: need better approach for administrators, ie. powershell, VS, services etc. maybe separate group, or put into "temporary" group?
	$Program = "$VSRoot\Common7\IDE\devenv.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) HTTPS/S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $VSUpdateUsers `
			-InterfaceType $DefaultInterface `
			-Description "Check for updates, symbols download and built in browser." | Format-RuleOutput
	}

	$Program = "$VSRoot\Common7\IDE\Extensions\Microsoft\LiveShare\Agent\vsls-agent.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) Liveshare" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "liveshare extension." | Format-RuleOutput
	}

	$Program = "$VSRoot\Common7\IDE\PerfWatson2.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) PerfWatson2" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "PerfWatson monitors delays on the UI thread, and submits error reports on
these delays with the user's consent." | Format-RuleOutput
	}

	$PathStatus = Invoke-Command -Session $SessionInstance -ScriptBlock {
		# NOTE: This path doesn't seem to exist in recent versions of VS, testing path to avoid generating warnings
		Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($using:VSRoot))\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86"
	}

	if ($PathStatus -or $ForceLoad)
	{
		# TODO: same comment in 4 rules
		$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.Host.CLR.x86.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
			Format-RuleOutput
		}

		# NOTE: System account is needed for port 9354
		$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.SettingsHost.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub SettingsHost" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443, 9354 `
				-LocalUser $ExtensionAccounts `
				-InterfaceType $DefaultInterface `
				-Description "ServiceHub programs provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
			Format-RuleOutput
		}

		$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.IdentityHost.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub IdentityHost" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
			Format-RuleOutput
		}

		$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.RoslynCodeAnalysisService32.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub Roslyn Code Analysis" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Block -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "Managed language service (Roslyn)." | Format-RuleOutput
		}

		$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.CLR.x86\ServiceHub.VSDetouredHost.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub VSDetouredHost" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." |
			Format-RuleOutput
		}
	}

	$Program = "$VSRoot\Common7\ServiceHub\controller\Microsoft.ServiceHub.Controller.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub Controller" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
		Format-RuleOutput
	}

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.netfx.x86\ServiceHub.IdentityHost.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub IdentityHost" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
		Format-RuleOutput
	}

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.Dotnet.x64\ServiceHub.IdentityHost.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub IdentityHost" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "ServiceHub services provide identity (sign-in for VS),
and support for internal services (like extension management, compiler support, etc).
These are not optional and are designed to be running side-by-side with devenv.exe." |
		Format-RuleOutput
	}

	$Program = "$VSRoot\Common7\ServiceHub\Hosts\ServiceHub.Host.AnyCPU\ServiceHub.VSDetouredHost.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) ServiceHub VSDetouredHost" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "ServiceHub services provide identity (sign-in for VS),
	and support for internal services (like extension management, compiler support, etc).
	These are not optional and are designed to be running side-by-side with devenv.exe." |
		Format-RuleOutput
	}

	# Subdirectory name consists of version number so let's get that:
	$MSVCVersion = Invoke-Command -Session $SessionInstance -ArgumentList $Instance.InstallationPath -ScriptBlock {
		param ($InstallationPath)

		Get-ChildItem -Directory -Name -Path "$InstallationPath\VC\Tools\MSVC" -ErrorAction SilentlyContinue
	}

	# There should be only one directory, but just in case let's select highest version
	$MSVCVersion = $MSVCVersion | Select-Object -Last 1

	# TODO: If MSVC isn't installed this translates to null: ...\MSVC\\bin\...
	$Program = "$VSRoot\VC\Tools\MSVC\$MSVCVersion\bin\Hostx86\x64\vctip.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "$($DisplayName) VCTIP telemetry" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Runs when opening up VS, vctip.exe is 'Microsoft VC compiler and tools
experience improvement data uploader'" | Format-RuleOutput
	}
}

#
# Visual Studio rules for executables from installer directory
# Rules which apply to Microsoft Visual Studio
# NOTE: these rules are global to all VS instances
#

# Test if installation exists on system
if ((Confirm-Installation "VisualStudioInstaller" ([ref] $VSInstallerRoot)) -or $ForceLoad)
{
	$Program = "$VSInstallerRoot\feedback.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - Feedback" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Installer feedback" | Format-RuleOutput
	}

	$PathStatus = Invoke-Command -Session $SessionInstance -ScriptBlock {
		# NOTE: This path doesn't seem to exist in recent versions of VS, testing path to avoid generating warnings
		Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($using:VSInstallerRoot))\resources\app\ServiceHub\Hosts"
	}

	if ($PathStatus -or $ForceLoad)
	{
		$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "VS Installer - ServiceHub Installer Service x64" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 80, 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "Run when updating or using add features to VS in installer." | Format-RuleOutput
		}

		$Program = "$VSInstallerRoot\resources\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "VS Installer - ServiceHub Installer Service x86" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "Run when Installing update or using add features to VS, also for sign in,
in report problem window." | Format-RuleOutput
		}
	}

	# NOTE: tested: $ExtensionAccounts, Administrator account was needed
	# TODO: testing: $VSUpdateUsers
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\BackgroundDownload.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - ServiceHub Background Download" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $VSUpdateUsers `
			-InterfaceType $DefaultInterface `
			-Description "Used when 'Automatically download updates' in VS2019?
Tools->Options->Environment->Product Updates->Automatically download updates." | Format-RuleOutput
	}

	$Program = "$VSInstallerRoot\setup.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - Setup" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $VSUpdateUsers `
			-InterfaceType $DefaultInterface `
			-Description "Used for updates since 16.0.3." | Format-RuleOutput
	}

	$Program = "$VSInstallerRoot\vs_installer.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - vs_Installer" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Looks like it's not used anymore, but vs_installerservice is used instead" |
		Format-RuleOutput
	}

	$Program = "$VSInstallerRoot\vs_installershell.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - vs_Installershell" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $VSUpdateUsers `
			-InterfaceType $DefaultInterface `
			-Description "Run when running VS Installer for add new features" | Format-RuleOutput
	}

	# TODO: needs testing what users are needed for VSIX rules
	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXInstaller.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - VSIX" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXAutoUpdate.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - VSIXAutoUpdate" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	$Program = "$VSInstallerRoot\resources\app\ServiceHub\Services\Microsoft.VisualStudio.Setup.Service\VSIXConfigurationUpdater.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "VS Installer - VSIXConfigurationUpdater" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log


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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Initialize-Project

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

#
# Setup local variables:
#
$Group = "Software - Nvidia"
$FirewallProfile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Nvidia installation directories
#
$NvidiaRoot64 = "%ProgramFiles%\NVIDIA Corporation"
$NvidiaRoot86 = "%ProgramFiles(x86)%\NVIDIA Corporation"
Set-Variable -Name GeForce -Scope Script -Value $null

# Some rules use multiple accounts
# TODO: we should probably have better approach to assemble SDDL's for multiple domains
$ContainerAccounts = $NT_AUTHORITY_System
Merge-SDDL ([ref] $ContainerAccounts) $UsersGroupSDDL @Logs

#
# Rules for Nvidia 64bit executables
# TODO: need universal handling of x64 and x86 rules, ie. on 64 bit systems both apply, while
# on x86 system this is not true, also some x64, x86 rules here are duplicate, ie. GFExperience
# Also some rules are not implemented for x86
#

# Test if installation exists on system
if ([System.Environment]::Is64BitOperatingSystem)
{
	if ((Test-Installation "Nvidia64" ([ref] $NvidiaRoot64) @Logs) -or $ForceLoad)
	{
		# Dummy variable, needs to be known because Test-Installation will return same path as nvidia root
		$GeForceRoot = "$NvidiaRoot64\NVIDIA GeForce Experience"
		Set-Variable -Name GeForce -Scope Script -Value $(Test-Installation "GeForceExperience" ([ref] $GeForceRoot) @Logs)

		# Test if GeForce experience exists on system, the path is same
		# TODO: this is temporary measure, it should be checked with Test-File function
		if ($script:GeForce -or $ForceLoad)
		{
			$Program = "$NvidiaRoot64\NvContainer\nvcontainer.exe"
			Test-File $Program @Logs

			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Nvidia Container x64" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser $ContainerAccounts `
				-Description "" @Logs | Format-Output @Logs

			$Program = "$NvidiaRoot64\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"
			Test-File $Program @Logs

			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Nvidia GeForce Experience x64" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
				-LocalUser $UsersGroupSDDL `
				-Description "" @Logs | Format-Output @Logs

			# TODO: this rule is not implemented for x86 system
			$Program = "$NvidiaRoot64\Update Core\NvProfileUpdater64.exe"
			Test-File $Program @Logs

			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Nvidia Profile Updater" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser $UsersGroupSDDL `
				-Description "" @Logs | Format-Output @Logs
		}

		# NOTE: this program no longer exists in recent installations
		# $Program = "$NvidiaRoot64\Display.NvContainer\NVDisplay.Container.exe"

		# NOTE: this is hardcoded and not universal path
		# $Program = "%SystemRoot%\System32\DriverStore\FileRepository\nv_dispi.inf_amd64_90685a092bcf58c7\Display.NvContainer\NVDisplay.Container.exe"

		# This may take several seconds, tell user what is going on
		Write-Information -Tags "User" -MessageData "INFO: Querying driver store for NVDisplay Container..."

		# TODO: we need to query drivers for all such programs in DriverStore, ex Get-DriverPath function
		[string] $Driver = Get-WindowsDriver -Online -All |
		Where-Object -Property OriginalFileName -Like "*nv_dispi.inf" |
		Sort-Object -Property Version -Descending |
		Select-Object -First 1 -ExpandProperty OriginalFilename

		$Program = Split-Path $Driver -Parent | Format-Path
		$Program += "\Display.NvContainer\NVDisplay.Container.exe"

		if ([string]::IsNullOrEmpty($Program))
		{
			# TODO: This is from Test-File, Test-File should handle this, see also todo in Test-File
			$NVDisplayExe = "NVDisplay.Container.exe"
			Write-Warning -Message "Executable '$NVDisplayExe' was not found, rules for '$NVDisplayExe' won't have any effect"

			Write-Information -Tags "User" -MessageData "INFO: Searched path was: %SystemRoot%\System32\DriverStore\FileRepository"
			Write-Information -Tags "User" -MessageData "INFO: To fix the problem find '$NVDisplayExe' and adjust the path in $Script and re-run the script"
		}
		else
		{
			Test-File $Program @Logs
			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Nvidia NVDisplay Container x64" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser $NT_AUTHORITY_System `
				-Description "" @Logs | Format-Output @Logs
		}
	}
}

#
# Rules for Nvidia 32bit executables
#

# Test if installation exists on system
if ((Test-Installation "Nvidia86" ([ref] $NvidiaRoot86) @Logs) -or $ForceLoad)
{
	# Dummy variable, needs to be known because Test-Installation will return same path as nvidia root
	$GeForceXProot = "$NvidiaRoot86\NVIDIA GeForce Experience"

	# Test if GeForce experience exists on system, the path is same
	# NOTE: This check is needed for current x64 bit setup to avoid double prompt
	if ($null -eq $script:GeForce)
	{
		$script:GeForce = $(Test-Installation "GeForceExperience" ([ref] $GeForceXProot) @Logs)
	}

	# TODO: this is temporary measure, it should be checked with Test-File function
	if ($script:GeForce -or $ForceLoad)
	{
		$Program = "$NvidiaRoot86\NvContainer\nvcontainer.exe"
		Test-File $Program @Logs

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Nvidia Container x86" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $ContainerAccounts `
			-Description "" @Logs | Format-Output @Logs

		# NOTE: it's duplicate of x64 rule, should be fixed after testing x86 rules
		if (![System.Environment]::Is64BitOperatingSystem)
		{
			$Program = "$NvidiaRoot86\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"
			Test-File $Program @Logs
			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Nvidia GeForce Experience x86" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser $UsersGroupSDDL `
				-Description "" @Logs | Format-Output @Logs
		}

		# NOTE: this program no longer exists in recent installations, most likely changed!
		# $Program = "$NvidiaRoot86\NvTelemetry\NvTelemetryContainer.exe"
		# Test-File $Program @Logs
		# New-NetFirewallRule -Platform $Platform `
		# 	-DisplayName "Nvidia Telemetry Container" -Service Any -Program $Program `
		# 	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		# 	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		# 	-LocalUser $UsersGroupSDDL `
		# 	-Description "" @Logs | Format-Output @Logs

		$Program = "$NvidiaRoot86\NvNode\NVIDIA Web Helper.exe"
		Test-File $Program @Logs

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Nvidia WebHelper TCP" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-Description "" @Logs | Format-Output @Logs
	}
}

Update-Log

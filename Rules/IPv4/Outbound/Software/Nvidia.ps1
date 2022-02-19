
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Outbound firewall rules for Nvidia

.DESCRIPTION
Outbound firewall rules for from Nvidia

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
PS> .\Nvidia.ps1

.INPUTS
None. You cannot pipe objects to Nvidia.ps1

.OUTPUTS
None. Nvidia.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - Nvidia"
$Accept = "Outbound rules for Nvidia software will be loaded, recommended if Nvidia software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Nvidia software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues = @{
	"Confirm-Installation:Quiet" = $Quiet
	"Confirm-Installation:Interactive" = $Interactive
	"Confirm-Installation:Session" = $SessionInstance
	"Confirm-Installation:CimSession" = $CimServer
	"Test-ExecutableFile:Quiet" = $Quiet
	"Test-ExecutableFile:Force" = $Trusted -or $SkipSignatureCheck
	"Test-ExecutableFile:Session" = $SessionInstance
}
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Nvidia installation directories
#
$NvidiaRoot64 = "%ProgramFiles%\NVIDIA Corporation"
$NvidiaRoot86 = "%ProgramFiles(x86)%\NVIDIA Corporation"
Set-Variable -Name GeForce -Scope Script -Value $null

# Some rules use multiple accounts
# TODO: we should probably have better approach to assemble SDDL's for multiple domains
$ContainerAccounts = $LocalSystem
Merge-SDDL ([ref] $ContainerAccounts) -From $UsersGroupSDDL

#
# Rules for Nvidia 64bit executables
# TODO: need universal handling of x64 and x86 rules, ie. on 64 bit systems both apply, while
# on x86 system this is not true, also some x64, x86 rules here are duplicate, ie. GFExperience
# Also some rules are not implemented for x86
#

# Test if installation exists on system
if ([System.Environment]::Is64BitOperatingSystem)
{
	if ((Confirm-Installation "Nvidia64" ([ref] $NvidiaRoot64)) -or $ForceLoad)
	{
		# Dummy variable, needs to be known because Confirm-Installation will return same path as nvidia root
		$GeForceRoot = "$NvidiaRoot64\NVIDIA GeForce Experience"
		Set-Variable -Name GeForce -Scope Script -Value ((Confirm-Installation "GeForceExperience" ([ref] $GeForceRoot)) -or $ForceLoad)

		# Test if GeForce experience exists on system, the path is same
		# TODO: this is temporary measure, it should be checked with Test-ExecutableFile function
		if ($script:GeForce -or $ForceLoad)
		{
			$Program = "$NvidiaRoot64\NvContainer\nvcontainer.exe"
			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Nvidia Container x64" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 80, 443 `
					-LocalUser $ContainerAccounts `
					-InterfaceType $DefaultInterface `
					-Description "" | Format-RuleOutput
			}

			$Program = "$NvidiaRoot64\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"
			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Nvidia GeForce Experience x64" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 443 `
					-LocalUser $UsersGroupSDDL `
					-InterfaceType $DefaultInterface `
					-Description "" | Format-RuleOutput
			}

			# TODO: this rule is not implemented for x86 system
			$Program = "$NvidiaRoot64\Update Core\NvProfileUpdater64.exe"
			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Nvidia Profile Updater" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 80, 443 `
					-LocalUser $UsersGroupSDDL `
					-InterfaceType $DefaultInterface `
					-Description "" | Format-RuleOutput
			}
		}

		# NOTE: this program no longer exists in recent installations
		# $Program = "$NvidiaRoot64\Display.NvContainer\NVDisplay.Container.exe"

		# NOTE: this is hardcoded and not universal path
		# $Program = "%SystemRoot%\System32\DriverStore\FileRepository\nv_dispi.inf_amd64_90685a092bcf58c7\Display.NvContainer\NVDisplay.Container.exe"

		# This may take several seconds, tell user what is going on
		Write-Information -Tags $ThisScript -MessageData "INFO: Querying driver store for NVDisplay Container..."

		# TODO: we need to query drivers for all such programs in DriverStore, ex Get-DriverPath function
		# TODO: might not work for DCH drivers, for difference with "standard" drivers see:
		# https://nvidia.custhelp.com/app/answers/detail/a_id/4777/~/nvidia-dch%2Fstandard-display-drivers-for-windows-10-faq
		[string] $Driver = Get-WindowsDriver -Online -All |
		Where-Object -Property OriginalFileName -Like "*nv_dispi.inf" |
		Sort-Object -Property Version -Descending |
		Select-Object -First 1 -ExpandProperty OriginalFilename

		if ([string]::IsNullOrEmpty($Driver))
		{
			# TODO: This is from Test-ExecutableFile, Test-ExecutableFile should handle this, see also todo in Test-ExecutableFile
			$NVDisplayExe = "NVDisplay.Container.exe"
			Write-Warning -Message "[$ThisScript] Executable '$NVDisplayExe' was not found, rules for '$NVDisplayExe' won't have any effect"

			Write-Information -Tags $ThisScript -MessageData "INFO: Searched path was: %SystemRoot%\System32\DriverStore\FileRepository"
			Write-Information -Tags $ThisScript -MessageData "INFO: To fix this problem find '$NVDisplayExe' and adjust the path in $((Get-Item $PSCommandPath).Name) and re-run the script"
		}
		else
		{
			$Program = Split-Path -Path $Driver -Parent | Format-Path
			$Program += "\Display.NvContainer\NVDisplay.Container.exe"

			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Nvidia NVDisplay Container x64" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 80, 443 `
					-LocalUser $LocalSystem `
					-InterfaceType $DefaultInterface `
					-Description "" | Format-RuleOutput
			}
		}
	}
}

#
# Rules for Nvidia 32bit executables
#

# Test if installation exists on system
if ((Confirm-Installation "Nvidia86" ([ref] $NvidiaRoot86)) -or $ForceLoad)
{
	# Dummy variable, needs to be known because Confirm-Installation will return same path as nvidia root
	$GeForceXPRoot = "$NvidiaRoot86\NVIDIA GeForce Experience"

	# Test if GeForce experience exists on system, the path is same
	# NOTE: This check is needed for current x64 bit setup to avoid double prompt
	if ($null -eq $script:GeForce)
	{
		$script:GeForce = (Confirm-Installation "GeForceExperience" ([ref] $GeForceXPRoot))
	}

	# TODO: this is temporary measure, it should be checked with Test-ExecutableFile function
	if ($script:GeForce -or $ForceLoad)
	{
		$Program = "$NvidiaRoot86\NvContainer\nvcontainer.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "Nvidia Container x86" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 80, 443 `
				-LocalUser $ContainerAccounts `
				-InterfaceType $DefaultInterface `
				-Description "" | Format-RuleOutput
		}

		# NOTE: it's duplicate of x64 rule, should be fixed after testing x86 rules
		if (![System.Environment]::Is64BitOperatingSystem)
		{
			$Program = "$NvidiaRoot86\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"
			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Nvidia GeForce Experience x86" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 80, 443 `
					-LocalUser $UsersGroupSDDL `
					-InterfaceType $DefaultInterface `
					-Description "" | Format-RuleOutput
			}
		}

		# NOTE: this program no longer exists in recent installations, most likely changed!
		# $Program = "$NvidiaRoot86\NvTelemetry\NvTelemetryContainer.exe"
		# Test-ExecutableFile $Program
		# New-NetFirewallRule -DisplayName "Nvidia Telemetry Container" `
		# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		# 	-Service Any -Program $Program -Group $Group `
		# 	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
		# 	-LocalAddress Any -RemoteAddress Internet4 `
		# 	-LocalPort Any -RemotePort 443 `
		# 	-LocalUser $UsersGroupSDDL `
		#   -InterfaceType $DefaultInterface `
		# 	-Description "" | Format-RuleOutput

		$Program = "$NvidiaRoot86\NvNode\NVIDIA Web Helper.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "Nvidia WebHelper TCP" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program $Program -Group $Group `
				-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Internet4 `
				-LocalPort Any -RemotePort 80, 443 `
				-LocalUser $UsersGroupSDDL `
				-InterfaceType $DefaultInterface `
				-Description "" | Format-RuleOutput
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log

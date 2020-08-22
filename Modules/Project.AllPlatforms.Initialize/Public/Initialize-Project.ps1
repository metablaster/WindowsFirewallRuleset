
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

<#
.SYNOPSIS
Check system requirements for this project
.DESCRIPTION
Initialize-Project is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, .NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.
.PARAMETER NoProjectCheck
If supplied, checking for project requirements and recommendations will not be performed,
This is equivalent to function that does nothing.
Note that this parameter is managed by project settings
.PARAMETER NoModulesCheck
If supplied, checking for required and recommended module updates will not be performed.
Note that this parameter is managed by project settings
.PARAMETER NoServicesCheck
If supplied, checking if required system services are running will not be performed.
Note that this parameter is managed by project settings
.EXAMPLE
PS> Initialize-Project
Performs default requirements and recommendations checks managed by global settings,
Error or warning message is shown if check failed, environment info otherwise.
.EXAMPLE
PS> Initialize-Project -NoModulesCheck
Performs default requirements and recommendations checks managed by global settings,
except installed modules are not validated.
Error or warning message is shown if check failed, environment info otherwise.
.INPUTS
None. You cannot pipe objects to Initialize-Project
.OUTPUTS
None.
.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

TODO: learn required NET version by scanning scripts (ie. adding .COMPONENT to comments)
TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
TODO: checking remote systems not implemented
#>
function Initialize-Project
{
	[OutputType([void])]
	[CmdletBinding()]
	param (
		[Parameter(ParameterSetName = "Project")]
		[switch] $NoProjectCheck = !$ProjectCheck,

		[Parameter(ParameterSetName = "NotProject")]
		[switch] $NoModulesCheck = !$ModulesCheck,

		[Parameter(ParameterSetName = "NotProject")]
		[switch] $NoServicesCheck = !$ServicesCheck
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# disabled when running scripts from SetupFirewall.ps1 script, in which case it runs only once
	if ($NoProjectCheck)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Project initialization skipped"
		return
	}

	# Print watermark
	Write-Output ""
	Write-Output "Windows Firewall Ruleset v$($ProjectVersion.ToString())"
	Write-Output "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"
	Write-Output "https://github.com/metablaster/WindowsFirewallRuleset"
	Write-Output ""

	Write-Information -Tags "User" -MessageData "INFO: Checking operating system"

	# Check operating system, for possible values see [System.PlatformID]::
	$OSPlatform = [System.Environment]::OSVersion.Platform

	if ($OSPlatform -ne "Win32NT")
	{
		Write-Error -Category OperationStopped -TargetObject $OSPlatform `
			-Message "$OSPlatform platform is not supported, required platform is Win32NT"
		exit
	}

	# Check OS version
	[version] $TargetOSVersion = [System.Environment]::OSVersion.Version

	if ($TargetOSVersion -lt $RequireWindowsVersion)
	{
		[string] $OSMajorMinor = "$($TargetOSVersion.Major).$($TargetOSVersion.Minor)"
		Write-Error -Category NotImplemented -TargetObject $TargetOSVersion `
			-Message "Minimum supported operating system is 'Windows v$($RequireWindowsVersion.ToString())' but 'Windows v$OSMajorMinor present"
		exit
	}

	# Check if in elevated PowerShell
	Write-Information -Tags "User" -MessageData "INFO: Checking user account elevation"
	$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

	if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Error -Category PermissionDenied -TargetObject $Principal `
			-Message "Elevation required, please open PowerShell as Administrator and try again"
		exit
	}

	# Check OS is not Home edition
	# NOTE: Get-WindowsEdition requires elevation
	Write-Information -Tags "User" -MessageData "INFO: Checking OS edition"
	$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

	if ($OSEdition -like "*Home*")
	{
		Write-Error -Category OperationStopped -TargetObject $OSEdition `
			-Message "Windows $OSEdition doesn't have Local Group Policy required by this project"
		exit
	}

	# Check OS build version
	[Int32] $TargetOSBuildVersion = ConvertFrom-OSBuild $TargetOSVersion.Build

	if ($TargetOSBuildVersion -lt 1909)
	{
		Write-Warning -Message "Target system version is v$TargetOSBuildVersion, few rules might not work, please upgrade to at least v1909"
	}

	# Check PowerShell edition
	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell edition"
	$PowerShellEdition = $PSVersionTable.PSEdition

	# Check PowerShell version
	[version] $RequirePSVersion = $RequirePowerShellVersion
	[version] $TargetPSVersion = $PSVersionTable.PSVersion

	if ($PowerShellEdition -eq "Core")
	{
		$RequirePSVersion = $RequireCoreVersion
		Write-Warning -Message "Remote firewall administration with PowerShell Core is not implemented"
	}
	else
	{
		# Default is set to 3.0.0 for Core editions
		Set-Variable -Name RequireNuGetVersion -Scope Global -Force -Value $([version]::new(2, 8, 5))
		Write-Warning -Message "Remote firewall administration with PowerShell $PowerShellEdition is partially implemented"
	}

	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell version"
	if ($TargetPSVersion -lt $RequirePSVersion)
	{
		# TODO: Core 6.1 should be fine, skipping
		if (($PowerShellEdition -eq "Desktop") -or ($TargetPSVersion -lt "6.1"))
		{
			Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
				-Message "Required PowerShell $PowerShellEdition is v$($RequirePSVersion.ToString()) but v$($TargetPSVersion.ToString()) present"
			exit
		}

		Write-Warning -Message "Recommended PowerShell $PowerShellEdition is v$($RequirePSVersion.ToString()) but v$($TargetPSVersion.ToString()) present"
	}

	if (!$NoServicesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking system services"

		# These services are minimum required
		$RequiredServices = @(
			"lmhosts" # TCP/IP NetBIOS Helper
			"LanmanWorkstation" # Workstation
			"LanmanServer" # Server
		)

		if (!(Initialize-Service $RequiredServices)) { exit }

		# NOTE: remote administration needs this service, see Enable-PSRemoting cmdlet
		# NOTE: some tests depend on this service, project not ready for remoting
		if ($Develop -and ($PolicyStore -ne [System.Environment]::MachineName))
		{
			if (!(Initialize-Service "WinRM")) { exit }
		}
	}

	# Modules and git is required only for development and editing scripts
	if ($Develop)
	{
		# Check NET Framework version
		# NOTE: Modules won't load if version isn't met, but scripts a lone may have requirements
		# NOTE: This prerequisite is valid for the PowerShell Desktop edition only
		if ($PowerShellEdition -eq "Desktop")
		{
			Write-Information -Tags "User" -MessageData "INFO: Checking .NET version"

			[version] $TargetNETVersion = Get-NetFramework |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			# Function may fail or no valid version was drilled out of registry
			if (!$TargetNETVersion)
			{
				Write-Error -Category ObjectNotFound -TargetObject $TargetNETVersion `
					-Message "Unable to determine installed .NET version, required .NET Framework is .NET v$($RequireNETVersion.ToString())"
				exit
			}

			if ($TargetNETVersion -lt $RequireNETVersion)
			{
				Write-Error -Category OperationStopped -TargetObject $TargetNETVersion `
					-Message "Minimum required .NET Framework is .NET v$($RequireNETVersion.ToString()) but v$($TargetNETVersion.ToString()) present"
				exit
			}
		}

		Write-Information -Tags "User" -MessageData "INFO: Checking git"

		# Git is recommended for version control and by posh-git module
		# NOTE: Other module scripts require this variable
		Set-Variable -Name GitInstance -Scope Script -Option Constant -Value `
		$(Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue)

		if ($GitInstance)
		{
			[version] $TargetGit = $GitInstance.Version

			if ($TargetGit -lt $RequireGitVersion)
			{
				Write-Warning -Message "Git v$($TargetGit.ToString()) is out of date, recommended is git v$($RequireGitVersion.ToString())"
				Write-Information -Tags "Project" -MessageData "INFO: Please visit https://git-scm.com to download and update"
			}
			else
			{
				Write-Information -Tags "Project" -MessageData "INFO: git.exe v$($TargetGit.ToString()) meets >= v$RequireGitVersion "
			}
		}
		else
		{
			Write-Warning -Message "Git in the PATH minimum v$($RequireGitVersion.ToString()) is recommended but missing"
			Write-Information -Tags "User" -MessageData "INFO: Please verify PATH or visit https://git-scm.com to download and install"
		}
	}

	# NOTE: Value should be set to $Develop
	if (!$NoModulesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking package providers"

		# TODO: "ModuleName" for Nuget here is actually "ProviderName" This is used in Initialize-Provider in
		# same manner as "Repository" with Initialize-Module, needs to be renamed to avoid confusion

		# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
		# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
		if (!(Initialize-Provider -Required @{ ModuleName = "NuGet"; ModuleVersion = $RequireNuGetVersion } `
					-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider")) { exit }

		Write-Information -Tags "User" -MessageData "INFO: Checking modules"

		# NOTE: This is default for Initialize-Module -Repository
		# [string] $Repository = "PSGallery"

		# PowerShellGet >= 2.2.4 is required otherwise updating modules might fail
		# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
		# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
		if (!(Initialize-Module -Required @{ ModuleName = "PowerShellGet"; ModuleVersion = $RequirePowerShellGetVersion } `
					-InfoMessage "PowerShellGet >= $($RequirePowerShellGetVersion.ToString()) is required otherwise updating other modules might fail")) { exit }

		# PackageManagement >= 1.4.7 is required otherwise updating modules might fail
		if (!(Initialize-Module -Required @{ ModuleName = "PackageManagement"; ModuleVersion = $RequirePackageManagementVersion } )) { exit }

		# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing
		if (!(Initialize-Module -Required @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = $RequireAnalyzerVersion } `
					-InfoMessage "PSScriptAnalyzer >= $($RequireAnalyzerVersion.ToString()) is required otherwise code will start missing while editing" )) { exit }

		# Pester is required to run pester tests
		# TODO: see also on how to get rid of duplicate modules https://pester.dev/docs/introduction/installation
		if (!(Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = $RequirePesterVersion } `
					-InfoMessage "Pester >= $($RequirePesterVersion.ToString()) is required to run pester tests" )) { }

		# posh-git >= 1.0.0-beta4 is recommended for better git experience in PowerShell
		if (Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = $RequirePoshGitVersion } -AllowPrerelease `
				-InfoMessage "posh-git >= $($RequirePoshGitVersion.ToString()) is recommended for better git experience in PowerShell" ) { }

		# Update help regardless of module updates
		if ($Develop)
		{
			# User prompt setup
			[int32] $Default = 0
			[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
			$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
			$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")

			$Deny.HelpMessage = "No help files will be updated"
			$Accept.HelpMessage = "Download and install the newest help files on your computer"
			$Choices += $Accept
			$Choices += $Deny

			$Title = "Update help files for PowerShell modules"
			$Question = "Do you want to update help files?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Write-Information -Tags "User" -MessageData "INFO: Checking online for help updates"

				$CultureNames = "en-US"
				[string[]] $UpdatableModules = Find-UpdatableModule -UICulture $CultureNames |
				Select-Object -ExpandProperty Name

				# NOTE: using UICulture en-US, otherwise errors may occur
				$UpdateParams = @{
					ErrorVariable = "UpdateError"
					ErrorAction = "SilentlyContinue"
					UICulture = $CultureNames
					Module = $UpdatableModules
				}

				if ($PowerShellEdition -eq "Core")
				{
					# The -Scope parameter was introduced in PowerShell Core version 6.1
					Update-Help @UpdateParams -Scope AllUsers
				}
				else
				{
					Update-Help @UpdateParams
				}

				# In almost all cases there will be some errors, ignore up to 10 errors
				if ($UpdateError.Count -gt 10)
				{
					$UpdateError
				}
			}
		}
	}

	# TODO: CIM may not always work
	$OSCaption = Get-CimInstance -Class Win32_OperatingSystem |
	Select-Object -ExpandProperty Caption

	# Everything OK, print environment status
	Write-Information -Tags "User" -MessageData "INFO: Checking project minimum requirements was successful"

	Write-Output ""
	Write-Output "System:`t`t $OSCaption v$($TargetOSVersion.ToString())"
	Write-Output "Environment:`t PowerShell $PowerShellEdition v$($TargetPSVersion)"
	Write-Output ""
}

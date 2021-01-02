
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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

using namespace System.Management.Automation.Host

<#
.SYNOPSIS
Check system requirements for this project

.DESCRIPTION
Initialize-Project is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, .NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.

.PARAMETER Abort
If specified exit is called on failure instead of return

.EXAMPLE
PS> Initialize-Project

Performs default requirements and recommendations checks managed by global settings.
Error or warning message is shown if check failed, environment info otherwise.

.EXAMPLE
PS> Initialize-Project -Abort

Performs default requirements and recommendations checks managed by global settings.
Error or warning message is shown if check failed and all subsequent operations are halted.
If successful environment info is shown.

.INPUTS
None. You cannot pipe objects to Initialize-Project

.OUTPUTS
None. Initialize-Project does not generate any output

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: we don't use logs in this module
TODO: checking remote systems not implemented
TODO: Any modules in standard user paths will override system wide modules
TODO: Abort parameter no longer makes sense, -EA Stop would be better, to reproduce problem change
Develop from false to true in clean session
#>
function Initialize-Project
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "There is no way to replace Write-Host here")]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initializenitialize-Project.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Abort
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# disabled when running scripts from SetupFirewall.ps1 script, in which case it runs only once
	if (!$ProjectCheck)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Project initialization skipped"

		if ($Develop -and ($PSVersionTable.PSVersion -ge "7.1"))
		{
			# NOTE: This must be imported to be able to run rules for StoreApps
			Import-WinModule -Name Appx
		}

		return
	}

	# Print watermark
	Write-Host ""
	Write-Host "Windows Firewall Ruleset v$ProjectVersion"
	Write-Host "Copyright (C) 2019-2021 metablaster zebal@protonmail.ch"
	Write-Host "https://github.com/metablaster/WindowsFirewallRuleset"
	Write-Host ""

	Write-Information -Tags "User" -MessageData "INFO: Checking operating system"

	# Check operating system, for possible values see [System.PlatformID]::
	$OSPlatform = [System.Environment]::OSVersion.Platform

	if ($OSPlatform -ne "Win32NT")
	{
		Write-Error -Category OperationStopped -TargetObject $OSPlatform `
			-Message "$OSPlatform platform is not supported, required platform is Win32NT"

		if ($Abort) { exit }
		return
	}

	# Check OS version
	[version] $TargetOSVersion = [System.Environment]::OSVersion.Version

	if ($TargetOSVersion -lt $RequireWindowsVersion)
	{
		[string] $OSMajorMinorBuild = "$($TargetOSVersion.Major).$($TargetOSVersion.Minor).$($TargetOSVersion.Build)"
		Write-Error -Category NotImplemented -TargetObject $TargetOSVersion `
			-Message "Minimum supported operating system is 'Windows v$RequireWindowsVersion' but 'Windows v$OSMajorMinorBuild present"

		if ($Abort) { exit }
		return
	}

	# Check if in elevated PowerShell
	Write-Information -Tags "User" -MessageData "INFO: Checking user account elevation"
	$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

	if (!$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Error -Category PermissionDenied -TargetObject $Principal `
			-Message "Elevation required, please open PowerShell as Administrator and try again"

		if ($Abort) { exit }
		return
	}

	# Check OS is not Home edition
	# NOTE: Get-WindowsEdition requires elevation
	Write-Information -Tags "User" -MessageData "INFO: Checking OS edition"
	$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

	# TODO: instead of comparing string we should probably compare numbers
	if ($OSEdition -like "*Home*")
	{
		Write-Error -Category OperationStopped -TargetObject $OSEdition `
			-Message "Windows $OSEdition doesn't have Local Group Policy required by this project"

		if ($Abort) { exit }
		return
	}

	# Check OS build version, the sole purpose is to write warning for out of date systems,
	# because of firewall rule updates that reflect lastest OS build
	if ($TargetOSVersion.Build -lt $RequireWindowsVersion.Build)
	{
		$TargetOSBuildVersion = ConvertFrom-OSBuild $TargetOSVersion.Build
		$RequireOSBuildVersion = ConvertFrom-OSBuild $RequireWindowsVersion.Build

		Write-Warning -Message "Target system version is v$TargetOSBuildVersion, to reduce issues with firewall rules please upgrade to at least v$RequireOSBuildVersion"
	}

	# Check PowerShell edition
	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell edition"
	$PowerShellEdition = $PSVersionTable.PSEdition

	# Check PowerShell version
	[version] $TargetPSVersion = $PSVersionTable.PSVersion
	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell version"

	if ($TargetPSVersion -lt $RequirePSVersion)
	{
		Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
			-Message "Required PowerShell $PowerShellEdition is v$RequirePSVersion but v$TargetPSVersion present"

		if ($Abort) { exit }
		return
	}

	if ($ServicesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking system services"

		# These services are minimum required
		$RequiredServices = @(
			"lmhosts" # TCP/IP NetBIOS Helper
			"LanmanWorkstation" # Workstation
			"LanmanServer" # Server
			# NOTE: WinRM required for:
			# 1. Remote firewall administration, see Enable-PSRemoting cmdlet, or when localhost is specified instad of NETBIOS name
			# 2. For PowerShell Core 7.1+ this service is required for compatibility module
			# 3. Required for CIM functions
			"WinRM" # Windows Remote Management (WS-Management)
		)

		if (!(Initialize-Service $RequiredServices))
		{
			if ($Abort) { exit }
			return
		}
	}

	# If PolicyStore variable doesn't point to localhost, but the project is not yet ready for remote administration
	if (Get-Variable -Scope Global -Name RemoteCredential -ErrorAction Ignore)
	{
		Write-Warning -Message "Remote firewall administration is not implemented"

		try
		{
			Write-Information -Tags "Project" -MessageData "Testing Windows remote management service on computer: '$PolicyStore'"
			# TODO: https://stackoverflow.com/questions/18284132/winrm-cannot-process-the-request-fails-only-over-a-specific-domain
			Test-WSMan -ComputerName $PolicyStore -Credential $RemoteCredential
		}
		catch
		{
			Write-Error -TargetObject $_.TargetObject -Category $_.CategoryInfo.Category `
				-Message "Remote management test to computer '$PolicyStore' failed with: $($_.Exception.Message)"
			exit
		}
	}

	if ($TargetPSVersion -ge "7.1")
	{
		# Since PowerShell Core 7.1 Using Appx no longer works, so we use a compatibility module
		# https://github.com/PowerShell/PowerShell/issues/13138
		# TODO: Future versions of PS Core will support more "Desktop" edition modules,
		# check to use compatibility only as needed
		# TODO: Implement Scope parameter
		Import-WinModule -Name Appx
	}

	if ($Develop)
	{
		# Check NET Framework version
		# NOTE: Project modules won't load if version isn't met, scripts a lone may have requirements too
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
					-Message "Unable to determine installed .NET version, required .NET Framework is .NET v$RequireNETVersion"

				if ($Abort) { exit }
				return
			}

			if ($TargetNETVersion -lt $RequireNETVersion)
			{
				Write-Error -Category OperationStopped -TargetObject $TargetNETVersion `
					-Message "Minimum required .NET Framework is .NET v$RequireNETVersion but v$TargetNETVersion present"
				Write-Information -Tags "Project" -MessageData "INFO: Please visit https://dotnet.microsoft.com/download/dotnet-framework to download and install"

				if ($Abort) { exit }
				return
			}
		}

		[System.Management.Automation.ApplicationInfo] $VSCode = Get-Command code.cmd -CommandType Application -ErrorAction SilentlyContinue

		if ($null -ne $VSCode)
		{
			[version] $TargetVSCode = (code --version)[0]

			if ($TargetVSCode -lt $RequireVSCodeVersion)
			{
				Write-Warning -Message "VSCode v$TargetVSCode is out of date, recommended VSCode v$RequireVSCodeVersion)"
			}
			else
			{
				Write-Information -Tags "Project" -MessageData "INFO: VSCode v$TargetVSCode meets >= v$RequireVSCodeVersion "
			}
		}
		else
		{
			Write-Warning -Message "VSCode in the PATH minimum v$RequireVSCodeVersion is recommended but missing"
			Write-Information -Tags "User" -MessageData "INFO: Please verify PATH or visit https://code.visualstudio.com to download and install"
		}
	}

	# Modules and git is required only for development and editing scripts
	if ($ModulesCheck -or $Develop)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking git"

		# Git is recommended for version control and by posh-git module
		# NOTE: Other module scripts require this variable
		# NOTE: Using ReadOnly option instead of Constant to be able to run Initialize-Project from command line multiple times
		Set-Variable -Name GitInstance -Scope Script -Option ReadOnly -Force -Value `
		(Get-Command -Name git.exe -CommandType Application -ErrorAction SilentlyContinue)

		if ($null -ne $GitInstance)
		{
			[version] $TargetGit = $GitInstance.Version

			if ($TargetGit -lt $RequireGitVersion)
			{
				Write-Warning -Message "Git v$TargetGit is out of date, recommended is git v$RequireGitVersion"
				Write-Information -Tags "Project" -MessageData "INFO: Please visit https://git-scm.com to download and update"
			}
			else
			{
				Write-Information -Tags "Project" -MessageData "INFO: git v$TargetGit meets >= v$RequireGitVersion"
			}
		}
		else
		{
			Write-Warning -Message "Git in the PATH minimum v$RequireGitVersion is recommended but missing"
			Write-Information -Tags "User" -MessageData "INFO: Please verify PATH or visit https://git-scm.com to download and install"
		}
	}

	# NOTE: Result value should be equivalent to $Develop
	if ($ModulesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking package providers"

		# Check if PowerShell needs to restart
		Set-Variable -Name Restart -Scope Script -Value $false

		# TODO: "ModuleName" for Nuget here is actually "ProviderName" This is used in Initialize-Provider in
		# same manner as "Repository" with Initialize-Module, needs to be renamed to avoid confusion

		# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
		# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
		if (!(Initialize-Provider -Required @{ ModuleName = "NuGet"; ModuleVersion = $RequireNuGetVersion } `
					-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider"))
		{
			if ($Abort) { exit }
			return
		}

		Write-Information -Tags "User" -MessageData "INFO: Checking modules"

		# NOTE: This is default for Initialize-Module -Repository
		# [string] $Repository = "PSGallery"

		# PowerShellGet is required otherwise updating modules might fail
		# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
		# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
		if (!(Initialize-Module -Required @{ ModuleName = "PowerShellGet"; ModuleVersion = $RequirePowerShellGetVersion } `
					-InfoMessage "PowerShellGet >= v$RequirePowerShellGetVersion is required otherwise updating other modules might fail"))
		{
			if ($Abort) { exit }
			return
		}

		# PackageManagement is required otherwise updating modules might fail, will be installed by PowerShellGet
		if (!(Initialize-Module -Required @{ ModuleName = "PackageManagement"; ModuleVersion = $RequirePackageManagementVersion } ))
		{
			if ($Abort) { exit }
			return
		}

		if ($script:Restart)
		{
			# NOTE: at this point PowerShell should be restarted to avoid errors
			# installing pester fails with signature, posh-git fails with -AllowPrerelease parameter
			Write-Warning -Message "Please restart PowerShell for changes to take effect"
			exit
		}

		# Pester is required to run pester tests, required by PSScriptAnalyzer
		if (!(Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = $RequirePesterVersion } `
					-InfoMessage "Pester >= v$RequirePesterVersion is required to run pester tests" )) { }

		# PSScriptAnalyzer is required for code formattings and analysis
		if (!(Initialize-Module -Required @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = $RequireAnalyzerVersion } `
					-InfoMessage "PSScriptAnalyzer >= v$RequireAnalyzerVersion is required otherwise code will start missing while editing" ))
		{
			if ($Abort) { exit }
			return
		}

		# posh-git is recommended for better git experience in PowerShell
		if (Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = $RequirePoshGitVersion } -AllowPrerelease `
				-InfoMessage "posh-git >= v$RequirePoshGitVersion is recommended for better git experience in PowerShell" ) { }

		if (Initialize-Module @{ ModuleName = "PSReadLine"; ModuleVersion = $RequirePSReadlineVersion } `
				-InfoMessage "PSReadLine >= v$RequirePSReadlineVersion is recommended for command line editing experience of PowerShell" ) { }

		if (Initialize-Module @{ ModuleName = "platyPS"; ModuleVersion = $RequirePlatyPSVersion } `
				-InfoMessage "platyPS >= v$RequirePlatyPSVersion is recommended to generate online help files for modules" ) { }

		# Update help regardless of module updates
		if ($Develop)
		{
			# User prompt setup
			[int32] $Default = 1
			[ChoiceDescription[]] $Choices = @()
			$Accept = [ChoiceDescription]::new("&Yes")
			$Deny = [ChoiceDescription]::new("&No")

			$Deny.HelpMessage = "No help files will be updated"
			$Accept.HelpMessage = "Download and install the newest help files on your computer"
			$Choices += $Accept
			$Choices += $Deny

			$Title = "Update help files for PowerShell modules"
			$Question = "Do you want to update help files?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -ne $Default)
			{
				Write-Information -Tags "User" -MessageData "INFO: Please wait, checking online for help updates..."

				$CultureNames = "en-US"

				# NOTE: using UICulture en-US, otherwise errors may occur
				$UpdateParams = @{
					ErrorVariable = "UpdateError"
					ErrorAction = "SilentlyContinue"
					UICulture = $CultureNames
				}

				[string[]] $UpdatableModules = Find-UpdatableModule -UICulture $CultureNames |
				Select-Object -ExpandProperty Name

				if (!$UpdatableModules)
				{
					# HACK: UpdatableModules may be null, failed on Enterprise edition with 0 found
					# helpinfo files.
					# Even after updating modules and manually running Update-Help which btw. succeeded!
					Write-Warning -Message "No modules contain HelpInfo files required to update help"

					# Otherwise the cause may because Update-Help was never run which is required to
					# download helpinfo.xml files
					Update-Help @UpdateParams
				}
				else
				{
					$UpdateParams["Module"] = $UpdatableModules

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
	}
	else
	{
		Write-Warning -Message "3rd party modules may be missing or outdated which could result in unexpected behavior"
		Write-Information -Tags "Project" -MessageData "INFO: This can be automated by enabling 'ModulesCheck' variable in Config\ProjectSettings.ps1"
	}

	# TODO: CIM may not always work
	$OSCaption = Get-CimInstance -Class Win32_OperatingSystem -ComputerName $PolicyStore `
		-OperationTimeoutSec $ConnectionTimeout -Namespace "root\cimv2" |
	Select-Object -ExpandProperty Caption

	$OSBuildVersion = ConvertFrom-OSBuild $TargetOSVersion.Build

	# Everything OK, print environment status
	# TODO: finally show loaded modules, providers and services stataus
	Write-Host ""
	# HACK: We don't know if it was successful, need to record errors and/or warnings
	Write-Host "Checking project minimum requirements was successful!" -ForegroundColor Cyan

	Write-Host ""
	# NOTE: No 'v' prefix because of possible "Insider" string
	Write-Host "System:`t`t $OSCaption $OSBuildVersion"
	Write-Host "Environment:`t PowerShell $PowerShellEdition $TargetPSVersion"
	Write-Host ""
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Check repository environment requirements

.DESCRIPTION
Initialize-Project is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, .NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.

.EXAMPLE
PS> Initialize-Project

.INPUTS
None. You cannot pipe objects to Initialize-Project

.OUTPUTS
None. Initialize-Project does not generate any output

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: We don't use logs in this module
TODO: checking remote systems not implemented
TODO: Any modules in standard user paths will override system wide modules
TODO: Changes done to system services should be reverted to original values, new function needed
TODO: code.exe --list-extensions and verify extensions installed
#>
function Initialize-Project
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Project.md")]
	[OutputType([string], [void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# We need "Stop" since this function when run on it's own may close the console if exit is used
	$ErrorActionPreference = "Stop"

	if ($PSCmdlet.ShouldProcess("System", "Check minimum requirements"))
	{
		# Disabled when running scripts from Deploy-Firewall.ps1 script, in which case it runs only once
		if (!$ProjectCheck)
		{
			Initialize-Connection
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Project initialization skipped"
			return
		}

		# Print watermark
		Write-ColorMessage
		Write-ColorMessage "Windows Firewall Ruleset v$ProjectVersion" Cyan
		Write-ColorMessage "Copyright (C) 2019-2022 metablaster zebal@protonmail.ch" Cyan
		Write-ColorMessage "https://github.com/metablaster/WindowsFirewallRuleset" Cyan
		Write-ColorMessage

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking operating system"

		# Check operating system, for possible values see [System.PlatformID]::
		$OSPlatform = [System.Environment]::OSVersion.Platform

		if ($OSPlatform -ne "Win32NT")
		{
			Write-Error -Category OperationStopped -TargetObject $OSPlatform `
				-Message "$OSPlatform platform is not supported, required platform is Win32NT"
			return
		}

		# Check OS version
		[version] $TargetOSVersion = [System.Environment]::OSVersion.Version

		if ($TargetOSVersion -lt $RequireWindowsVersion)
		{
			[string] $OSMajorMinorBuild = "$($TargetOSVersion.Major).$($TargetOSVersion.Minor).$($TargetOSVersion.Build)"
			Write-Error -Category NotImplemented -TargetObject $TargetOSVersion `
				-Message "Minimum supported operating system is 'Windows v$RequireWindowsVersion' but 'Windows v$OSMajorMinorBuild present"
			return
		}

		# Check if in elevated PowerShell
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking user account elevation"
		$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

		if (!$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
		{
			Write-Error -Category PermissionDenied -TargetObject $Principal `
				-Message "Elevation required, please open PowerShell as Administrator and try again"
			return
		}

		# Check OS is not Home edition
		# NOTE: Get-WindowsEdition requires elevation
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking OS edition"
		$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

		# TODO: instead of comparing string we should probably compare numbers
		if ($OSEdition -like "*Home*")
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Windows $OSEdition doesn't have Local Group Policy required by this project"
			return
		}

		# Check OS build version, the sole purpose is to write warning for out of date systems,
		# because of firewall rule updates that reflect lastest OS build
		if ($TargetOSVersion.Build -lt $RequireWindowsVersion.Build)
		{
			$TargetOSBuildVersion = ConvertFrom-OSBuild $TargetOSVersion.Build
			$RequireOSBuildVersion = ConvertFrom-OSBuild $RequireWindowsVersion.Build

			Write-Warning -Message "[$($MyInvocation.InvocationName)] Target system version is v$TargetOSBuildVersion, to reduce issues with firewall rules please upgrade to at least v$RequireOSBuildVersion"
		}

		# Check PowerShell edition
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking PowerShell edition"
		$PowerShellEdition = $PSVersionTable.PSEdition

		# Check PowerShell version
		[version] $TargetPSVersion = $PSVersionTable.PSVersion
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking PowerShell version"

		if ($TargetPSVersion -lt $RequirePSVersion)
		{
			Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
				-Message "Required PowerShell $PowerShellEdition is v$RequirePSVersion but v$TargetPSVersion present"
			return
		}

		if ($ServicesCheck)
		{
			# TODO: Optionally set services to automatic startup, most of services are needed only to run code.
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking system services"

			# These services are minimum required
			$AutomaticServices = @(
				"lmhosts" # TCP/IP NetBIOS Helper
				"LanmanWorkstation" # Workstation
				"LanmanServer" # Server
				"fdPHost" # Function Discovery Provider host
				"FDResPub" # Function Discovery Resource Publication (depends on fdPHost)
				# WinRM required for:
				# 1. Remote firewall administration, see Enable-PSRemoting cmdlet, or when localhost is specified instad of NETBIOS name
				# 2. For PowerShell Core 7.1+ this service is required for compatibility module
				# 3. Required for CIM functions by both local and remote machine
				"WinRM" # Windows Remote Management (WS-Management)
			)

			# RemoteRegistry is required by both client and server for OpenRemoteBaseKey to work
			# It may be also required for localhost deployment
			$ManualServices = "RemoteRegistry"

			if (!(Initialize-Service $ManualServices -Status Stopped -StartupType "Manual"))
			{
				return
			}

			if ($Develop)
			{
				$AutomaticServices += @(
					# ssh-agent recommended for:
					# 1. Remote SSH in VSCode
					# 2. git over SSH
					"ssh-agent" # OpenSSH Authentication Agent
					# sshd recommended to host SSH and VSCode server
					"sshd" # OpenSSH SSH Server
				)
			}

			if (!(Initialize-Service $AutomaticServices))
			{
				return
			}
		}

		if ($Develop)
		{
			Initialize-Connection

			# Check NET Framework version
			# NOTE: Project modules won't load if version isn't met, scripts a lone may have requirements too
			# NOTE: This prerequisite is valid for the PowerShell Desktop edition only
			if ($PowerShellEdition -eq "Desktop")
			{
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking .NET version"

				[version] $TargetNETVersion = Get-NetFramework |
				Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

				# Function may fail or no valid version was drilled out of registry
				if (!$TargetNETVersion)
				{
					Write-Error -Category ObjectNotFound -TargetObject $TargetNETVersion `
						-Message "Unable to determine installed .NET version, required .NET Framework is .NET v$RequireNETVersion"
					return
				}

				if ($TargetNETVersion -lt $RequireNETVersion)
				{
					Write-Error -Category OperationStopped -TargetObject $TargetNETVersion -ErrorAction SilentlyContinue `
						-Message "Minimum required .NET Framework is .NET v$RequireNETVersion but v$TargetNETVersion present"
					Write-Information -Tags $MyInvocation.InvocationName `
						-MessageData "INFO: Please visit https://dotnet.microsoft.com/download/dotnet-framework to download and install"
					return
				}
			}

			# [System.Management.Automation.ApplicationInfo]
			$VSCode = Get-Command code.cmd -CommandType Application -ErrorAction SilentlyContinue

			if ($null -ne $VSCode)
			{
				[version] $TargetVSCode = (code --version)[0]

				if ($TargetVSCode -lt $RequireVSCodeVersion)
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] VSCode v$TargetVSCode is out of date, recommended VSCode v$RequireVSCodeVersion"
				}
				else
				{
					Write-Information -Tags $MyInvocation.InvocationName `
						-MessageData "INFO: VSCode v$TargetVSCode meets >= v$RequireVSCodeVersion "
				}
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] VSCode in the PATH minimum v$RequireVSCodeVersion is recommended but missing"
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Please verify PATH or visit https://code.visualstudio.com to download and install"
			}
		}

		# Modules and git is required only for development and editing scripts
		if ($ModulesCheck -or $Develop)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking git"

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
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Git v$TargetGit is out of date, recommended is git v$RequireGitVersion"
					Write-Information -Tags $MyInvocation.InvocationName `
						-MessageData "INFO: Please visit https://git-scm.com to download and update"
				}
				else
				{
					Write-Information -Tags $MyInvocation.InvocationName `
						-MessageData "INFO: git v$TargetGit meets >= v$RequireGitVersion"
				}
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Git in the PATH minimum v$RequireGitVersion is recommended but missing"
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Please verify PATH or visit https://git-scm.com to download and install"
			}
		}

		# NOTE: Result value should be equivalent to $Develop
		if ($ModulesCheck)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking package providers"

			# Check if PowerShell needs to restart
			Set-Variable -Name Restart -Scope Script -Value $false

			# TODO: "ModuleName" for Nuget here is actually "ProviderName" This is used in Initialize-Provider in
			# same manner as "Repository" with Initialize-Module, needs to be renamed to avoid confusion

			# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
			# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
			if (!(Initialize-Provider -Required -ProviderName "NuGet" -RequiredVersion $RequireNuGetVersion `
						-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider"))
			{
				return
			}

			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking modules"

			# NOTE: This is default for Initialize-Module -Repository
			# [string] $Repository = "PSGallery"

			# PowerShellGet is required otherwise updating modules might fail
			# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
			# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
			if (!(Initialize-Module -Required @{ ModuleName = "PowerShellGet"; ModuleVersion = $RequirePowerShellGetVersion } `
						-InfoMessage "PowerShellGet >= v$RequirePowerShellGetVersion is required otherwise updating other modules might fail"))
			{
				return
			}

			# PackageManagement is required otherwise updating modules might fail, will be installed by PowerShellGet
			if (!(Initialize-Module -Required @{ ModuleName = "PackageManagement"; ModuleVersion = $RequirePackageManagementVersion } ))
			{
				return
			}

			if ($script:Restart)
			{
				# NOTE: at this point PowerShell should be restarted to avoid errors
				# installing pester fails with signature, posh-git fails with -AllowPrerelease parameter
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Please restart PowerShell for changes to take effect and run last command again"
				Read-Host "Press enter to exit"
				exit
			}

			# Pester is required to run pester tests, required by PSScriptAnalyzer
			if (!(Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = $RequirePesterVersion } `
						-InfoMessage "Pester >= v$RequirePesterVersion is required to run pester tests" )) { }

			# PSScriptAnalyzer is required for code formattings and analysis
			if (!(Initialize-Module -Required @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = $RequireAnalyzerVersion } `
						-InfoMessage "PSScriptAnalyzer >= v$RequireAnalyzerVersion is required otherwise the code might disappear while editing" ))
			{
				return
			}

			# posh-git is recommended for better git experience in PowerShell
			if (Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = $RequirePoshGitVersion } -AllowPrerelease `
					-InfoMessage "posh-git >= v$RequirePoshGitVersion is recommended for better git experience in PowerShell" ) { }

			if (Initialize-Module @{ ModuleName = "PSReadLine"; ModuleVersion = $RequirePSReadlineVersion } `
					-InfoMessage "PSReadLine >= v$RequirePSReadlineVersion is recommended for command line editing experience in PowerShell" ) { }

			if (Initialize-Module @{ ModuleName = "platyPS"; ModuleVersion = $RequirePlatyPSVersion } `
					-InfoMessage "platyPS >= v$RequirePlatyPSVersion is recommended to generate online help files for modules" ) { }

			if ($Develop)
			{
				# Exclude possibility of using outdated modules by removing them
				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Checking for existence of module duplication"

				Uninstall-DuplicateModule
			}
		}
		else
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] 3rd party modules may be missing or outdated which some non essential scripts require"
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: This can be resolved by enabling 'ModulesCheck' variable in Config\ProjectSettings.ps1"
		}

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
				Update-ModuleHelp
			}
		}

		# Otherwise this was performed before .NET checking
		if (!$Develop)
		{
			Initialize-Connection
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Detecting OS on computer '$PolicyStore'"
		$OSCaption = Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
			-Class Win32_OperatingSystem -Property Caption | Select-Object -ExpandProperty Caption

		if ([string]::IsNullOrEmpty($OSCaption))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to determine OS on computer '$PolicyStore'"
			$OSCaption = "Windows"
		}

		$OSBuildVersion = ConvertFrom-OSBuild $TargetOSVersion.Build

		# Everything OK, print environment status
		# TODO: finally show loaded modules, providers and services stataus
		Write-ColorMessage
		Write-ColorMessage "Checking system requirements completed successfully" Cyan

		Write-ColorMessage
		# TODO: This should include both, server and client system
		# NOTE: No 'v' prefix because of possible "Insider" string
		Write-ColorMessage "System:`t`t $OSCaption $OSBuildVersion" Cyan
		Write-ColorMessage "Environment:`t PowerShell $PowerShellEdition $TargetPSVersion" Cyan
		Write-ColorMessage
	} # if ShouldProcess
}

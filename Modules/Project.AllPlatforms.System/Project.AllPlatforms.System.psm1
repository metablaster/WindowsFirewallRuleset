
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}
else
{
	# Everything is default except InformationPreference should be enabled
	$InformationPreference = "Continue"
}

<#
.SYNOPSIS
Test and print system requirements required for this project
.DESCRIPTION
Test-SystemRequirements is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.
.PARAMETER Check
true or false to check or not to check
note that this parameter is managed by project settings
.EXAMPLE
Test-SystemRequirements $true
.INPUTS
None. You cannot pipe objects to Test-SystemRequirements
.OUTPUTS
None. Error or warning message is shown if check failed, system info otherwise.
.NOTES
TODO: learn required NET version by scanning scripts (ie. adding .COMPONENT to comments)
TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
TODO: remote check not implemented
#>
function Test-SystemRequirements
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = "There is no better name")]
	[OutputType([System.Void])]
	param (
		[Parameter(Mandatory = $false)]
		[bool] $Check = $SystemCheck
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# disabled when running scripts from SetupFirewall.ps1 script
	if (!$Check)
	{
		return
	}

	# print info
	Write-Output ""
	Write-Output "Windows Firewall Ruleset v$($ProjectVersion.ToString())"
	Write-Output "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"
	Write-Output "https://github.com/metablaster/WindowsFirewallRuleset"
	Write-Output ""

	# Check operating system
	$OSPlatform = [System.Environment]::OSVersion.Platform
	[System.Version] $TargetOSVersion = [System.Environment]::OSVersion.Version
	[System.Version] $RequiredOSVersion = "10.0"

	if (!(($OSPlatform -eq "Win32NT") -and ($TargetOSVersion -ge $RequiredOSVersion)))
	{
		Write-Error -Category OperationStopped -TargetObject $TargetOSVersion `
			-Message "Unable to proceed, minimum required operating system is 'Win32NT $($RequiredOSVersion.ToString())' to run these scripts"

		Write-Information -Tags "Project" -MessageData "INFO: Your operating system is: '$OSPlatform $($TargetOSVersion.ToString())'"
		exit
	}

	# Check if in elevated PowerShell
	$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

	if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Error -Category PermissionDenied -TargetObject $Principal `
			-Message "Unable to proceed, please open PowerShell as Administrator"
		exit
	}

	# Check OS is not Home edition
	$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

	# TODO: We need SKU function here
	if ($OSEdition -like "*Home*")
	{
		Write-Error -Category OperationStopped -TargetObject $OSEdition `
			-Message "Unable to proceed, home editions of Windows do not have Local Group Policy"
		exit
	}

	# Check PowerShell edition
	$PowerShellEdition = $PSVersionTable.PSEdition

	if ($PowerShellEdition -eq "Core")
	{
		Write-Warning -Message "Project with 'Core' edition of PowerShell does not yet support remote administration"
		Write-Information -Tags "Project" -MessageData "INFO: Your PowerShell edition is: $PowerShellEdition"
	}

	# Check PowerShell version
	[System.Version] $RequiredPSVersion = "5.1.0"
	[System.Version] $TargetPSVersion = $PSVersionTable.PSVersion

	if ($TargetPSVersion -lt $RequiredPSVersion)
	{
		Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
			-Message "Unable to proceed, minimum required PowerShell required to run these scripts is: Desktop $($RequiredPSVersion.ToString())"

		Write-Information -Tags "Project" -MessageData "INFO: Your PowerShell version is: $($TargetPSVersion.ToString())"
		exit
	}

	# Check NET Framework version
	# NOTE: this check is not required unless in some special cases
	if ($Develop -and ($PowerShellEdition -eq "Desktop"))
	{
		# Now that OS and PowerShell is OK we can use these functions
		# TODO: What if function fails?
		$NETFramework = Get-NetFramework
		[System.Version] $TargetNETVersion = $NETFramework |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		[System.Version] $RequiredNETVersion = "3.5.0"

		if ($TargetNETVersion -lt $RequiredNETVersion)
		{
			Write-Error -Category OperationStopped -TargetObject $TargetNETVersion `
				-Message "Unable to proceed, minimum required NET Framework version to run these scripts is: $($RequiredNETVersion.ToString())"
			Write-Information -Tags "Project" -MessageData "INFO: Your NET Framework version is: $($TargetNETVersion.ToString())"
			exit
		}
	}

	[string] $Title = "Required service not running"
	[string[]] $Choices = "&Yes", "&No"
	[int32] $Default = 0
	[bool] $StatusGood = $true
	$RequiredServices = Get-Service -Name lmhosts, LanmanWorkstation, LanmanServer

	foreach ($Service in $RequiredServices)
	{
		if ($Service.Status -ne "Running")
		{
			[string] $Question = "Do you want to start '$($Service.DisplayName)' now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				$Dependencies = Get-Service -Name $Service.Name -DependentServices
				foreach ($DependentService in $Dependencies)
				{
					if ($DependentService.Status -ne "Running")
					{
						Start-Service -Name $DependentService.Name
						$Status = Get-Service -Name $DependentService.Name | Select-Object -ExpandProperty Status

						if ($Status -ne "Running")
						{
							Write-Error -Category OperationStopped -TargetObject $DependentService `
								-Message "Unable to proceed, Dependent services can't be started"
							Write-Information -Tags "User" -MessageData "INFO: Starting dependent service '$($DependentService.DisplayName)' failed, please start manually and try again"
							exit
						}
					}
				}

				# Dependencies are meet, start required service
				Start-Service -Name $Service.Name
				$Status = Get-Service -Name $Service.Name | Select-Object -ExpandProperty Status

				if ($Status -ne "Running")
				{
					$StatusGood = $false
					Write-Information -Tags "User" -MessageData "INFO: Starting $($Service.DisplayName) failed, please start manually and try again"
				}
			}
			else
			{
				# User refused default action
				$StatusGood = $false
			}

			if (!$StatusGood)
			{
				Write-Error -Category OperationStopped -TargetObject $Service `
					-Message "Unable to proceed, required services are not started"
				exit
			}
		}
	}

	# NOTE: remote administration needs this service, see Enable-PSRemoting cmdlet
	$WinRM = Get-Service -Name WinRM

	# NOTE: some tests depend on this service, project not ready for remoting
	if ($develop -and ($PolicyStore -ne [System.Environment]::MachineName) -and ($WinRM.Status -ne "Running"))
	{
		$Question = "$($WinRM.DisplayName) service is required for remote administration and testing but not started"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			$Dependencies = Get-Service -Name $WinRM.Name -DependentServices
			foreach ($DependentService in $Dependencies)
			{
				if ($DependentService.Status -ne "Running")
				{
					Start-Service -Name $DependentService.Name
					$Status = Get-Service -Name $DependentService.Name | Select-Object -ExpandProperty Status

					if ($Status -ne "Running")
					{
						Write-Error -Category OperationStopped -TargetObject $DependentService `
							-Message "Unable to proceed, Dependent services can't be started"
						Write-Information -Tags "User" -MessageData "INFO: Starting dependent service '$($DependentService.DisplayName)' failed, please start manually and try again"
						exit
					}
				}
			}

			# Dependencies are meet, start required service
			Start-Service -Name WinRM
			$WinRM = Get-Service -Name WinRM

			if ($WinRM.Status -ne "Running")
			{
				$StatusGood = $false
				Write-Output "$($WinRM.DisplayName) service can not be started, please start it manually and try again"
			}
		}
		else
		{
			$StatusGood = $false
		}

		if (!$StatusGood)
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, required service is not started"

			Write-Information -Tags "Project" -MessageData "INFO: $($WinRM.DisplayName) service is required but not started"
			exit
		}
	}

	# Git is recommended for version control
	[string] $RequiredGit = "2.28.0"
	$GitInstance = Get-Command git.exe -CommandType Application -ErrorAction Ignore

	if ($GitInstance)
	{
		[System.Version] $TargetGit = $GitInstance.Version

		if ($TargetGit -lt $RequiredGit)
		{
			Write-Warning -Message "Git version $($TargetGit.ToString()) is out of date, recommended version is: $RequiredGit"
			Write-Information -Tags "Project" -MessageData "INFO: Please visit https://git-scm.com to download and update"
		}
	}
	else
	{
		Write-Warning -Message "Git in the PATH minimum version $($RequiredGit.ToString()) is recommended but missing"
		Write-Information -Tags "User" -MessageData "INFO: Please verify PATH or visit https://git-scm.com to download and install"
	}

	[string] $TitleSuffix = ""

	if (!(Test-NetConnection "nuget.org" -CommonTCPPort HTTP -ErrorAction Ignore))
	{
		$TitleSuffix = " but no connection to nuget.org"
	}

	# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
	# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
	[string] $RequiredVersion = "3.0.0"
	$ProviderName = "NuGet"
	[System.Version] $TargetVersion = Get-PackageProvider -Name NuGet |
	Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

	if (!$TargetVersion)
	{
		Write-Warning -Message "Package provider '$ProviderName' not installed"
	}
	elseif ($TargetVersion -lt $RequiredVersion)
	{
		Write-Warning -Message "$ProviderName provider version '$($TargetVersion.ToString())' is out of date, recommended version is: $RequiredVersion"

		$Title = "Recommended package provider is out of date$TitleSuffix"
		$Question = "Update '$ProviderName' provider now?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			$SoftwareIdentity = Find-PackageProvider -Name "Nuget" -IncludeDependencies

			if ($SoftwareIdentity)
			{
				Install-PackageProvider $SoftwareIdentity

				[System.Version] $NewVersion = Get-PackageProvider -Name NuGet |
				Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

				if ($NewVersion -gt $TargetVersion)
				{
					Write-Information -Tags "User" -MessageData "INFO: $ProviderName status changed, PowerShell must be restarted"
					exit
				}
				# else error should be shown
			}
			else
			{
				Write-Warning -Message "$ProviderName not found to update"
			}
		}
		else
		{
			Write-Warning -Message "$ProviderName not installed"
		}
	}

	$TitleSuffix = ""
	if (!(Test-NetConnection "powershellgallery.com" -CommonTCPPort HTTP -ErrorAction Ignore))
	{
		$TitleSuffix = " but no connection to powershellgallery.com"
	}

	# PowerShellGet >= 2.2.4 is required otherwise updating modules might fail
	# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
	$RequiredVersion = "2.2.4"
	$ModuleName = "PowerShellGet"
	[System.Collections.Hashtable] $ModuleFullName = @{ ModuleName = "$ModuleName"; ModuleVersion = "$RequiredVersion" }
	if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
	{
		[System.Version] $TargetVersion = Get-Module -Name $ModuleName -ListAvailable |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

		if ($TargetVersion)
		{
			Write-Warning -Message "$ModuleName module version '$($TargetVersion.ToString())' is out of date, recommended version is: $RequiredVersion"

			$Title = "Recommended module out of date$TitleSuffix"
			$Question = "Update '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				# In PowerShellGet versions 2.0.0 and above, the default is CurrentUser, which does not require elevation for install.
				# In PowerShellGet 1.x versions, the default is AllUsers, which requires elevation for install.
				# NOTE: for version 1.0.1 -Scope parameter is not recognized, we'll skip it for very old version
				if (Get-InstalledModule -Name $ModuleName -ErrorAction Ignore)
				{
					if ($TargetVersion -gt "2.0.0")
					{
						PowerShellGet\Update-Module -Name $ModuleName -Scope AllUsers
					}
					else
					{
						PowerShellGet\Update-Module -Name $ModuleName
					}
				}
				else
				{
					# Need force to install side by side, update not possible
					if ($TargetVersion -gt "2.0.0")
					{
						PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -Force
					}
					else
					{
						PowerShellGet\Install-Module -Name $ModuleName -Force
					}
				}
			}
		}
		else
		{
			Write-Warning -Message "$ModuleName module minimum version $RequiredVersion is required for best editing experience but not installed"

			$Title = "Recommended module not installed$TitleSuffix"
			$Question = "Install '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				if ($TargetVersion -gt "2.0.0")
				{
					PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -MinimumVersion $RequiredVersion
				}
				else
				{
					PowerShellGet\Install-Module -Name $ModuleName -MinimumVersion $RequiredVersion
				}
			}
		}

		# Check if installation was success
		[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $AnalyzerModule -ListAvailable
		if ($ModuleStatus)
		{
			Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell must be restarted"
			exit
		}
		{
			Write-Error -Category OperationStopped -TargetObject $ModuleStatus `
				-Message "$ModuleName module not installed"
			exit
		}
	}

	# PackageManagement >= 1.4.7 is required otherwise updating modules might fail
	[string] $RequiredVersion = "1.4.7"
	$ModuleName = "PackageManagement"
	[System.Collections.Hashtable] $ModuleFullName = @{ ModuleName = "$ModuleName"; ModuleVersion = "$RequiredVersion" }
	if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
	{
		[System.Version] $TargetVersion = Get-Module -Name $ModuleName -ListAvailable |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

		if ($TargetVersion)
		{
			Write-Warning -Message "$ModuleName module version '$($TargetVersion.ToString())' is out of date, recommended version is: $RequiredVersion"

			$Title = "Recommended module out of date$TitleSuffix"
			$Question = "Update '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Update-Module -Name $ModuleName -Scope AllUsers
			}
		}
		else
		{
			Write-Warning -Message "$ModuleName module minimum version $RequiredVersion is required for best editing experience but not installed"

			$Title = "Recommended module not installed$TitleSuffix"
			$Question = "Install '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -MinimumVersion $RequiredVersion
			}
		}

		# Check if installation was success
		[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable
		if ($ModuleStatus)
		{
			Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell must be restarted"
			exit
		}
		{
			Write-Error -Category OperationStopped -TargetObject $ModuleStatus `
				-Message "$ModuleName module not installed"
			exit
		}
	}

	# posh-git is recommended for better git experience in PowerShell
	[string] $StablePoshGit = "0.7.3"
	[string] $RequiredPoshGit = "1.0.0"
	[string] $ModuleName = "posh-git"
	[System.Collections.Hashtable] $ModuleFullName = @{ ModuleName = $ModuleName; ModuleVersion = "$RequiredPoshGit" }
	if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
	{
		if (!$GitInstance)
		{
			Write-Information -Tags "User" -MessageData "$ModuleName module can not function without git in PATH"
		}
		else
		{
			[string] $InstallStatus = ""
			[System.Version] $TargetPoshGit = Get-Module -Name $ModuleName -ListAvailable |
			Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

			if ($TargetPoshGit)
			{
				Write-Warning -Message "$ModuleName module version '$($TargetPoshGit.ToString())' is out of date, recommended version is: $RequiredPoshGit"

				$Title = "Recommended module out of date$TitleSuffix"
				$Question = "Update '$ModuleName' module now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					PowerShellGet\Update-Module -Name $ModuleName -Scope AllUsers -ErrorAction Stop
				}
			}
			else
			{
				Write-Warning -Message "$ModuleName module minimum version $RequiredPoshGit is recommended to work with git in PowerShell"

				$Title = "Recommended module not installed$TitleSuffix"
				$Question = "Install '$ModuleName' module now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -AllowPrerelease -MinimumVersion $StablePoshGit -ErrorAction Stop
					$InstallStatus = "OK"
				}
			}

			[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable
			if ($ModuleStatus)
			{
				if (![System.String]::IsNullOrEmpty($InstallStatus))
				{
					Add-PoshGitToProfile -AllHosts
				}

				Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell should be later restarted"
			}
		}
	}

	# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing
	[string] $RequiredAnalyzer = "1.19.1"
	$ModuleName = "PSScriptAnalyzer"
	[System.Collections.Hashtable] $ModuleFullName = @{ ModuleName = "$ModuleName"; ModuleVersion = "$RequiredAnalyzer" }
	if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
	{
		[System.Version] $TargetAnalyzer = Get-Module -Name $ModuleName -ListAvailable |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

		if ($TargetAnalyzer)
		{
			Write-Warning -Message "$ModuleName module version '$($TargetAnalyzer.ToString())' is out of date, recommended version is: $RequiredAnalyzer"

			$Title = "Recommended module out of date$TitleSuffix"
			$Question = "Update '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Update-Module -Name $ModuleName -Scope AllUsers
			}
		}
		else
		{
			Write-Warning -Message "$ModuleName module minimum version $RequiredAnalyzer is required for best editing experience but not installed"

			$Title = "Recommended module not installed$TitleSuffix"
			$Question = "Install '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -MinimumVersion $RequiredAnalyzer
			}
		}

		[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable
		if ($ModuleStatus)
		{
			Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell should be later restarted"
		}
		else
		{
			Write-Error -Category OperationStopped -TargetObject $ModuleStatus `
				-Message "$ModuleName module not installed"
			exit
		}
	}

	# Pester is recommended to run pester tests
	[string] $RequiredPester = "5.0.3"
	$ModuleName = "Pester"
	[System.Collections.Hashtable] $ModuleFullName = @{ ModuleName = $ModuleName; ModuleVersion = "$RequiredPester" }
	if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
	{
		[System.Version] $TargetPester = Get-Module -Name $ModuleName -ListAvailable |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

		if ($TargetPester)
		{
			Write-Warning -Message "$ModuleName module version '$($TargetPester.ToString())' is out of date, recommended version is: $RequiredPester"

			$Title = "Recommended module out of date$TitleSuffix"
			$Question = "Update '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Update-Module -Name $ModuleName -Scope AllUsers
			}
		}
		else
		{
			Write-Warning -Message "$ModuleName module minimum version $RequiredPester is recommended to run some of the tests but not installed"

			$Title = "Recommended module not installed$TitleSuffix"
			$Question = "Install '$ModuleName' module now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -MinimumVersion $RequiredPester
			}
		}

		[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable
		if ($ModuleStatus)
		{
			Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell should be later restarted"
		}
	}

	# Everything OK, print environment status
	Write-Output ""
	Write-Output "System:`t`t $OSPlatform $($TargetOSVersion.ToString())"
	Write-Output "PowerShell:`t $PowerShellEdition $($TargetPSVersion)"
	Write-Output ""
}

#
# Function exports
#

Export-ModuleMember -Function Test-SystemRequirements


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

# TODO: repository paths whitelist check

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
Test if required system services are started
.DESCRIPTION
Test if required system services are started, some services are essential for
correct firewall and network functioning, without essential services project code
may result in errors hard to debug
.PARAMETER Services
An array of services to start
.EXAMPLE
A sample command that uses the function or script,
optionally followed by sample output and a description. Repeat this keyword for each example.
.INPUTS
[string[]] One or more service short names to check
.OUTPUTS
None.
.NOTES
[System.ServiceProcess.ServiceController[]]
#>
function Test-ServiceRequirements
{
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'This name cant be singular')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]] $Services
	)

	begin
	{
		[string] $Title = "Required service not running"
		[string[]] $Choices = "&Yes", "&No"
		[int32] $Default = 0
		[bool] $StatusGood = $true
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($InputService in $Services)
		{
			$StatusGood = $true
			$Service = Get-Service -Name $InputService

			if ($Service.Status -ne "Running")
			{
				[string] $Question = "Do you want to start $($Service.DisplayName) service now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					$RequiredServices = Get-Service -Name $Service.Name -RequiredServices

					foreach ($Required in $RequiredServices)
					{
						# For dependent services print only failures
						if ($Required.StartType -ne "Automatic")
						{
							Set-Service -Name $Required.Name -StartupType Automatic
							$Startup = Get-Service -Name $Required.Name | Select-Object -ExpandProperty StartupType

							if ($Startup -ne "Automatic")
							{
								Write-Warning -Message "Dependent service $($Required.DisplayName) set to automatic failed"
							}
							else
							{
								Write-Verbose -Message "Setting dependent $($Required.DisplayName) service to autostart succeeded"
							}
						}

						if ($Required.Status -ne "Running")
						{
							Start-Service -Name $Required.Name
							$Status = Get-Service -Name $Required.Name | Select-Object -ExpandProperty Status

							if ($Status -ne "Running")
							{
								Write-Error -Category OperationStopped -TargetObject $Required `
									-Message "Unable to proceed, Dependent services can't be started"
								Write-Information -Tags "User" -MessageData "INFO: Starting dependent service '$($Required.DisplayName)' failed, please start manually and try again"
								return $false
							}
							else
							{
								Write-Verbose -Message "Starting dependent $($Required.DisplayName) service succeeded"
							}
						}
					} # Required Services

					# If decision is no, or if service is running there is no need to modify startup type
					# Otherwise set startup type after requirements are met
					if ($Service.StartType -ne "Automatic")
					{
						Set-Service -Name $Service.Name -StartupType Automatic
						$Startup = Get-Service -Name $Service.Name | Select-Object -ExpandProperty StartupType

						if ($Startup -ne "Automatic")
						{
							Write-Warning -Message "Set service $($Service.DisplayName) to automatic failed"
						}
						else
						{
							Write-Verbose -Message "Setting $($Service.DisplayName) service to autostart succeeded"
						}
					}

					# Required services and startup is checked, start input service
					# Status was already checked
					Start-Service -Name $Service.Name
					$Status = Get-Service -Name $Service.Name | Select-Object -ExpandProperty Status

					if ($Status -eq "Running")
					{
						Write-Information -Tags "User" -MessageData "INFO: Starting $($Service.DisplayName) service succeeded"
					}
					else
					{
						$StatusGood = $false
						Write-Information -Tags "User" -MessageData "INFO: Starting $($Service.DisplayName) service failed, please start manually and try again"
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
					return $false
				}
			} # if service not running
		} # foreach InputService

		return $true
	}
}

<#
.SYNOPSIS
Test if recommended modules are installed
.DESCRIPTION
Test if recommended and up to date modules are installed, if not user is
prompted to install them.
Outdated modules can cause strange issues, this function ensures latest modules are
installed and in correct order, taking into account failures that can happen while
installing or updating modules
.PARAMETER ModuleFullName
Hash table ModuleName, Version representing minimum required module
.PARAMETER Repository
Repository from which to download module such as PSGallery
.PARAMETER InfoMessage
Optional information displayable to user for choice help message
.PARAMETER AllowPrerelease
whether to allow installing beta modules
.EXAMPLE
Test-ModuleRecommendation @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
.INPUTS
[System.Collections.Hashtable] consisting of module name and minimum required version
.OUTPUTS
None.
.NOTES
TODO: for posh-git check git in PATH
#>
function Test-ModuleRecommendation
{
	[OutputType([System.Boolean])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Collections.Hashtable] $ModuleFullName,

		[Parameter()]
		[string] $Repository = "powershellgallery.com",

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $AllowPrerelease
	)

	begin
	{
		[int32] $Default = 0

		# Importing module to learn version could result in error
		[System.Version] $PowerShellGetVersion = Get-Module -Name PowerShellGet -ListAvailable |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[string] $ConnectionStatus = ""
		if (!(Test-NetConnection $Repository -CommonTCPPort HTTP -ErrorAction Ignore))
		{
			$ConnectionStatus = " but no connection to $Repository"
		}

		if (!(Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable))
		{
			[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()

			$YesChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
			$YesChoice.HelpMessage = $InfoMessage
			$Choices += $YesChoice

			$NoChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
			$NoChoice.HelpMessage = "Skip operation"
			$Choices += $NoChoice

			# Get required module from input
			[string] $ModuleName = $ModuleFullName.ModuleName
			[System.Version] $RequiredVersion = $ModuleFullName.ModuleVersion

			# Highest version present on system if any
			[System.Version] $TargetVersion = Get-Module -Name $ModuleName -ListAvailable |
			Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

			if ($TargetVersion)
			{
				Write-Warning -Message "$ModuleName module version $($TargetVersion.ToString()) is out of date, recommended version is $RequiredVersion"

				$Title = "Recommended module out of date$ConnectionStatus"
				$Question = "Update $ModuleName module now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					# In PowerShellGet versions 2.0.0 and above, the default is CurrentUser, which does not require elevation for install.
					# In PowerShellGet 1.x versions, the default is AllUsers, which requires elevation for install.
					# NOTE: for version 1.0.1 -Scope parameter is not recognized, we'll skip it for very old version
					if (Get-InstalledModule -Name $ModuleName -ErrorAction Ignore)
					{
						if ($PowerShellGetVersion -gt "2.0.0")
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
						if ($PowerShellGetVersion -gt "2.0.0")
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
			else # Module not present
			{
				Write-Warning -Message "$ModuleName module minimum version $RequiredVersion is recommended but not installed"

				$Title = "Recommended module not installed$ConnectionStatus"
				$Question = "Install $ModuleName module now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					if ($PowerShellGetVersion -gt "2.0.0")
					{
						PowerShellGet\Install-Module -Name $ModuleName -Scope AllUsers -MinimumVersion $RequiredVersion -AllowPrerelease:$AllowPrerelease
					}
					else
					{
						# TODO: AllowPrerelease may not work here
						PowerShellGet\Install-Module -Name $ModuleName -MinimumVersion $RequiredVersion
					}
				}
			}

			# If user choose default action, check if installation was success
			if ($Decision -eq $Default)
			{
				[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable
				if ($ModuleStatus)
				{
					Write-Information -Tags "User" -MessageData "INFO: $ModuleName status changed, PowerShell must be restarted"
					return $true
				}
				{
					Write-Error -Category OperationStopped -TargetObject $ModuleStatus `
						-Message "$ModuleName module not installed"
				}
			}

			return $false
		}
	}
}

<#
.SYNOPSIS
Test if recommended packages are installed
.DESCRIPTION
Test if recommended and up to date packages are installed, if not user is
prompted to install them.
Outdated packages can cause issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating modules
.PARAMETER ProviderFullName
Hash table ProviderName, Version representing minimum required module
.PARAMETER Repository
Repository from which to download module such as PSGallery
.PARAMETER InfoMessage
Optional information displayable to user for choice help message
.EXAMPLE
Test-ModuleRecommendation @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
.INPUTS
[System.Collections.Hashtable] consisting of module name and minimum required version
.OUTPUTS
None.
.NOTES
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version
#>
function Test-ProviderRecommendation
{
	[OutputType([System.Boolean])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Collections.Hashtable] $ProviderFullName,

		[Parameter()]
		[string] $Repository = "nuget.org",

		[Parameter()]
		[string] $InfoMessage = "Accept operation"
	)

	begin
	{
		[int32] $Default = 0
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[string] $ConnectionStatus = ""
		if (!(Test-NetConnection $Repository -CommonTCPPort HTTP -ErrorAction Ignore))
		{
			$ConnectionStatus = " but no connection to $Repository"
		}

		# Get required module from input
		[string] $PackageName = $ProviderFullName.ModuleName
		[System.Version] $RequiredVersion = $ProviderFullName.ModuleVersion

		# Highest version present on system if any
		[System.Version] $TargetVersion = Get-PackageProvider -Name $PackageName |
		Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

		if (!$TargetVersion)
		{
			# TODO: need better program logic
			$TargetVersion = "0.0.0"
			Write-Warning -Message "Package provider $PackageName not installed"
		}

		if ($TargetVersion -lt $RequiredVersion)
		{
			Write-Warning -Message "$ProviderName provider version '$($TargetVersion.ToString())' is out of date, recommended version is: $RequiredVersion"

			[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()

			$YesChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
			$YesChoice.HelpMessage = $InfoMessage
			$Choices += $YesChoice

			$NoChoice = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
			$NoChoice.HelpMessage = "Skip operation"
			$Choices += $NoChoice

			$Title = "Recommended package provider is out of date$ConnectionStatus"
			$Question = "Update $ProviderName provider now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				$SoftwareIdentity = Find-PackageProvider -Name $PackageName -Source $Repository `
					-MinimumVersion $RequiredVersion -IncludeDependencies

				if ($SoftwareIdentity)
				{
					Install-PackageProvider $SoftwareIdentity.Name -Source $Repository -MinimumVersion $RequiredVersion

					[System.Version] $NewVersion = Get-PackageProvider -Name $SoftwareIdentity.Name |
					Sort-Object -Property Version | Select-Object -First 1 -ExpandProperty Version

					if ($NewVersion -gt $TargetVersion)
					{
						Write-Information -Tags "User" -MessageData "INFO: $ProviderName provider status changed, PowerShell must be restarted"
						return $true
					}
					# else error should be shown
				}
				else
				{
					Write-Warning -Message "$ProviderName provider not found to update"
				}
			}
			else
			{
				# User refused default action
				Write-Warning -Message "$ProviderName provider not installed"
			}
		}

		return $false
	}
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

	# These services are minimum required
	Test-ServiceRequirements @("lmhosts", "LanmanWorkstation", "LanmanServer")

	# NOTE: remote administration needs this service, see Enable-PSRemoting cmdlet
	# NOTE: some tests depend on this service, project not ready for remoting
	if ($develop -and ($PolicyStore -ne [System.Environment]::MachineName))
	{
		Test-ServiceRequirements "WinRM"
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

	[string] $Repository = "nuget.org"

	# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
	# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
	if (!Test-PackageRecommendation @{ ModuleName = "NuGet"; ModuleVersion = "3.0.0" } $Repository `
			-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider") { exit }

	$Repository = "powershellgallery.com"

	# PowerShellGet >= 2.2.4 is required otherwise updating modules might fail
	# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
	# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
	if (!Test-ModuleRecommendation @{ ModuleName = "PowerShellGet"; ModuleVersion = "2.2.4" } $Repository `
			-InfoMessage "PowerShellGet >= 2.2.4 is required otherwise updating modules might fail") { exit }

	# PackageManagement >= 1.4.7 is required otherwise updating modules might fail
	if (!Test-ModuleRecommendation @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } $Repository) { exit }

	# posh-git >= 1.0.0-beta4 is recommended for better git experience in PowerShell
	if (Test-ModuleRecommendation @{ ModuleName = "posh-git"; ModuleVersion = "0.7.3" } $Repository -AllowPrerelease `
			-InfoMessage "posh-git is recommended for better git experience in PowerShell" )
	{
		Add-PoshGitToProfile -AllHosts
	}

	# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing
	if (!Test-ModuleRecommendation @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1" } $Repository `
			-InfoMessage "PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing" ) { exit }

	# Pester is required to run pester tests
	if (!Test-ModuleRecommendation @{ ModuleName = "Pester"; ModuleVersion = "5.0.3" } $Repository `
			-InfoMessage "Pester is required to run pester tests" ) { }

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
Export-ModuleMember -Function Test-ServiceRequirements
Export-ModuleMember -Function Test-ModuleRecommendation
Export-ModuleMember -Function Test-ProviderRecommendation

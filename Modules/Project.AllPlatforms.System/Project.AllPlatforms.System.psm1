
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
# TODO: should process must be implemented for system changes
# if (!$PSCmdlet.ShouldProcess("ModuleName", "Update or install module if needed"))
# SupportsShouldProcess = $true, ConfirmImpact = 'High'

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
function Test-ServicesRequirement
{
	[OutputType([bool])]
	[CmdletBinding()]
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
Check if recommended modules are installed
.DESCRIPTION
Test if recommended and up to date modules are installed, if not user is
prompted to install or update them.
Outdated or missing modules can cause strange issues, this function ensures latest modules are
installed and in correct order, taking into account failures that can happen while
installing or updating modules
.PARAMETER ModuleFullName
Hash table with a minimum ModuleName and ModuleVersion keys, in the form of ModuleSpecification
.PARAMETER Repository
Repository name from which to download module such as PSGallery,
if repository is not registered user is prompted to register it
.PARAMETER RepositoryLocation
Repository location associated with repository name,
this parameter is used only if repository is not registered
.PARAMETER InstallationPolicy
If the supplied repository needs to be registered InstallationPolicy specifies
whether repository is trusted or not.
this parameter is used only if repository is not registered
.PARAMETER InfoMessage
Help message used for default choice in host prompt
.PARAMETER AllowPrerelease
whether to allow installing beta modules
.EXAMPLE
Initialize-ModulesRequirement @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "PSGallery"
.INPUTS
None. You cannot pipe objects to Initialize-ModuleRequirement
.OUTPUTS
None.
.NOTES
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version
#>
function Initialize-ModuleRequirement
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0,
			HelpMessage = "Specify module to check in the form of ModuleSpecification object")]
		[ValidateNotNullOrEmpty()]
		[hashtable] $ModuleFullName,

		[Parameter()]
		[ValidatePattern("^[a-zA-Z]+$")]
		[string] $Repository = "PSGallery",

		[Parameter()]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $RepositoryLocation = "https://www.powershellgallery.com/api/v2",

		[Parameter()]
		[ValidateSet("Trusted", "UnTrusted")]
		[string] $InstallationPolicy = "UnTrusted",

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $AllowPrerelease
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Validate module specification
	if (!($ModuleFullName.Count -ge 2 -and
			($ModuleFullName.ContainsKey("ModuleName") -and $ModuleFullName.ContainsKey("ModuleVersion"))))
	{
		Write-Error -Category InvalidArgument -TargetObject $ModuleFullName `
			-Message "ModuleSpecification parameter for: $($ModuleFullName.ModuleName) is not valid"
		return $false
	}

	# Get required module from input
	[string] $ModuleName = $ModuleFullName.ModuleName
	[version] $RequiredVersion = $ModuleFullName.ModuleVersion

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module $ModuleName is installed and what version"

	# Highest version present on system if any
	[version] $TargetVersion = Get-Module -Name $ModuleName -ListAvailable |
	Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

	if ($TargetVersion)
	{
		if ($TargetVersion -ge $RequiredVersion)
		{
			# Up to date
			Write-Information -Tags "User" -MessageData "INFO: Installed module $ModuleName v$TargetVersion meets >= v$RequiredVersion"
			return $true
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Module $ModuleName v$TargetVersion found"
	}

	if (($ModuleName -eq "posh-git") -and !$script:GitInstance)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if git.exe is in PATH required by module $ModuleName"

		if ($TargetVersion)
		{
			Write-Warning -Message "$ModuleName requires git in PATH but git.exe is not present"
		}
		else
		{
			Write-Error -Category NotInstalled -TargetObject $script:GitInstance `
				-Message "$ModuleName requires git.exe in PATH"
			return $false
		}
	}

	# User prompt default values
	[int32] $Default = 0
	[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
	$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
	$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
	$Deny.HelpMessage = "Skip operation"

	# Check for PowerShellGet only if not processing PowerShellGet
	if ($ModuleName -ne "PowerShellGet")
	{
		[version] $RequiredPowerShellGet = "2.2.4"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module PowerShellGet v$RequiredPowerShellGet is installed"

		# NOTE: Importing module to learn version could result in error
		[version] $TargetPowerShellGet = Get-Module -Name PowerShellGet -ListAvailable |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		if (!$TargetPowerShellGet -or ($TargetPowerShellGet -lt $RequiredPowerShellGet))
		{
			Write-Error -Category NotInstalled -TargetObject $TargetPowerShellGet `
				-Message "Module PowerShellGet v$RequiredPowerShellGet must be installed before other modules, v$TargetPowerShellGet is installed"
			return $false
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Module PowerShellGet v$TargetPowerShellGet found"
	}

	# Check requested repository is registered
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if repository $Repository is registered"

	# Repository name only list
	[string] $RepositoryList = ""

	# Available repositories
	[PSCustomObject[]] $Repositories = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue

	if ($Repositories)
	{
		$RepositoryList = $Repository
	}
	else
	{
		# Setup choices
		$Accept.HelpMessage = "Registered repositories are user-specific, they are not registered in a system-wide context"
		$Choices += $Accept
		$Choices += $Deny

		$Title = "Repository $Repository not registered"
		$Question = "Register $Repository repository now?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			Write-Information -Tags "User" -MessageData "INFO: Registering repository $Repository"
			# Register repository to be able to use it
			Register-PSRepository -Name $Repository -SourceLocation $RepositoryLocation -InstallationPolicy $InstallationPolicy

			$RepositoryObject = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue

			if ($RepositoryObject)
			{
				$Repositories += $RepositoryObject
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Repository $Repository is registered and $($Repositories[0].InstallationPolicy)"
			}
			# else error should be displayed
		}
		else
		{
			# Use default repositories registered by user
			$Repositories = Get-PSRepository
		}

		if (!$Repositories)
		{
			# Registering repository failed or no valid repository exists
			Write-Error -Category ObjectNotFound -TargetObject $Repositories `
				-Message "No registered repositories exist"
			return $false
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Constructing list of repositories for display"

			# Construct list for display on single line
			foreach ($RepositoryItem in $Repositories)
			{
				$RepositoryList += $RepositoryItem.Name
				$RepositoryList += ", "
			}

			$RepositoryList.TrimEnd(", ")
		}
	}

	# No need to specify type of repository, it's explained by user action
	Write-Information -Tags "User" -MessageData "INFO: Using following repositories: $RepositoryList"

	# Check if module could be downloaded
	[PSCustomObject] $FoundModule = $null
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module $ModuleName version >= $RequiredVersion could be downloaded"

	foreach ($RepositoryItem in $Repositories)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking repository $RepositoryItem for updates"

		[uri] $RepositoryURI = $RepositoryItem.SourceLocation
		if (Test-NetConnection $RepositoryURI.Host -CommonTCPPort HTTP -ErrorAction SilentlyContinue)
		{
			Write-Warning -Message "Repository $($RepositoryItem.Name) could not be contacted"
		}

		# Try anyway, only first match is considered
		$FoundModule = Find-Module -Name $ModuleName -Repository $RepositoryItem -MinimumVersion $RequiredVersion -ErrorAction SilentlyContinue

		if ($FoundModule)
		{
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$($ModuleStatus.Version.ToString()) is selected for download"
			break
		}
	}

	if (!$FoundModule)
	{
		# Registering repository failed or no valid repository exists
		Write-Error -Category ObjectNotFound -TargetObject $Repositories `
			-Message "Module $ModuleName was no found in any of the following repositories: $RepositoryList"
		return $false
	}

	# Setup new choices
	$Accept.HelpMessage = $InfoMessage
	$Choices.Clear()
	$Choices += $Accept
	$Choices += $Deny

	# Either 'Update' or "Install" needed for additional work
	[string] $InstallType = ""

	if ($TargetVersion)
	{
		Write-Warning -Message "$ModuleName module version $($TargetVersion.ToString()) is out of date, recommended version is $RequiredVersion"

		$Title = "Recommended module out of date"
		$Question = "Update $ModuleName module now?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			# TODO: splatting for parameters
			# Check if older version is user installed
			if (Get-InstalledModule -Name $ModuleName -ErrorAction Ignore)
			{
				$InstallType = "Update"
				Write-Information -Tags "User" -MessageData "INFO: Updating module $($FoundModule.Name) to v$($FoundModule.Version)"

				# In PowerShellGet versions 2.0.0 and above, the default is CurrentUser, which does not require elevation for install.
				# In PowerShellGet 1.x versions, the default is AllUsers, which requires elevation for install.
				# NOTE: for version 1.0.1 -Scope parameter is not recognized, we'll skip it for very old version
				# TODO: need to test compatible parameters for outdated Windows PowerShell
				if ($PowerShellGetVersion -gt "2.0.0")
				{
					Update-Module -InputObject $FoundModule -Scope AllUsers
				}
				else
				{
					Update-Module -InputObject $FoundModule
				}
			}
			else # Shipped with system
			{
				$InstallType = "Install"
				Write-Information -Tags "User" -MessageData "INFO: Installing module $($FoundModule.Name) v$($FoundModule.Version)"

				# Need force to install side by side, update not possible
				if ($PowerShellGetVersion -gt "2.0.0")
				{
					Install-Module -InputObject $FoundModule -AllowPrerelease:$AllowPrerelease -Scope AllUsers -Force
				}
				else
				{
					Install-Module -InputObject $FoundModule -Force
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
			$InstallType = "Install"
			Write-Information -Tags "User" -MessageData "INFO: Installing module $($FoundModule.Name) v$($FoundModule.Version)"

			if ($PowerShellGetVersion -gt "2.0.0")
			{
				Install-Module -InputObject $FoundModule -Scope AllUsers -AllowPrerelease:$AllowPrerelease
			}
			else
			{
				# TODO: AllowPrerelease may not work here
				Install-Module -InputObject $FoundModule
			}
		}
	}

	# If user choose default action, check if installation was success
	if ($Decision -eq $Default)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if $ModuleName install or update was successful"
		[PSModuleInfo] $ModuleStatus = Get-Module -FullyQualifiedName $ModuleFullName -ListAvailable

		if ($ModuleStatus)
		{
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$($ModuleStatus.Version.ToString()) is installed"

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Loading module $ModuleName v$($ModuleStatus.Version.ToString()) into session"
			# Replace old module with module in current session
			Remove-Module -Name $ModuleName
			Import-Module -Name $ModuleName

			# Finishing work, update as needed
			switch ($ModuleName)
			{
				"posh-git"
				{
					Write-Information -Tags "User" -MessageData "INFO: Adding $ModuleName $($ModuleStatus.Version.ToString()) to profile"
					Add-PoshGitToProfile -AllHosts
				}
			}

			return $true
		}
	}

	# Installation/update failed or user refused to do so
	Write-Error -Category NotInstalled -TargetObject $ModuleStatus `
		-Message "Module $ModuleName v$RequiredVersion not installed"

	return $false
}

<#
.SYNOPSIS
Test if recommended packages are installed
.DESCRIPTION
Test if recommended and up to date packages are installed, if not user is
prompted to install or update them.
Outdated or missing packages can cause strange issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating packages
.PARAMETER ProviderFullName
Hash table ProviderName, Version representing minimum required module
.PARAMETER Repository
Repository name from which to download packages such as NuGet,
if repository is not registered user is prompted to register it
.PARAMETER RepositoryLocation
Repository location associated with repository name,
this parameter is used only if repository is not registered
.PARAMETER InstallationPolicy
If the supplied repository needs to be registered InstallationPolicy specifies
whether repository is trusted or not.
this parameter is used only if repository is not registered
.PARAMETER InfoMessage
Optional information displayable to user for choice help message
.EXAMPLE
Initialize-ProviderRequirement @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
.INPUTS
None. You cannot pipe objects to Initialize-ProviderRequirement
.OUTPUTS
None.
.NOTES
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
#>
function Initialize-ProviderRequirement
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[hashtable] $ProviderFullName,

		[Parameter()]
		[ValidatePattern("^[a-zA-Z]+$")]
		[string] $Repository = "NuGet",

		[Parameter()]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $RepositoryLocation = "nuget.org",

		[Parameter()]
		[ValidateSet("Trusted", "UnTrusted")]
		[string] $InstallationPolicy = "UnTrusted",

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $AllowPrerelease
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
		[version] $RequiredVersion = $ProviderFullName.ModuleVersion

		# Highest version present on system if any
		[version] $TargetVersion = Get-PackageProvider -Name $PackageName |
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

					[version] $NewVersion = Get-PackageProvider -Name $SoftwareIdentity.Name |
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
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $false)]
		[bool] $Check = $SystemCheck,

		[Parameter()]
		[switch] $NoModulesCheck = $ModulesCheck,

		[Parameter()]
		[switch] $NoServicesCheck = $ServicesCheck
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
	[version] $TargetOSVersion = [System.Environment]::OSVersion.Version
	[version] $RequiredOSVersion = "10.0"

	if (!(($OSPlatform -eq "Win32NT") -and ($TargetOSVersion -ge $RequiredOSVersion)))
	{
		Write-Error -Category OperationStopped -TargetObject $TargetOSVersion `
			-Message "Unable to proceed, minimum required operating system is 'Win32NT $($RequiredOSVersion.ToString())' to run these scripts"

		Write-Information -Tags "Project" -MessageData "INFO: Current operating system is: '$OSPlatform $($TargetOSVersion.ToString())'"
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

	if ($OSEdition -like "*Home*")
	{
		Write-Error -Category OperationStopped -TargetObject $OSEdition `
			-Message "Unable to proceed, home editions of Windows don't have Local Group Policy"
		exit
	}

	# Check PowerShell edition
	$PowerShellEdition = $PSVersionTable.PSEdition

	if ($PowerShellEdition -eq "Core")
	{
		Write-Warning -Message "Remote firewall administration with PowerShell Core is not implemented"
		Write-Information -Tags "Project" -MessageData "INFO: Current PowerShell edition is: $PowerShellEdition"
	}
	else
	{
		Write-Warning -Message "Remote firewall administration with PowerShell Desktop is partially implemented"
	}

	# Check PowerShell version
	[version] $RequiredPSVersion = "5.1.0"
	[version] $TargetPSVersion = $PSVersionTable.PSVersion

	if ($TargetPSVersion -lt $RequiredPSVersion)
	{
		Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
			-Message "Unable to proceed, minimum required PowerShell required to run these scripts is: Desktop $($RequiredPSVersion.ToString())"

		Write-Information -Tags "Project" -MessageData "INFO: Current PowerShell version is: $($TargetPSVersion.ToString())"
		exit
	}

	# Check NET Framework version
	# NOTE: this check is not required unless in some special cases
	if ($Develop -and ($PowerShellEdition -eq "Desktop"))
	{
		# Now that OS and PowerShell is OK we can use these functions
		# TODO: What if function fails?
		$NETFramework = Get-NetFramework
		[version] $TargetNETVersion = $NETFramework |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		[version] $RequiredNETVersion = "3.5.0"

		if ($TargetNETVersion -lt $RequiredNETVersion)
		{
			Write-Error -Category OperationStopped -TargetObject $TargetNETVersion `
				-Message "Unable to proceed, minimum required NET Framework version to run these scripts is: $($RequiredNETVersion.ToString())"
			Write-Information -Tags "Project" -MessageData "INFO: Installed NET Framework version is: $($TargetNETVersion.ToString())"
			exit
		}
	}

	if (!$NoServicesCheck)
	{
		# These services are minimum required
		if (!(Test-ServiceRequirements @("lmhosts", "LanmanWorkstation", "LanmanServer"))) { exit }

		# NOTE: remote administration needs this service, see Enable-PSRemoting cmdlet
		# NOTE: some tests depend on this service, project not ready for remoting
		if ($develop -and ($PolicyStore -ne [System.Environment]::MachineName))
		{
			if (Test-ServiceRequirements "WinRM") { exit }
		}
	}

	# Git is recommended for version control and by posh-git module
	[string] $RequiredGit = "2.28.0"
	Set-Variable -Name GitInstance -Scope Script -Option Constant -Value `
	$(Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue)

	if ($GitInstance)
	{
		[version] $TargetGit = $GitInstance.Version

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

	if (!$NoModulesCheck)
	{
		[string] $Repository = "NuGet"

		# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
		# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
		if (!(Initialize-ProviderRequirement @{ ModuleName = "NuGet"; ModuleVersion = "3.0.0" } -Repository $Repository `
					-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider")) { exit }

		# PowerShellGet >= 2.2.4 is required otherwise updating modules might fail
		# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
		# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
		if (!(Initialize-ModuleRequirement @{ ModuleName = "PowerShellGet"; ModuleVersion = "2.2.4" } -Repository $Repository `
					-InfoMessage "PowerShellGet >= 2.2.4 is required otherwise updating modules might fail")) { exit }

		# PackageManagement >= 1.4.7 is required otherwise updating modules might fail
		if (!(Initialize-ModuleRequirement @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository $Repository)) { exit }

		# posh-git >= 1.0.0-beta4 is recommended for better git experience in PowerShell
		if (Initialize-ModuleRequirement @{ ModuleName = "posh-git"; ModuleVersion = "0.7.3" } -Repository $Repository -AllowPrerelease `
				-InfoMessage "posh-git is recommended for better git experience in PowerShell" ) { }

		# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing
		if (!(Initialize-ModuleRequirement @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1" } -Repository $Repository `
					-InfoMessage "PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing" )) { exit }

		# Pester is required to run pester tests
		if (!(Initialize-ModuleRequirement @{ ModuleName = "Pester"; ModuleVersion = "5.0.3" } -Repository $Repository `
					-InfoMessage "Pester is required to run pester tests" )) { }
	}

	# Everything OK, print environment status
	$OSCaption = Get-CimInstance -Class Win32_OperatingSystem |
	Select-Object -ExpandProperty Caption

	Write-Output ""
	Write-Information -Tags "User" -MessageData "INFO: Checking project requirements successful"
	Write-Output "System:`t`t $OSCaption $($TargetOSVersion.ToString())"
	Write-Output "Environment:`t PowerShell $PowerShellEdition $($TargetPSVersion)"
	Write-Output ""
}

#
# Function exports
#

Export-ModuleMember -Function Test-SystemRequirements
Export-ModuleMember -Function Test-ServiceRequirements
Export-ModuleMember -Function Initialize-ModuleRequirement
Export-ModuleMember -Function Initialize-ProviderRequirement

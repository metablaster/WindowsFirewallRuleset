
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
None. You cannot pipe objects to Initialize-Module
.OUTPUTS
None.
.NOTES
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version
#>
function Initialize-Module
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

	# TODO: check for NuGet
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
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module $ModuleName version >= v$RequiredVersion could be downloaded"

	foreach ($RepositoryItem in $Repositories)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking repository $RepositoryItem for updates"

		[uri] $RepositoryURI = $RepositoryItem.SourceLocation
		if (!(Test-NetConnection -ComputerName $RepositoryURI.Host -Port 443 -InformationLevel Quiet -ErrorAction SilentlyContinue))
		{
			Write-Warning -Message "Repository $($RepositoryItem.Name) could not be contacted"
		}

		# Try anyway, maybe port is wrong, only first match is considered
		$FoundModule = Find-Module -Name $ModuleName -Repository $RepositoryItem -MinimumVersion $RequiredVersion -ErrorAction SilentlyContinue

		if ($FoundModule)
		{
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$($ModuleStatus.Version.ToString()) is selected for download"
			break
		}
		# TODO: check for older version and ask for confirmation
	}

	if (!$FoundModule)
	{
		# Registering repository failed or no valid repository exists
		Write-Error -Category ObjectNotFound -TargetObject $Repositories `
			-Message "Module $ModuleName version >= v$RequiredVersion was not found in any of the following repositories: $RepositoryList"
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
		Write-Warning -Message "$ModuleName module version v$($TargetVersion.ToString()) is out of date, recommended version is v$RequiredVersion"

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
		Write-Warning -Message "$ModuleName module minimum version v$RequiredVersion is recommended but not installed"

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

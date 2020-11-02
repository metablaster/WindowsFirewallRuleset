
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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
Check if module is installed or needs update

.DESCRIPTION
Test if recommended and up to date module is installed, if not user is
prompted to install or update them.
Outdated or missing modules can cause strange issues, this function ensures latest modules are
installed and in correct order, taking into account failures that can happen while
installing or updating modules

.PARAMETER FullyQualifiedName
Hash table with a minimum ModuleName and ModuleVersion keys, in the form of ModuleSpecification

.PARAMETER Repository
Repository name from which to download module such as PSGallery,
if repository is not registered user is prompted to register it

.PARAMETER RepositoryLocation
Repository location associated with repository name,
this parameter is used only if repository is not registered

.PARAMETER InfoMessage
Help message used for default choice in host prompt

.PARAMETER Trusted
If the supplied repository needs to be registered Trusted specifies
whether repository is trusted or not.
this parameter is used only if repository is not registered

.PARAMETER AllowPrerelease
whether to allow installing beta modules

.PARAMETER Required
Controls whether module initialization must succeed, if initialization fails execution stops,
otherwise only warning is generated

.EXAMPLE
PS> Initialize-ModulesRequirement @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1" }
Checks if PSScriptAnalyzer is up to date, if not user is prompted to update, and if repository
specified by default is not registered user is prompted to do that too.

.EXAMPLE
PS> Initialize-ModulesRequirement @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository `
> "PSGallery" -RepositoryLocation "https://www.powershellgallery.com/api/v2"
Checks if PackageManagement is up to date, if not user is prompted to update, and if repository
is not registered user is prompted to do that too.

.INPUTS
None. You cannot pipe objects to Initialize-Module

.OUTPUTS
[System.Boolean]

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version
TODO: Implement initializing for non Administrator users
TODO: installing post-git in same session while installing other modules may fail, and PS restart is required.
#>
function Initialize-Module
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Initialize/Help/en-US/Initialize-Module.md" )]
	param (
		[Parameter(Mandatory = $true, Position = 0,
			HelpMessage = "Specify module to check in the form of ModuleSpecification object")]
		[ValidateNotNullOrEmpty()]
		[hashtable] $FullyQualifiedName,

		[Parameter()]
		[ValidatePattern("^[a-zA-Z]+$")]
		[string] $Repository = "PSGallery",

		[Parameter()]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $RepositoryLocation = "https://www.powershellgallery.com/api/v2",

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $Trusted,

		[Parameter()]
		[switch] $AllowPrerelease,

		[Parameter()]
		[switch] $Required
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Validate module specification
	if (!($FullyQualifiedName.Count -ge 2 -and
			($FullyQualifiedName.ContainsKey("ModuleName") -and $FullyQualifiedName.ContainsKey("ModuleVersion"))))
	{
		$Message = "ModuleSpecification parameter for: $($FullyQualifiedName.ModuleName) is not valid"
		if ($Required)
		{
			Write-Error -Category InvalidArgument -TargetObject $FullyQualifiedName -Message $Message
			return $false
		}

		Write-Warning -Message $Message
		return $true
	}

	# Get required module from input
	[string] $ModuleName = $FullyQualifiedName.ModuleName
	[version] $RequireVersion = $FullyQualifiedName.ModuleVersion

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if module $ModuleName is installed and which version"

	# Highest version present on system if any
	[version] $TargetVersion = Get-Module -Name $ModuleName -ListAvailable |
	Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

	if ($TargetVersion)
	{
		if ($TargetVersion -ge $RequireVersion)
		{
			if ($ModuleName -eq "PowerShellGet")
			{
				# Let other parts of a module know PowerShellGet is up to date
				Set-Variable -Name HasPowerShellGet -Scope Script -Option ReadOnly -Force -Value $true
			}

			# Up to date
			# TODO: for AllowPrerelease we should check for prerelease, example required posh-git 0.7.3 if met, no prerelease will be installed
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$TargetVersion meets >= v$RequireVersion"
			return $true
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Module $ModuleName v$TargetVersion found"
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Module $ModuleName not installed"
	}

	if ($ModuleName -eq "posh-git")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if git.exe is in PATH required by module $ModuleName"

		if ($script:GitInstance)
		{
			Write-Information -Tags "Project" -MessageData "INFO: Checking if git.exe is in PATH, required by $ModuleName was success"
		}
		else
		{
			if ($TargetVersion)
			{
				Write-Warning -Message "$ModuleName requires git in PATH but git.exe not present, aborting update..."
			}
			else
			{
				$Message = "$ModuleName requires git in PATH but git.exe not present, aborting installation..."
				if ($Required)
				{
					Write-Error -Category NotInstalled -TargetObject $script:GitInstance -Message $Message
					return $false
				}

				Write-Warning -Message $Message
				return $true
			}
		}
	}

	# User prompt default values
	[int32] $Default = 0
	[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
	$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
	$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
	$Deny.HelpMessage = "Skip operation, module $ModuleName will not be installed or updated"

	# NOTE: Importing module to learn version could result in error
	[version] $TargetPowerShellGet = Get-Module -Name PowerShellGet -ListAvailable |
	Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

	# Check for PowerShellGet only if not processing PowerShellGet
	if ($ModuleName -ne "PowerShellGet")
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module PowerShellGet v$RequirePowerShellGetVersion is installed"

		if (!$TargetPowerShellGet -or ($TargetPowerShellGet -lt $RequirePowerShellGetVersion))
		{
			$Message = "Module PowerShellGet v$RequirePowerShellGetVersion must be installed before other modules, installed version is v$TargetPowerShellGet"
			if ($Required)
			{
				Write-Error -Category NotInstalled -TargetObject $TargetPowerShellGet -Message $Message
				return $false
			}

			Write-Warning -Message $Message
			return $true
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Module PowerShellGet v$TargetPowerShellGet found"
	}

	# Check requested repository is registered
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if repository $Repository is registered"

	# Repository name only list
	[string] $RepositoryList = ""

	# Available repositories
	# NOTE: only one may exist with same name, using it as $Repositories[0]
	[PSCustomObject[]] $Repositories = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue

	if ($Repositories)
	{
		$RepositoryList = $Repositories[0].Name

		if ($Repositories[0].InstallationPolicy -ne "Trusted")
		{
			# Setup choices
			$Accept.HelpMessage = "Setting to trusted won't ask you for confirmation in the future"
			$Choices += $Accept
			$Choices += $Deny

			$Title = "Repository $Repository is not trusted"
			$Question = "Set $Repository as trusted now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Set-PSRepository -Name $Repository -InstallationPolicy Trusted
				$Repositories = Get-PSRepository -Name $Repository

				if ($Repositories[0].InstallationPolicy -eq "Trusted")
				{
					Write-Debug -Message "Repository $Repository set to trusted"
				}
			}
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Repository $Repository is registered"
	}
	else # Register input repository
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Repository $Repository is not registered"

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

			$IsTrusted = "Untrusted"
			if ($Trusted)
			{
				$IsTrusted = "Trusted"
			}

			if ($Repository -eq "PSGallery")
			{
				# To register PSGallery the -Default must be specified
				# TODO: The -Default switch not documented at this point
				Register-PSRepository -Default -InstallationPolicy $IsTrusted
			}
			else
			{
				# Register repository to be able to use it
				Register-PSRepository -Name $Repository -SourceLocation $RepositoryLocation -InstallationPolicy $IsTrusted
			}

			$RepositoryObject = Get-PSRepository -Name $Repository # -ErrorAction SilentlyContinue

			if ($RepositoryObject)
			{
				$Repositories = $RepositoryObject
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Repository $Repository is registered and $IsTrusted)"
			}
			# else error should be displayed and $Repositories variable is null
		}
		else
		{
			# TODO: Use default repositories registered by user?
			$Repositories = Get-PSRepository
		}

		if ($Repositories)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Constructing list of repositories for display"

			# Construct list for display on single line
			foreach ($RepositoryItem in $Repositories)
			{
				$RepositoryList += $RepositoryItem.Name
				$RepositoryList += ", "
			}

			$RepositoryList = $RepositoryList.TrimEnd(", ")
		}
		else
		{
			# Registering repository failed or no valid repository exists
			$Message = "No registered repositories exist"

			if ($Required)
			{
				# $Repositories is null
				Write-Error -Category ObjectNotFound -TargetObject $Repository -Message $Message
				return $false
			}

			Write-Warning -Message $Message
			return $true
		}
	}

	# No need to specify type of repository, it's explained by user action
	Write-Information -Tags "User" -MessageData "INFO: Using following repositories: $RepositoryList"

	# Check if module could be downloaded
	[PSCustomObject] $FoundModule = $null

	# In PowerShellGet versions 2.0.0 and above, the default is CurrentUser, which does not require elevation for install.
	# In PowerShellGet 1.x versions, the default is AllUsers, which requires elevation for install.
	# NOTE: for version 1.0.1 -Scope parameter is not recognized, we'll skip it for very old version
	# HACK: need to test compatible parameters for outdated Windows PowerShell
	[version] $Version2 = "2.0.0"

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if module $ModuleName version >= v$RequireVersion is available for download"

	foreach ($RepositoryItem in $Repositories)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking repository $($RepositoryItem.Name) for updates"

		# TODO: verify -AllowPrerelease will work in all cases
		# if ($TargetPowerShellGet -ge $Version2) do not use -AllowPrerelease
		# However then stable posh-git and similar modules will be installed because of $FoundModule variable
		# Meaning we must not reuse $FoundModule in that case,
		# for project this is not urgent since we install modules in correct order
		# HACK: -AllowPrerelease will not work if PackageManagement or PowerShellGet is out of date (probably version < 2.0.0)
		# see: https://github.com/MicrosoftDocs/azure-docs/issues/29999
		# TODO: for some reason updated module was not loaded, probably because error stopped execution

		# Try anyway, maybe port is wrong, only first match is considered
		# NOTE: -InputObject can't be used with -AllowPrerelease, we'll use -AllowPrerelease here to be able to install what is found
		if ($TargetPowerShellGet -ge $Version2)
		{
			$FoundModule = Find-Module -Name $ModuleName -Repository $RepositoryItem.Name `
				-MinimumVersion $RequireVersion -AllowPrerelease:$AllowPrerelease # -ErrorAction SilentlyContinue
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Finding module $ModuleName for download failed, trying alternative solution"
			$FoundModule = Find-Module -Name $ModuleName -Repository $RepositoryItem.Name `
				-MinimumVersion $RequireVersion # -ErrorAction SilentlyContinue
		}

		if ($FoundModule)
		{
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$($FoundModule.Version.ToString()) is selected for download"
			break
		}
		# else error should be displayed
		# TODO: check for older version and ask for confirmation
	}

	if (!$FoundModule)
	{
		$Message = "Module $ModuleName version >= v$RequireVersion was not found in any of the following repositories: $RepositoryList"
		if ($Required)
		{
			# Registering repository failed or no valid repository exists
			Write-Error -Category ObjectNotFound -TargetObject $FullyQualifiedName -Message $Message
			return $false
		}

		Write-Warning -Message $Message
		return $true
	}

	# Setup new choices
	$Accept.HelpMessage = $InfoMessage
	$Choices = @()
	$Choices += $Accept
	$Choices += $Deny

	$Title = "Recommended"
	if ($Required)
	{
		$Title = "Required"
	}

	if ($TargetVersion)
	{
		Write-Warning -Message "Current module $ModuleName v$($TargetVersion.ToString()) is out of date, recommended version is v$RequireVersion"

		$Title += " module out of date"
		$Question = "Update $ModuleName module now?"
		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			# Check if older version is user installed
			if (Get-InstalledModule -Name $ModuleName -ErrorAction Ignore)
			{
				Write-Information -Tags "User" -MessageData "INFO: Updating module $($FoundModule.Name) to v$($FoundModule.Version)"

				if ($TargetPowerShellGet -ge $Version2)
				{
					Update-Module $ModuleName -Scope AllUsers
				}
				else
				{
					Update-Module $ModuleName
				}
			}
			else # Shipped with system
			{
				Write-Information -Tags "User" -MessageData "INFO: Installing module $($FoundModule.Name) v$($FoundModule.Version) side by side"

				# Need force to install side by side, update not possible
				if ($TargetPowerShellGet -ge $Version2)
				{
					# NOTE: -InputObject can't be used with -AllowPrerelease
					Install-Module -InputObject $FoundModule -Scope AllUsers -Force
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
		Write-Warning -Message "$ModuleName module minimum version v$RequireVersion is recommended but not installed"

		$Title += " module not installed"
		$Question = "Install $ModuleName module now?"

		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			Write-Information -Tags "User" -MessageData "INFO: Installing module $($FoundModule.Name) v$($FoundModule.Version)"

			if ($TargetPowerShellGet -ge $Version2)
			{
				# NOTE: -InputObject can't be used with -AllowPrerelease
				Install-Module -InputObject $FoundModule -Scope AllUsers
			}
			else
			{
				Install-Module -InputObject $FoundModule
			}
		}
	}

	# If user choose default action, check if installation was success
	if ($Decision -eq $Default)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if $ModuleName install or update was successful"
		[PSModuleInfo] $ModuleInfo = Get-Module -FullyQualifiedName $FullyQualifiedName -ListAvailable

		if ($ModuleInfo)
		{
			Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName v$RequireVersion was installed/updated"

			# Remove old module if it exists and is loaded
			# TODO: It looks like this method doesn't solve the problem and we need to restart PowerShell anyway
			Remove-Module -Name $ModuleName -Force -ErrorAction Ignore

			if ($ModuleName -eq "PowerShellGet")
			{
				# Let other parts of a module know PowerShellGet is up to date
				Set-Variable -Name HasPowerShellGet -Scope Script -Option ReadOnly -Force -Value $true

				# PackageManagement must be reloaded too
				# TODO: because of pester signature error?
				Remove-Module -Name PackageManagement -Force -ErrorAction Ignore

				# PowerShell needs to restart
				Set-Variable -Name Restart -Scope Script -Value $true
			}

			Write-Information -Tags "User" -MessageData "INFO: Loading module $ModuleName v$RequireVersion into session"

			# Load new module into current session
			# TODO: In case of PowerShellGet this should load PackageManagement too?
			Import-Module -ModuleInfo $ModuleInfo -Scope Global

			if (!(Get-Module -FullyQualifiedName $FullyQualifiedName))
			{
				# PowerShell needs to restart
				Set-Variable -Name Restart -Scope Script -Value $true

				Write-Warning -Message "$ModuleName provider v$RequireVersion could not be imported, please restart PowerShell and try again"
			}

			# Finishing work, update as needed
			# TODO: will not run if module not imported?
			if ($ModuleName -eq "posh-git")
			{
				# TODO: shortened prompt, is valid only for user home path
				# TODO: last test did not execute Add-PoshGitToProfile after failed and second attempt
				Write-Information -Tags "User" -MessageData "INFO: Adding $ModuleName v$RequireVersion to profile"
				Add-PoshGitToProfile -AllHosts
			}

			return $true
		}
	}

	$Message = "Module $ModuleName v$RequireVersion was not installed/updated"
	if ($Required)
	{
		# Installation/update failed or user refused to do so
		Write-Error -Category NotInstalled -TargetObject $FullyQualifiedName -Message $Message
		return $false
	}

	Write-Warning -Message $Message
	return $true
}

#
# Module variables
#

# Let other parts of a module know status about PowerShellGet
Set-Variable -Name HasPowerShellGet -Scope Script -Option ReadOnly -Force -Value $false

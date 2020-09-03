
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
Test if recommended packages are installed
.DESCRIPTION
Test if recommended and up to date packages are installed, if not user is
prompted to install or update them.
Outdated or missing packages can cause strange issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating packages
.PARAMETER FullyQualifiedName
Hash table ProviderName, Version representing minimum required module
.PARAMETER Name
Package source name which to assign to registered provider if registration is needed
.PARAMETER Location
Repository name from which to download packages such as NuGet,
if repository is not registered user is prompted to register it
.PARAMETER Trusted
If the supplied repository needs to be registered Trusted specifies
whether repository is trusted or not.
this parameter is used only if repository is not registered
.PARAMETER InfoMessage
Optional information displayable to user for choice help message
.PARAMETER Required
Controls whether the provider initialization must succeed, if initialization fails execution stops,
otherwise only warning is generated
.EXAMPLE
Initialize-Provider @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
.INPUTS
None. You cannot pipe objects to Initialize-Provider
.OUTPUTS
None.
.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

There is no "Repository" parameter here like in Initialize-Module, instead it's called ProviderName
which is supplied in parameter FullyQualifiedName
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
#>
function Initialize-Provider
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[hashtable] $FullyQualifiedName,

		[Parameter()]
		[string] $Name = "nuget.org",

		[Parameter()]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $Location = "https://api.nuget.org/v3/index.json",
		# HACK: array https://www.nuget.org/api/v2 (used by PSGallery?)
		# NOTE: suggested in Windows PowerShell: https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll
		[Parameter()]
		[switch] $Trusted,

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $Required
	)

	begin
	{
		# User prompt default values
		[int32] $Default = 0
		[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
		$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
		$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[string] $ProviderName = $FullyQualifiedName.ModuleName
		$Deny.HelpMessage = "Skip operation, provider $ProviderName will not be installed or updated"

		# Validate module specification
		if (!($FullyQualifiedName.Count -ge 2 -and
				($FullyQualifiedName.ContainsKey("ModuleName") -and $FullyQualifiedName.ContainsKey("ModuleVersion"))))
		{
			$Message = "ModuleSpecification parameter for: $ProviderName is not valid"
			if ($Required)
			{
				Write-Error -Category InvalidArgument -TargetObject $FullyQualifiedName -Message $Message
				return $false
			}

			Write-Warning -Message $Message
			return $true
		}

		# Get required provider package from input
		[version] $RequireVersion = $FullyQualifiedName.ModuleVersion

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if provider $ProviderName is installed and which version"

		# Highest version present on system if any
		[version] $TargetVersion = Get-PackageProvider -Name $ProviderName -ListAvailable -ErrorAction SilentlyContinue |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		if ($TargetVersion)
		{
			if ($TargetVersion -ge $RequireVersion)
			{
				if ($ProviderName -eq "NuGet")
				{
					# Let other parts of a module know NuGet is up to date
					Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $true
				}

				Write-Information -Tags "User" -MessageData "INFO: Provider $ProviderName v$TargetVersion meets >= v$RequireVersion"
				return $true
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider $ProviderName v$TargetVersion found"
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider $ProviderName not installed"
		}

		# Check requested package source is registered
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if package source $ProviderName is registered"

		# Package source name only list
		[string] $SourcesList = ""

		# Available package sources if found have these sample properties:
		# Name     : nuget.org
		# Location : https://api.nuget.org/v3/index.json
		# Source   : nuget.org
		# ProviderName : NuGet
		# Provider  : Microsoft.PackageManagement.Implementation.PackageProvider
		# IsTrusted : False
		# IsRegistered : True
		# TODO: If not found "PowerShell" may ask to install, and if that fails it may return package source anyway (seen in: Windows PowerShell)
		# NOTE: This is controlled with powershell.promptToUpdatePackageManagement
		[PSCustomObject[]] $PackageSources = Get-PackageSource -ProviderName $ProviderName -ErrorAction SilentlyContinue # -Name $Name

		if ($PackageSources)
		{
			$SourcesList = $ProviderName

			if (!$PackageSources.IsTrusted)
			{
				# Setup choices
				$Accept.HelpMessage = "Setting to trusted won't ask you in the future for confirmation"
				$Choices += $Accept
				$Choices += $Deny

				$Title = "Package source $ProviderName is not trusted"
				$Question = "Set $ProviderName as trusted now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					Set-PackageSource -Name $ProviderName -Trusted
					$PackageSources = Get-PackageSource -ProviderName $ProviderName

					if ($PackageSources.IsTrusted)
					{
						Write-Debug -Message "Package source $ProviderName set to trusted"
					}
				}
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source $ProviderName is registered"
		}
		else # Register provided package source
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source $ProviderName is not registered"

			# Setup choices
			$Accept.HelpMessage = "Add a package source for a specified package provider"
			$Choices += $Accept
			$Choices += $Deny

			$Title = "Package source $ProviderName not registered"
			$Question = "Register $ProviderName package source now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Write-Information -Tags "User" -MessageData "INFO: Registering package source $ProviderName"

				# Register package source to be able to use it
				Register-PackageSource -Name $Name -ProviderName $ProviderName -Location $Location -Trusted:$Trusted

				$SourceObject = Get-PackageSource -Name $Name -ProviderName $ProviderName # -ErrorAction SilentlyContinue

				if ($SourceObject)
				{
					$PackageSources += $SourceObject
					$IsTrusted = "UnTrusted"

					if ($PackageSources[0].IsTrusted)
					{
						$IsTrusted = "Trusted"
					}

					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Package source $ProviderName is registered and $IsTrusted"
				}
				# else error should be displayed
			}
			else
			{
				# Use default registered package sources
				$PackageSources = Get-PackageSource
				Write-Debug -Message "[$($MyInvocation.InvocationName)] User refused to register $ProviderName, using system default package sources"
			}

			if (!$PackageSources)
			{
				$Message = "No registered package source exist"
				if ($Required)
				{
					# Registering repository failed or no valid package source exists
					Write-Error -Category ObjectNotFound -TargetObject $PackageSources -Message $Message
					return $false
				}

				Write-Warning -Message $Message
				return $true
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Constructing list of package sources for display"

				# Construct list for display on single line
				foreach ($SourceItem in $PackageSources)
				{
					$SourcesList += $SourceItem.Name
					$SourcesList += ", "
				}

				$SourcesList = $SourcesList.TrimEnd(", ")
			}
		}

		# No need to specify type of repository, it's explained by user action
		Write-Information -Tags "User" -MessageData "INFO: Using following package sources: $SourcesList"

		# Check if module could be downloaded
		# [Microsoft.PackageManagement.Packaging.SoftwareIdentity]
		[PSCustomObject] $FoundProvider = $null
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if $ProviderName provider version >= v$RequireVersion is available for download"

		# NOTE: $PackageSources may contains following 3 package sources in following order of possibility:
		# 1. explicit source requested by user, there could be multiple that match and are registered
		# 2. source offered during offer by PowerShell to install, (TODO: which may not be registered?)
		# 3. source was not found on system, but it was manually registered
		# 4. all available package sources registered on system
		# Which means we need to handle all 4 possible cases
		foreach ($SourceItem in $PackageSources)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking repository $SourceItem for updates"

			[uri] $SourceURI = $SourceItem.Location
			if (!(Test-NetConnection -ComputerName $SourceURI.Host -Port 443 -InformationLevel Quiet)) # -ErrorAction SilentlyContinue
			{
				Write-Warning -Message "Package source $($SourceItem.Name) could not be contacted"
			}

			# This (handles all 4 cases) is handled in case when first call to Get-PackageSource offers installation,
			# fails installing and returns source for download
			$FoundProvider = Find-PackageProvider -Name $SourceItem.Name -Source $SourceItem.Location `
				-MinimumVersion $RequireVersion -IncludeDependencies -ErrorAction SilentlyContinue

			if (!$FoundProvider)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Finding provider $ProviderName for download failed, trying alternative solution"
				# Try with Find-Package
				$FoundProvider = Find-Package -Name $SourceItem.Name -Source $SourceItem.Location -IncludeDependencies `
					-MinimumVersion $RequireVersion -AllowPrereleaseVersions # -ErrorAction SilentlyContinue
			}

			if ($FoundProvider)
			{
				Write-Information -Tags "User" -MessageData "INFO: Provider $($FoundProvider.Name) v$($FoundProvider.Version.ToString()) is selected for download"
				break
			}
			# else error should be displayed
			# TODO: Check for older version and ask for confirmation
		}

		if (!$FoundProvider)
		{
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Write-Warning -Message "Provider $ProviderName was not found because of a known issue with PowerShell Core"
				Write-Information -Tags "User" -MessageData "INFO: https://github.com/OneGet/oneget/issues/360"

				return !$Required
			}

			$Message = "$ProviderName provider version >= v$RequireVersion was not found in any of the following package sources: $SourcesList"
			if ($Required)
			{
				# Registering repository failed or no valid repository exists
				Write-Error -Category ObjectNotFound -TargetObject $PackageSources -Message $Message
				return $false
			}

			Write-Warning -Message $Message
			return $true
		}

		# Setup prompt
		$Title = "Recommended"
		if ($Required)
		{
			$Title = "Required"
		}

		if ($TargetVersion)
		{
			$Title += " package provider is out of date"
			$Question = "Install $ProviderName provider now?"
			Write-Warning -Message "Provider $ProviderName v$($TargetVersion.ToString()) is out of date, required version is v$RequireVersion"
		}
		else
		{
			$Title += " package provider is not installed"
			$Question = "Update $ProviderName provider now?"
			Write-Warning -Message "$ProviderName provider minimum version v$RequireVersion is required but not installed"
		}

		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			Write-Information -Tags "User" -MessageData "INFO: Installing provider $($FoundProvider.Name) v$($FoundProvider.Version.ToString())"
			Install-PackageProvider -Name $FoundProvider.Name -Source $FoundProvider.Source

			[version] $NewVersion = Get-PackageProvider -Name $FoundProvider.Name |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			if ($NewVersion -and ($NewVersion -gt $TargetVersion))
			{
				Write-Information -Tags "User" -MessageData "INFO: $ProviderName provider v$NewVersion is installed"

				# Force, don't ask for confirmation
				Import-PackageProvider -Name $ProviderName -RequiredVersion $NewVersion -Force

				# If not imported into current session restart is required
				if (!(Get-PackageProvider -Name $ProviderName))
				{
					Write-Warning -Message "$ProviderName provider v$NewVersion could not be imported, please restart PowerShell and try again"
					return $false
				}

				# Let other parts of a module know NuGet is up to date
				Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $true
				return $true
			}
			# else error should be shown
			# TODO: was not installed or updated
		}
		else
		{
			# User refused default action
			# TODO: should this be error? maybe switch
			Write-Warning -Message "Installing provider $ProviderName aborted by user"
		}

		return !$Required
	} # process
}

#
# Module variables
#

# Let other parts of a module know status about Nuget
Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $false

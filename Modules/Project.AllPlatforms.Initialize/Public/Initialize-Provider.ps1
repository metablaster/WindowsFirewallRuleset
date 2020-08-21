
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
Test if recommended packages are installed
.DESCRIPTION
Test if recommended and up to date packages are installed, if not user is
prompted to install or update them.
Outdated or missing packages can cause strange issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating packages
.PARAMETER ProviderFullName
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
.EXAMPLE
Initialize-Provider @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
.INPUTS
None. You cannot pipe objects to Initialize-Provider
.OUTPUTS
None.
.NOTES
There is no "Repository" parameter here like in Initialize-Module, instead it's called ProviderName
which is supplied in parameter ProviderFullName
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
#>
function Initialize-Provider
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[hashtable] $ProviderFullName,

		[Parameter()]
		[string] $Name = "nuget.org",

		[Parameter()]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $Location = "https://api.nuget.org/v3/index.json",
		# TODO: array https://www.nuget.org/api/v2 (used by PSGallery?)
		# TODO: suggested in Windows PowerShell: https://onegetcdn.azureedge.net/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll
		[Parameter()]
		[switch] $Trusted,

		[Parameter()]
		[string] $InfoMessage = "Accept operation"
	)

	begin
	{
		# User prompt default values
		[int32] $Default = 0
		[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
		$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
		$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
		$Deny.HelpMessage = "Skip operation"
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# Validate module specification
		if (!($ProviderFullName.Count -ge 2 -and
				($ProviderFullName.ContainsKey("ModuleName") -and $ProviderFullName.ContainsKey("ModuleVersion"))))
		{
			Write-Error -Category InvalidArgument -TargetObject $ProviderFullName `
				-Message "ModuleSpecification parameter for: $($ProviderFullName.ModuleName) is not valid"
			return $false
		}

		# Get required provider package from input
		[string] $ProviderName = $ProviderFullName.ModuleName
		[version] $RequireVersion = $ProviderFullName.ModuleVersion

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if provider $ProviderName is installed and which version"

		# Highest version present on system if any
		[version] $TargetVersion = Get-PackageProvider -Name $ProviderName -ListAvailable -ErrorAction SilentlyContinue |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		if ($TargetVersion)
		{
			if ($TargetVersion -ge $RequireVersion)
			{
				# Up to date
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
		[PSCustomObject[]] $PackageSources = Get-PackageSource -ProviderName $ProviderName # -ErrorAction SilentlyContinue # -Name $Name

		if ($PackageSources)
		{
			$SourcesList = $ProviderName
			# TODO: Prompt to set it as trusted
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source $ProviderName is registered"
		}
		else
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

				$SourceObject = Get-PackageSource -Name $Name -ProviderName $ProviderName -ErrorAction SilentlyContinue

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
				# Registering repository failed or no valid package source exists
				Write-Error -Category ObjectNotFound -TargetObject $PackageSources `
					-Message "No registered package source exist"
				return $false
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
			if (!(Test-NetConnection -ComputerName $SourceURI.Host -Port 443 -InformationLevel Quiet -ErrorAction SilentlyContinue))
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
					-MinimumVersion $RequireVersion -AllowPrereleaseVersions -ErrorAction SilentlyContinue
			}

			if ($FoundProvider)
			{
				Write-Information -Tags "User" -MessageData "INFO: $($FoundProvider.Name) provider v$($FoundProvider.Version.ToString()) is selected for download"
				break
			}
			# else error should be displayed, TODO: Check for older version and ask for confirmation
		}

		if (!$FoundProvider)
		{
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Write-Warning -Message "$ProviderName was not found because of a known issue with PowerShell Core"
				Write-Information -Tags "User" -MessageData "INFO: https://github.com/OneGet/oneget/issues/360"
				return $false
			}

			# Registering repository failed or no valid repository exists
			Write-Error -Category ObjectNotFound -TargetObject $PackageSources `
				-Message "$ProviderName provider version >= v$RequireVersion was not found in any of the following package sources: $SourcesList"
			return $false
		}

		# Setup prompt
		if ($TargetVersion)
		{
			$Title = "Required package provider is out of date"
			$Question = "Install $ProviderName provider now?"
			Write-Warning -Message "$ProviderName provider version v$($TargetVersion.ToString()) is out of date, required version is v$RequireVersion"
		}
		else
		{
			$Title = "Required package provider is not installed"
			$Question = "Update $ProviderName provider now?"
			Write-Warning -Message "$ProviderName provider minimum version v$RequireVersion is required but not installed"
		}

		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			Write-Information -Tags "User" -MessageData "INFO: Installing $($FoundProvider.Name) provider v$($FoundProvider.Version.ToString())"
			Install-PackageProvider -Name $FoundProvider.Name -Source $FoundProvider.Source

			[version] $NewVersion = Get-PackageProvider -Name $FoundProvider.Name |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			if ($TargetVersion -and ($NewVersion -gt $TargetVersion))
			{
				Write-Information -Tags "User" -MessageData "INFO: $ProviderName provider v$NewVersion is installed"
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

		return $false
	} # process
}

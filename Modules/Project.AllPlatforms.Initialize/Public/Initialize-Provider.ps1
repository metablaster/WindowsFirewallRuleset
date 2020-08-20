
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
Hash table ProviderName, Version representing minimum required module
.PARAMETER ProviderName
Hash table ProviderName, Version representing minimum required module
.PARAMETER Location
Repository name from which to download packages such as NuGet,
if repository is not registered user is prompted to register it
.PARAMETER Trusted
If the supplied repository needs to be registered InstallationPolicy specifies
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
		[uri] $Location = "https://api.nuget.org/v3/index.json", # TODO: array https://www.nuget.org/api/v2 (used by PSGallery?)

		[Parameter()] # TODO: switch also for modules
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
		[version] $RequiredVersion = $ProviderFullName.ModuleVersion

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if provider $ProviderName is installed and what version"

		# Highest version present on system if any
		[version] $TargetVersion = Get-PackageProvider -Name $ProviderName -ListAvailable |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		if ($TargetVersion)
		{
			if ($TargetVersion -ge $RequiredVersion)
			{
				# Up to date
				Write-Information -Tags "User" -MessageData "INFO: Installed provider $ProviderName v$TargetVersion meets >= v$RequiredVersion"
				return $true
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider $ProviderName v$TargetVersion found"
		}

		# Check requested package source is registered
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if package source $ProviderName is registered"

		# Package source name only list
		[string] $SourcesList = ""

		# Available package sources
		[PSCustomObject[]] $PackageSources = Get-PackageSource -Name $Name -ProviderName $ProviderName -ErrorAction SilentlyContinue

		if ($PackageSources)
		{
			$SourcesList = $ProviderName
		}
		else
		{
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

				# TODO: use $foreach, anyway it doesn't work
				$SourcesList.TrimEnd(", ")
			}
		}

		# No need to specify type of repository, it's explained by user action
		Write-Information -Tags "User" -MessageData "INFO: Using following package sources: $SourcesList"

		# Check if module could be downloaded
		# [Microsoft.PackageManagement.Packaging.SoftwareIdentity]
		[PSCustomObject] $FoundProvider = $null
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if $ProviderName provider version >= v$RequiredVersion could be downloaded"

		foreach ($SourceItem in $PackageSources)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking repository $SourceItem for updates"

			[uri] $SourceURI = $SourceItem.Location
			if (!(Test-NetConnection -ComputerName $SourceURI.Host -Port 443 -InformationLevel Quiet -ErrorAction SilentlyContinue))
			{
				Write-Warning -Message "Package source $($SourceItem.Name) could not be contacted"
			}

			# Try anyway, maybe port is wrong, only first match is considered
			$FoundProvider = Find-PackageProvider -Name $ProviderName -Source $Location `
				-MinimumVersion $RequiredVersion -IncludeDependencies -ErrorAction SilentlyContinue

			if (!$FoundProvider)
			{
				# Try with Find-Package
				$FoundProvider = Find-Package -Name $ProviderName -Source $SourceItem.Name -IncludeDependencies `
					-MinimumVersion $RequiredVersion -AllowPrereleaseVersions -ErrorAction SilentlyContinue
			}

			if ($FoundProvider)
			{
				Write-Information -Tags "User" -MessageData "INFO: $FoundProvider provider v$($FoundProvider.Version.ToString()) is selected for download"
				break
			}

			# TODO: else check for older version and ask for confirmation
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
				-Message "$ProviderName provider version >= v$RequiredVersion was not found in any of the following package sources: $SourcesList"
			return $false
		}

		# Setup prompt
		if (!$TargetVersion)
		{
			$Title = "Required package provider is not installed"
			$Question = "Update $ProviderName provider now?"
			Write-Warning -Message "$ProviderName provider minimum version v$RequiredVersion is required but not installed"
		}
		else
		{
			$Title = "Required package provider is out of date"
			$Question = "Install $ProviderName provider now?"
			Write-Warning -Message "$ProviderName provider version v$($TargetVersion.ToString()) is out of date, required version is v$RequiredVersion"
		}

		$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

		if ($Decision -eq $Default)
		{
			Write-Information -Tags "User" -MessageData "INFO: Installing $($FoundProvider.Name) provider v$($FoundProvider.Version.ToString())"
			Install-PackageProvider $FoundProvider.Name -Source $FoundProvider.Source

			[version] $NewVersion = Get-PackageProvider -Name $FoundProvider.Name |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			if ($NewVersion -gt $TargetVersion)
			{
				Write-Information -Tags "User" -MessageData "INFO: $ProviderName provider v$NewVersion is installed"
				return $true
			}
			# else error should be shown
		}
		else
		{
			# User refused default action
			# TODO: should this be error?
			Write-Warning -Message "$ProviderName provider not installed"
		}

		return $false
	} # process
}

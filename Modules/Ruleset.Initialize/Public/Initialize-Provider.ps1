
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Update or install specified package provider

.DESCRIPTION
Test if recommended and up to date packages are installed, if not user is
prompted to install or update them.
Outdated or missing packages can cause strange issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating packages

.PARAMETER FullyQualifiedName
Hash table ProviderName, Version representing minimum required module

.PARAMETER InfoMessage
Optional information displayable to user for choice help message

.PARAMETER Required
Controls whether the provider initialization must succeed, if initialization fails execution stops,
otherwise only warning is generated

.EXAMPLE
PS> Initialize-Provider @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"

.INPUTS
None. You cannot pipe objects to Initialize-Provider

.OUTPUTS
[bool]

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

There is no "Repository" parameter here like in Initialize-Module, instead it's called ProviderName
which is supplied in parameter FullyQualifiedName
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
#>
function Initialize-Provider
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initializenitialize-Provider.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[hashtable] $FullyQualifiedName,

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $Required
	)

	begin
	{
		# User prompt default values
		[int32] $Default = 0
		[ChoiceDescription[]] $Choices = @()
		$Accept = [ChoiceDescription]::new("&Yes")
		$Deny = [ChoiceDescription]::new("&No")
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

			# Out of date
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider $ProviderName v$TargetVersion found"
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider $ProviderName not installed"
		}

		# Check if provider could be downloaded
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if $ProviderName provider version >= v$RequireVersion is available for download"

		# NOTE: Find-Package searches registered package sources (registered with Register-PackageSource)
		# NOTE: Find-PackageProvider searches PowerShellGet (registered with PowerShellGet, that is Register-PSRepository) or Azure blob store
		# NOTE: If Nuget is not installed PowerShell will ask to install it here
		[Microsoft.PackageManagement.Packaging.SoftwareIdentity] $FoundProvider = Find-PackageProvider -Name $ProviderName `
			-MinimumVersion $RequireVersion -IncludeDependencies -ErrorAction SilentlyContinue

		if (!$FoundProvider)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Finding provider $ProviderName for download failed, trying alternative solution"
			# Try with Find-Package
			# NOTE: For some reason -AllowPrereleaseVersions may return no results
			$FoundProvider = Find-Package -Name $ProviderName -IncludeDependencies `
				-MinimumVersion $RequireVersion -ErrorAction SilentlyContinue # -AllowPrereleaseVersions
		}

		if ($FoundProvider)
		{
			if (($FoundProvider | Measure-Object).Count -gt 1)
			{
				# TODO: If there are multiple finds, selecting first one
				$FoundProvider = $FoundProvider[0]
				Write-Warning -Message "Found multiple sources for provider $($FoundProvider.Name), selecting first one"
			}

			Write-Information -Tags "User" -MessageData "INFO: Provider $($FoundProvider.Name) v$($FoundProvider.Version.ToString()) is selected for download"

			# TODO: If PowerShell asks to install NuGet during "Find-PackageProvider" and if that fails
			# it may return package source anyway (test with "Desktop" edition)
			# NOTE: This is controlled with powershell.promptToUpdatePackageManagement
			[Microsoft.PackageManagement.Packaging.PackageSource] $PackageSource = $FoundProvider | Get-PackageSource

			# If package source for "FoundProvider" is not registered do nothing, this will be the cause with
			# "Bootstrap" provider, which means NuGet was already installed during "Find-PackageProvider" above!
			if (!((Get-PackageSource).ProviderName -like "$($PackageSource.ProviderName)"))
			{
				Write-Warning -Message "Not using $($PackageSource.ProviderName) provider to install package, provider not registered"
				return $true
			}

			# Check package source is trusted
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if package source $($PackageSource.ProviderName) is trusted"

			if (!$PackageSource.IsTrusted)
			{
				# Setup choices
				$Accept.HelpMessage = "Setting $($PackageSource.Location) to trusted won't ask you in the future for confirmation"
				$Choices += $Accept
				$Choices += $Deny

				$Title = "Package source $($PackageSource.ProviderName) is not trusted"
				$Question = "Set $($PackageSource.ProviderName) as trusted now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					Set-PackageSource -Name $PackageSource.ProviderName -Trusted
					Write-Debug -Message "Package source $($PackageSource.ProviderName) set to trusted"
				}
			}

			Write-Information -Tags "User" -MessageData "INFO: Using following package sources: $($PackageSource.ProviderName)"
		}
		else
		{
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Write-Warning -Message "Provider $ProviderName was not found because of a known issue with PowerShell Core"
				Write-Information -Tags "User" -MessageData "INFO: see https://github.com/OneGet/oneget/issues/360"

				return !$Required
			}

			$Message = "$ProviderName provider version >= v$RequireVersion was not found"
			if ($Required)
			{
				# Registering repository failed or no valid repository exists
				Write-Error -Category ObjectNotFound -TargetObject $FullyQualifiedName -Message $Message
				return $false
			}

			Write-Warning -Message $Message
			return $true
		}

		# Setup prompt for installation/update
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
			# TODO: Use InputObject? after ensuring there aren't multiple provider names
			Install-PackageProvider -Name $FoundProvider.Name -Source $FoundProvider.Source

			[version] $NewVersion = Get-PackageProvider -Name $FoundProvider.Name |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			if ($NewVersion -and ($NewVersion -gt $TargetVersion))
			{
				Write-Information -Tags "User" -MessageData "INFO: $ProviderName provider v$NewVersion is installed"

				# Force, don't ask for confirmation
				Import-PackageProvider -Name $ProviderName -RequiredVersion $NewVersion -Force

				# If not imported into current session restart is required
				if ((Get-PackageProvider -Name $ProviderName).Version -lt $NewVersion)
				{
					# PowerShell needs to restart
					Set-Variable -Name Restart -Scope Script -Value $true

					Write-Warning -Message "$ProviderName provider v$NewVersion could not be imported, please restart PowerShell and try again"
					return $false
				}

				if ($ProviderName -eq "NuGet")
				{
					# PowerShell needs to restart
					Set-Variable -Name Restart -Scope Script -Value $true

					# Let other parts of a module know NuGet is up to date
					Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $true
				}

				return $true
			}
			else
			{
				$Message = "Module $ProviderName v$RequireVersion was not installed/updated"
				if ($Required)
				{
					# Installation/update failed
					Write-Error -Category NotInstalled -TargetObject $FullyQualifiedName -Message $Message
					return $false
				}

				Write-Warning -Message $Message
				return $true
			}
		}
		else
		{
			# User refused default action
			# TODO: should this be error? maybe switch
			Write-Warning -Message "Installing provider $ProviderName aborted by user"
			return !$Required
		}
	} # process
}

#
# Module variables
#

# Let other parts of a module know status about Nuget
Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $false

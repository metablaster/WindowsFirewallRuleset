
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
Update or install specified package providers

.DESCRIPTION
Initialize-Provider tests if specified package provider is installed and is up to date,
if not user is prompted to install or update it.
Outdated or missing package providers can cause strange issues, this function ensures that
specified package provider is installed, taking into account failures which can happen while
installing or updating package providers.

.PARAMETER ProviderName
Specifies a package provider name which to install or update.

.PARAMETER RequiredVersion
Specifies the exact version of the package provider which to install or update.

.PARAMETER UseProvider
Existing provider to use to install or update provider specified by -ProviderName parameter.
This parameter is used only if Find-PackageProvider fails, in which case Find-Package is used.
This provider is used to register package source specified by -Location if it isn't already
registered.
Acceptable values are: Bootstrap, NuGet or PowerShellGet.
The default value is PowerShellGet.

.PARAMETER Source
Specifies a web location of a package management source.

.PARAMETER InfoMessage
Optional information displayable to user for choice help message

.PARAMETER Required
Controls whether the provider initialization must succeed, if initialization fails execution stops
and false is returned, otherwise a warning is generated and true is returned.

.PARAMETER Scope
Specifies the installation scope of the provider.
The acceptable values for this parameter are:

AllUsers: $env:ProgramFiles\PackageManagement\ProviderAssemblies.
CurrentUser: $env:LOCALAPPDATA\PackageManagement\ProviderAssemblies.

The default value is AllUsers.

.EXAMPLE
PS> Initialize-Provider -ProviderName NuGet -RequiredVersion 2.8.5 -Required

.EXAMPLE
PS> Initialize-Provider -ProviderName NuGet -RequiredVersion 2.8.5 -Required `
-UseProvider NuGet -Location https://www.nuget.org/api/v2

.INPUTS
None. You cannot pipe objects to Initialize-Provider

.OUTPUTS
[bool]

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: -Force parameter not implemented because for most commandlets used in this function this
implies -ForceBootstrap which is not desired, few commandlets could make use of -Force

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Provider.md

.LINK
https://learn.microsoft.com/en-us/powershell/module/packagemanagement

.LINK
https://learn.microsoft.com/en-us/powershell/scripting/gallery/how-to/getting-support/bootstrapping-nuget

.LINK
https://learn.microsoft.com/en-us/powershell/scripting/gallery/installing-psget

.LINK
https://github.com/OneGet/oneget/issues/472

.LINK
https://github.com/OneGet/oneget/issues/360
#>
function Initialize-Provider
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Provider.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $ProviderName,

		[Parameter(Mandatory = $true)]
		[version] $RequiredVersion,

		[Parameter(Mandatory = $true, ParameterSetName = "UseProvider")]
		[ValidateSet("Bootstrap", "NuGet", "PowerShellGet")]
		[string] $UseProvider,

		[Parameter(ParameterSetName = "UseProvider")]
		[ValidatePattern("[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)")]
		[uri] $Source,

		[Parameter()]
		[string] $InfoMessage = "Accept operation",

		[Parameter()]
		[switch] $Required,

		[Parameter()]
		[ValidateSet("AllUsers", "CurrentUser")]
		[string] $Scope = "AllUsers",

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# User prompt default values
	# MSDN: The index of the label in the choices collection element to be presented to the user as the default choice.
	[int32] $Default = 0
	[ChoiceDescription[]] $Choices = @()
	$Accept = [ChoiceDescription]::new("&Yes")
	$Deny = [ChoiceDescription]::new("&No")

	#region CheckExisting
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if provider '$ProviderName' is installed and which version"

	# Highest version present on system if any
	[version] $InstalledVersion = Get-PackageProvider -Name $ProviderName -ListAvailable -ErrorAction SilentlyContinue |
	Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

	if ($InstalledVersion)
	{
		if ($InstalledVersion -ge $RequiredVersion)
		{
			if ($ProviderName -eq "NuGet")
			{
				# Let other parts of a module know NuGet is up to date
				Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $true
			}

			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Provider '$ProviderName' v$($InstalledVersion.ToString()) meets >= v$($RequiredVersion.ToString())"
			return $true
		}

		# Out of date
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Found outdated provider '$ProviderName' v$($InstalledVersion.ToString())"
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Provider '$ProviderName' not installed"
	}
	#endregion

	#region FindProvider
	# Check if provider could be downloaded
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if '$ProviderName' v$($RequiredVersion.ToString()) provider is available for download"

	# NOTE: Find-PackageProvider searches PowerShellGet (registered with PowerShellGet, that is Register-PSRepository)
	# MSDN: These are package providers available for installation with the Install-PackageProvider cmdlet.
	# Find-PackageProvider also finds matching Package Management providers that are available in the Package Management Azure Blob store.
	# Use the bootstrapper provider to find and install them.
	# TODO: We should use Register-PSRepository for manually specified repository here, for which a parameter needs to be implemented.
	# NOTE: If Nuget is not installed Windows PowerShell will ask to install it here and if accepted
	# $AllProviders will be initialized to downloaded and installed provider
	# TODO: Bootstraping should be handled manually
	[Microsoft.PackageManagement.Packaging.SoftwareIdentity[]] $AllProviders = Find-PackageProvider -Name $ProviderName `
		-RequiredVersion $RequiredVersion -IncludeDependencies -ErrorAction SilentlyContinue

	# If provider was found with Find-PackageProvider it should be installed with Install-PackageProvider
	$UseInstallPackageProvider = $true

	#region Find-Package
	if (($AllProviders | Measure-Object).Count -eq 0)
	{
		# If Find-PackageProvider failed an alternative solution is to use Find-Package
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Finding provider '$ProviderName' for download failed, trying alternative solution"

		# For Find-Package to work properly we need to ensure at least one package source exists
		# In addition we prompt user to optionally mark package sources as trusted.

		# Package sources name only list
		[string] $SourcesList = ""

		# MSDN: The Get-PackageSource cmdlet gets a list of package sources that are registered with PackageManagement on the local computer.
		# If you specify a package provider, Get-PackageSource gets only those sources that are associated with the specified provider.
		# Otherwise, the command returns all package sources that are registered with PackageManagement.
		[Microsoft.PackageManagement.Packaging.PackageSource[]] $PackageSources = Get-PackageSource -ErrorAction SilentlyContinue

		# Parameters for Find-Package
		$FindPackageParams = @{
			Name = $ProviderName
			IncludeDependencies = $true
			RequiredVersion = $RequiredVersion
			ErrorAction = "SilentlyContinue"
		}

		if ($Source)
		{
			if ($PackageSources -and ($Source -notin $PackageSources.Source))
			{
				# Register package source specified by Location
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Specified package source '$Source' is not registered"

				# Setup choices
				$Accept.HelpMessage = "Register '$Source' package source so that is can be used to search for providers"
				$Deny.HelpMessage = "Skip operation, '$Source' package source will not be registered nor used"
				$Choices = @()
				$Choices += $Accept
				$Choices += $Deny

				$Title = "Package source '$Source' is not registered"
				$Question = "Register '$Source' package source now?"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Registering package source '$Source'"
					Register-PackageSource -Name $Source -Location $Source -ProviderName $UseProvider

					# [Microsoft.PackageManagement.Packaging.PackageSource]
					$PackageSources = Get-PackageSource -Name $Source
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Package source '$Source' was registered with '$UseProvider' provider"
				}
				else
				{
					$PackageSources = $null
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Package source '$Source' was not registered and won't be used"
				}
			}
			else # Location already registered
			{
				# [Microsoft.PackageManagement.Packaging.PackageSource]
				$PackageSources = Get-PackageSource | Where-Object {
					$_.Location -eq $Source
				}
			}

			if ($PackageSources)
			{
				if (![string]::IsNullOrEmpty($UseProvider) -and ($PackageSources.ProviderName -ne $UseProvider))
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] The specified package provider '$UseProvider' was ignored because package source is already registered with '$($PackageSources.ProviderName)'"
				}

				$UseProvider = $PackageSources.ProviderName
				$FindPackageParams.Source = $PackageSources.Name
				$FindPackageParams.ProviderName = $UseProvider
			}
		}
		elseif (![string]::IsNullOrEmpty($UseProvider))
		{
			# [Microsoft.PackageManagement.Implementation.PackageProvider]
			$ExistingUseProvider = Get-PackageProvider -Name $UseProvider -ListAvailable -ErrorAction SilentlyContinue

			if ($ExistingUseProvider)
			{
				$UseProvider = $ExistingUseProvider
				$PackageSources = Get-PackageSource -ProviderName $UseProvider

				$FindPackageParams.Source = $PackageSources.Name
				$FindPackageParams.ProviderName = $UseProvider
			}
			else
			{
				Write-Error -Category ObjectNotFound -TargetObject $UseProvider `
					-Message "The specified provider '$UseProvider' is not installed"
			}
		}

		if (($PackageSources | Measure-Object).Count -ne 0)
		{
			# Check trust status of all package sources
			foreach ($SourceItem in $PackageSources)
			{
				if ($SourceItem.IsTrusted -ne "Trusted")
				{
					# Setup choices
					$Accept.HelpMessage = "Setting '$($SourceItem.Name)' to trusted won't ask you for confirmation to use it"
					$Deny.HelpMessage = "Leaving '$($SourceItem.Name)' as untrusted will ask you for confirmation to use it"
					$Choices = @()
					$Choices += $Accept
					$Choices += $Deny

					$Title = "Package source '$($SourceItem.Name)' is not trusted"
					$Question = "Set '$($SourceItem.Name)' as trusted now?"
					$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

					if ($Decision -eq $Default)
					{
						Set-PackageSource -Name $SourceItem.Name -Trusted | Out-Null
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source '$($SourceItem.Name)' set to trusted"
					}
					else
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source '$($SourceItem.Name)' not set to trusted"
					}
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Package source '$($SourceItem.Name)' already set to trusted"

				# Construct list for display on single line
				$SourcesList += "$($SourceItem.Name), "
			}

			$SourcesList = $SourcesList.TrimEnd(", ")

			if ($UseProvider -or $Source)
			{
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Searching '$UseProvider' provider with the following package sources: $SourcesList"
			}
			else
			{
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Searching the following package sources: $SourcesList"
			}

			# BUG: For some reason -AllowPrereleaseVersions may return no stable version
			# NOTE: Find-Package searches registered package sources (registered with Register-PackageSource)
			# [Microsoft.PackageManagement.Packaging.SoftwareIdentity[]]
			$AllProviders = Find-Package @FindPackageParams # -AllowPrereleaseVersions
		}
		else
		{
			# Not an error because PS may offer to install provider automatically,
			# ex. in Windows PS it will offer to install NuGet when using Find-PackageProvider
			Write-Warning -Message "[$($MyInvocation.InvocationName)] No registered package sources exist"
		}

		# Use Install-Package instead
		$UseInstallPackageProvider = $false
	}
	#endregion

	if (($AllProviders | Measure-Object).Count -ne 0)
	{
		# If there are multiple finds, selecting latest version
		# [Microsoft.PackageManagement.Packaging.SoftwareIdentity]
		$FoundProvider = $AllProviders | Sort-Object -Property Version | Select-Object -Last 1

		if (($AllProviders | Measure-Object).Count -gt 1)
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Found multiple '$($FoundProvider.Name)' providers, selecting latest version $($FoundProvider.Version)"
		}
		else
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Provider '$($FoundProvider.Name)' v$($FoundProvider.Version) is selected for download"
		}

		# TODO: If PowerShell asks to install NuGet during "Find-PackageProvider" and if that fails
		# it may return package source anyway (test with "Desktop" edition)
		# NOTE: This is controlled with powershell.promptToUpdatePackageManagement
		[Microsoft.PackageManagement.Packaging.PackageSource] $FoundPackageSource = $FoundProvider | Get-PackageSource

		# If package source for "FoundProvider" is not registered do nothing, this will be the cause with
		# "Bootstrap" provider, which means NuGet was already installed during "Find-PackageProvider" above!
		# It may also be the case if a user denied registering a package source.
		if ($FoundPackageSource.ProviderName -notin (Get-PackageSource).ProviderName)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Not using '$($FoundPackageSource.ProviderName)' provider to install package, package source not registered"

			# TODO: This scenario needs testing, it currently works for NuGet in Windows PowerShell
			return $null -ne (Get-PackageProvider -Name $ProviderName)
		}

		# Check package source is trusted
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if package source '$($FoundPackageSource.ProviderName)' is trusted"

		# This will be the case with package sources used by Find-PackageProvider
		# TODO: We handled package sources for Find-Package but not for Find-PackageProvider
		if (!$FoundPackageSource.IsTrusted)
		{
			# Setup choices
			$Accept.HelpMessage = "Setting '$($FoundPackageSource.Location)' to trusted won't ask you for confirmation to use it"
			$Deny.HelpMessage = "Leaving '$($FoundPackageSource.Location)' as untrusted will ask you for confirmation to use it"
			$Choices = @()
			$Choices += $Accept
			$Choices += $Deny

			$Title = "Package source '$($FoundPackageSource.ProviderName)' is not trusted"
			$Question = "Set '$($FoundPackageSource.ProviderName)' as trusted now?"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Set-PackageSource -Name $FoundPackageSource.ProviderName -Trusted | Out-Null
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Package provider '$($FoundPackageSource.ProviderName)' set to trusted"
			}
		}

		Write-Information -Tags $MyInvocation.InvocationName `
			-MessageData "INFO: Using '$($FoundPackageSource.ProviderName)' provider with the following package source: $($FoundPackageSource.Location)"
	}
	else
	{
		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# ISSUE: https://github.com/OneGet/oneget/issues/472
			# ISSUE: https://github.com/OneGet/oneget/issues/360
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Provider '$ProviderName' was not found probably because of a known issue present in PowerShell Core"
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: see https://github.com/OneGet/oneget/issues/472"

			return !$Required
		}

		$Message = "'$ProviderName' provider version >= v$($RequiredVersion.ToString()) was not found"
		if ($Required)
		{
			# Registering repository failed or no valid repository exists
			Write-Error -Category ObjectNotFound -TargetObject $ProviderName -Message $Message
			return $false
		}

		Write-Warning -Message "[$($MyInvocation.InvocationName)] $Message"
		return $true
	}
	#endregion

	#region Installation
	# Setup prompt for installation/update
	if (![string]::IsNullOrEmpty($InfoMessage))
	{
		$Accept.HelpMessage = $InfoMessage
	}

	$DesiredStatus = "Recommended"
	if ($Required)
	{
		$DesiredStatus = "Required"
	}

	if ($InstalledVersion)
	{
		$Deny.HelpMessage = "Abort operation, provider '$ProviderName' will not be updated"
		$Title = "$DesiredStatus package provider is out of date"
		$Question = "Update '$ProviderName' provider now?"
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Provider '$ProviderName' v$($InstalledVersion.ToString()) is out of date, $($DesiredStatus.ToLower()) version is $($RequiredVersion.ToString())"
	}
	else
	{
		$Deny.HelpMessage = "Abort operation, provider '$ProviderName' will not be installed"
		$Title = "$DesiredStatus package provider is not installed"
		$Question = "Install '$ProviderName' provider now?"
		Write-Warning -Message "[$($MyInvocation.InvocationName)] '$ProviderName' provider v$($RequiredVersion.ToString()) is $($DesiredStatus.ToLower()) but not installed"
	}

	$Choices = @()
	$Choices += $Accept
	$Choices += $Deny
	$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

	if ($Decision -eq $Default)
	{
		Write-Information -Tags $MyInvocation.InvocationName `
			-MessageData "INFO: Installing provider '$($FoundProvider.Name)' v$($FoundProvider.Version)"

		# TODO: Use InputObject?
		if ($UseInstallPackageProvider)
		{
			# -Source is the name of a registered repository
			Install-PackageProvider -Name $FoundProvider.Name -Source $FoundPackageSource.Name -Scope:$Scope
			$InstalledPackage = Get-PackageProvider -ListAvailable -Name $FoundProvider.Name |
			Where-Object {
				$_.Version -eq $RequiredVersion
			}
		}
		else
		{
			# -Source is the name of a registered package source
			Install-Package -Name $FoundProvider.Name -Source $FoundPackageSource.Name -Scope:$Scope | Out-Null
			$InstalledPackage = Get-Package -Name $FoundProvider.Name -RequiredVersion $RequiredVersion
		}

		[version] $NewVersion = $InstalledPackage | Select-Object -ExpandProperty Version

		if ($NewVersion -and ($NewVersion -gt $InstalledVersion))
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: '$ProviderName' provider v$($NewVersion.ToString()) was installed"

			if ($ProviderName -eq "NuGet")
			{
				# PowerShell needs to restart
				Set-Variable -Name Restart -Scope Script -Value $true

				# Let other parts of a module know NuGet is up to date
				Set-Variable -Name HasNuGet -Scope Script -Option ReadOnly -Force -Value $true
			}

			if ($UseInstallPackageProvider)
			{
				# Force, don't ask for confirmation
				Import-PackageProvider -Name $ProviderName -RequiredVersion $NewVersion -Force
				$ImportedPackage = Get-PackageProvider -Name $ProviderName | Where-Object {
					$_.Version -eq $RequiredVersion
				}
			}
			else
			{
				$ImportedPackage = Get-Package -Name $ProviderName -RequiredVersion $RequiredVersion
			}

			if (!$ImportedPackage)
			{
				# If not imported into current session restart is required
				Set-Variable -Name Restart -Scope Script -Value $true
				$Message = "'$ProviderName' provider v$($NewVersion.ToString()) could not be imported or used, please restart PowerShell and try again"

				if ($Required)
				{
					Write-Error -Category InvalidResult -TargetObject $ProviderName -Message $Message
				}
				else
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] $Message"
				}

				return $false
			}


			return $true
		}
		else
		{
			$Message = "Provider '$ProviderName' v$($RequiredVersion.ToString()) was not installed/updated"
			if ($Required)
			{
				# Installation/update failed
				Write-Error -Category NotInstalled -TargetObject $ProviderName -Message $Message
				return $false
			}

			Write-Warning -Message "[$($MyInvocation.InvocationName)] $Message"
			return $true
		}
	}
	else
	{
		# User refused default action
		if ($Required)
		{
			Write-Error -Category OperationStopped -TargetObject $ProviderName `
				-Message "Installing provider '$ProviderName' aborted by user"
		}
		else
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Installing provider '$ProviderName' aborted by user"
		}

		return !$Required
	}
	#endregion
}

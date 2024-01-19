
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Get Windows store app capabilities

.DESCRIPTION
Get-AppCapability returns a list of capabilities for an app in one of the following formats:
1. Principal display name
2. Principal full reference name

.PARAMETER Name
Specifies the name of a particular package.
If specified, function returns results for this package only.
Wildcards are permitted.

.PARAMETER PackageTypeFilter
Specifies the type of a packages to get from the package repository.

Valid values are:
Bundle
Framework
Main
Resource
None (default)

.PARAMETER InputObject
One or more Windows store apps for which to retrieve capabilities

.PARAMETER Domain
Computer name on which to run function

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER User
Specify user name for which to obtain store apps to query capabilities.

.PARAMETER IncludeAuthority
If specified, outputs full reference name.
By default only capability display name is returned.

.PARAMETER Networking
If specified, the result includes only networking capabilities

.EXAMPLE
PS> Get-AppxPackage -Name "*ZuneMusic*" | Get-AppCapability

Your Internet connection
Your home or work networks
Your music library
Removable storage

.EXAMPLE
PS> Get-AppCapability -IncludeAuthority -InputObject (Get-AppxPackage -Name "*ZuneMusic*") -Networking

APPLICATION PACKAGE AUTHORITY\Your Internet connection
APPLICATION PACKAGE AUTHORITY\Your home or work networks

.INPUTS
[object[]] Deserialized object on PowerShell Core 7.1+, otherwise
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]]

.OUTPUTS
[string] Capability names or full reference names for capabilities of an app

.NOTES
TODO: There are some capabilities not implemented here

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md

.LINK
https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations

.LINK
https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest

.LINK
https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/appxmanifestschema/element-capability

.LINK
https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-capability

.LINK
https://docs.microsoft.com/en-us/uwp/api/Windows.Management.Deployment.PackageTypes
#>
function Get-AppCapability
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md")]
	[OutputType([string])]
	param (
		[Parameter(Position = 0, ParameterSetName = "Name")]
		[SupportsWildcards()]
		[string] $Name = "*",

		[Parameter(ParameterSetName = "Name")]
		[ValidateSet("Bundle", "Framework", "Main", "Resource", "None", "Xap", "Optional")]
		[string] $PackageTypeFilter,

		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "InputObject")]
		[Alias("App", "StoreApp")]
		[object[]] $InputObject,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter(Mandatory = $true)]
		[string] $User,

		[Parameter()]
		[switch] $IncludeAuthority,

		[Parameter()]
		[switch] $Networking
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[hashtable] $SessionParams = @{}
		if ($Session)
		{
			$Domain = $Session.ComputerName
			$SessionParams.Session = $Session
		}
		else
		{
			$Domain = Format-ComputerName $Domain

			# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
			if ($Domain -ne [System.Environment]::MachineName)
			{
				$SessionParams.ComputerName = $Domain
				if ($Credential)
				{
					$SessionParams.Credential = $Credential
				}
			}
		}

		$InvocationName = $MyInvocation.InvocationName

		if ($PSCmdlet.ParameterSetName -eq "Name")
		{
			$AppxParams = @{
				Name = $Name

				# NOTE: Get-AppxPackage gets a list of the app packages that are installed in a user profile.
				# Also Get-AppxPackageManifest does for current user.
				# If no user is specified Get-AppxPackage and Get-AppxPackageManifest won't return anything from remote session
				# because for remote session we use virtual Admin for which there aren't any packages
				User = $User
			}

			if (![string]::IsNullOrEmpty($PackageTypeFilter))
			{
				$AppxParams.PackageTypeFilter = $PackageTypeFilter
			}

			if ($Domain -eq [System.Environment]::MachineName)
			{
				$InputObject = Get-AppxPackage @AppxParams
			}
			else
			{
				$InputObject = Invoke-Command @SessionParams -ArgumentList $AppxParams -ScriptBlock {
					param ([hashtable] $AppxParams)

					# TODO: This is temporary for debugging, appx should be imported in startup script
					if (($PSVersionTable.PSEdition -eq "Core") -and !(Get-Module -Name Appx -ErrorAction Ignore))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Appx module not imported into remote session"
					}

					# HACK: In remote Windows PowerShell this fails with "The system cannot find the file specified"
					Get-AppxPackage @AppxParams
				}
			}

			if ($null -eq $InputObject)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] No apps were retrieved to process for '$($AppxParams.Name)' app"
			}
		}
	}
	process
	{
		Invoke-Command @SessionParams -ArgumentList $InvocationName, $InputObject, $User, $Networking, $IncludeAuthority -ScriptBlock {
			param ([string] $InvocationName, $InputObject, $User, $Networking, $IncludeAuthority)

			# [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage]
			foreach ($StoreApp in $InputObject)
			{
				# Need a copy because of possible modification
				$App = $StoreApp
				[string[]] $OutputObject = @()
				Write-Verbose -Message "[$InvocationName] Processing store app: '$($App.Name)'"

				# TODO: Other store options are: None, Main, Framework, Resource, Bundle, Xap, Optional
				# NOTE: $App.IsFramework in not in the main store
				if ($App.IsBundle -or $App.IsResourcePackage) # -or $App.IsFramework
				{
					# If app was not obtained from the main store, get it from main store to be able to query package manifest
					Write-Verbose -Message "[$InvocationName] Input app is not from the main store, querying main store"
					$App = Get-AppxPackage -Name $App.Name -User $User -PackageTypeFilter Main

					if (!$App)
					{
						Write-Error -Category ObjectNotFound -TargetObject $StoreApp `
							-Message "The app $($StoreApp.Name) not found in the main store, unable to query package manifest"
						continue
					}
				}

				Write-Debug -Message "[$InvocationName] Getting package manifest for '$($App.Name)'"
				$PackageManifest = $App | Get-AppxPackageManifest -User $User

				if (!$PackageManifest)
				{
					Write-Warning -Message "[$InvocationName] Store app '$($App.Name)' is missing package manifest"
					continue
				}
				elseif ($null -eq ($PackageManifest | Select-Object -ExpandProperty Package))
				{
					# NOTE: This may be the cause with Microsoft account (non local Windows account)
					Write-Warning -Message "[$InvocationName] Store app '$($App.Name)' is missing manifest 'Package' property"
					continue
				}

				$Package = $PackageManifest.Package
				if (!$Package.PSObject.Properties.Name.Contains("Capabilities"))
				{
					Write-Verbose -Message "[$InvocationName] Store app '$($App.Name)' has no capabilities"
					continue
				}
				elseif (!$Package.Capabilities.PSObject.Properties.Name.Contains("Capability"))
				{
					Write-Verbose -Message "[$InvocationName] Store app '$($App.Name)' is missing capabilities"
					continue
				}

				Write-Debug -Message "[$InvocationName] Resolving capabilities for '$($App.Name)'"
				[string[]] $AppCapabilities = ($Package.Capabilities | Select-Object -ExpandProperty Capability).Name

				foreach ($Capability in $AppCapabilities)
				{
					# NOTE: -Debug:$false to avoid spaming the console
					Write-Debug -Message "[$InvocationName] Processing capability: '$Capability'" -Debug:$false

					[string] $DisplayName = switch ($Capability)
					{
						# Networking capabilities
						# TODO: Unknown display name
						"runFullTrust" { "runFullTrust" }
						"internetClient" { "Your Internet connection"; break }
						"internetClientServer" { "Your Internet connection, including incoming connections from the Internet"; break }
						"privateNetworkClientServer" { "Your home or work networks"; break }
						default
						{
							if ($Networking)
							{
								break
							}

							switch ($Capability)
							{
								"picturesLibrary" { "Your pictures library"; break }
								"videosLibrary" { "Your videos library"; break }
								"musicLibrary" { "Your music library"; break }
								"documentsLibrary" { "Your documents library"; break }
								# TODO: there are multiple capabilities that could match this?
								"enterpriseAuthentication" { "Your Windows credentials" }
								"sharedUserCertificates" { "Software and hardware certificates or a smart card"; break }
								"removableStorage" { "Removable storage"; break }
								"appointments" { "Your Appointments"; break }
								"contacts" { "Your Contacts"; break }
								default
								{
									Write-Debug -Message "[$InvocationName] Getting displayname for '$Capability' capability not implemented"
								}
							}
						}
					}

					if ([string]::IsNullOrEmpty($DisplayName))
					{
						# NOTE: -Debug:$false to avoid spaming the console
						Write-Debug -Message "[$InvocationName] Capability: '$Capability' not resolved" -Debug:$false
						continue
					}
					elseif ($IncludeAuthority)
					{
						$OutputObject += ("APPLICATION PACKAGE AUTHORITY\" + $DisplayName)
					}
					else
					{
						$OutputObject += $DisplayName
					}
				} # foreach capability

				Write-Output $OutputObject
			} # foreach app
		} # invoke-command
	} # process
}

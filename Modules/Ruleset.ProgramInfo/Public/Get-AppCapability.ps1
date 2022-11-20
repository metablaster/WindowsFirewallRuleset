
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
Specifies one or more comma-separated types of packages to gets from the package repository.
If not specified processes only packages of types Main and Framework.

Valid values are:
Bundle
Framework
Main
Resource
None

.PARAMETER InputObject
One or more Windows store apps for which to retrieve capabilities

.PARAMETER Domain
Computer name which to check

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER User
Specify user name for which to query app capabilities.
This parameter is required only if input app or the app specified by -Name parameter is
not from the main store.

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
TODO: According to unit test there are some capabilities not implemented here
HACK: Parameter set names for ComputerName vs Session

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
		[ValidateSet("Bundle", "Framework", "Main", "Resource", "None", "Xap")]
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

		[Parameter()]
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
			# Get it from main store to be able to query package manifest
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Getting app from main store"

			$AppxParams = @{
				Name = $Name
			}

			if (![string]::IsNullOrEmpty($PackageTypeFilter))
			{
				$AppxParams["PackageTypeFilter"] = $PackageTypeFilter
			}

			if (![string]::IsNullOrEmpty($User))
			{
				$AppxParams["User"] = $User
			}

			if ($Domain -eq [System.Environment]::MachineName)
			{
				# HACK: module not imported, need to import manually
				Import-WinModule -Name Appx -ErrorAction Stop
				$InputObject = Get-AppxPackage @AppxParams
			}
			else
			{
				# HACK: No apps are returned from remote
				$InputObject = Invoke-Command @SessionParams -ArgumentList $AppxParams -ScriptBlock {
					param ([hashtable] $AppxParams)

					Get-AppxPackage @AppxParams
				}
			}
		}
	}
	process
	{
		# HACK: Cannot use @SessionParams, no return value
		Invoke-Command @SessionParams -ArgumentList $InvocationName -ScriptBlock {
			param ([string] $InvocationName)

			foreach ($StoreApp in $using:InputObject)
			{
				# Need a copy because of possible modification
				# [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage]
				$App = $StoreApp
				[string[]] $OutputObject = @()
				Write-Verbose -Message "[$InvocationName] Processing store app: '$($App.Name)'"

				if ($App.IsBundle -or $App.IsResourcePackage -or $App.IsFramework)
				{
					if ([string]::IsNullOrEmpty($using:User))
					{
						Write-Error -Category InvalidArgument -TargetObject "User" `
							-Message "The app '$($App.Name)' is not from the main store, please specify 'User' parameter"
						continue
					}

					# If input app was not obtained from main store, get it from main store to be able to query package manifest
					Write-Debug -Message "[$InvocationName] Input app is not from the main store, querying main store"
					$App = Get-AppxPackage -Name $App.Name -User $using:User -PackageTypeFilter Main

					if (!$App)
					{
						Write-Error -Category ObjectNotFound -TargetObject $StoreApp `
							-Message "The app $($StoreApp.Name) not found in main store, unable to query package manifest"
						continue
					}

					Write-Debug -Message "[$InvocationName] Getting package manifest for $($App.Name) user $using:User"
					# [System.XML.XMLDocument]
					$PackageManifest = $App | Get-AppxPackageManifest -User $using:User
				}
				else
				{
					Write-Debug -Message "[$InvocationName] Getting package manifest for $($App.Name)"
					$PackageManifest = $App | Get-AppxPackageManifest
				}

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
					Write-Verbose -Message "[$InvocationName] Store app '$($App.Name) has no capabilities"
					continue
				}
				elseif (!$Package.Capabilities.PSObject.Properties.Name.Contains("Capability"))
				{
					Write-Verbose -Message "[$InvocationName] Store app '$($App.Name) is missing capabilities"
					continue
				}

				[string[]] $AppCapabilities = ($Package.Capabilities | Select-Object -ExpandProperty Capability).Name

				foreach ($Capability in $AppCapabilities)
				{
					Write-Debug -Message "[$InvocationName] Processing capability: '$Capability'"

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
							if ($using:Networking)
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
									Write-Error -Category NotImplemented -TargetObject $Capability `
										-Message "Getting capability for '$Capability' not implemented"
								}
							}
						}
					}

					if ([string]::IsNullOrEmpty($DisplayName))
					{
						Write-Debug -Message "[$InvocationName] Capability: '$Capability' not resolved"
						continue
					}
					else
					{
						Write-Debug -Message "[$InvocationName] Capability: '$Capability' resolved to: $DisplayName"

						if ($using:IncludeAuthority)
						{
							$OutputObject += ("APPLICATION PACKAGE AUTHORITY\" + $DisplayName)
						}
						else
						{
							$OutputObject += $DisplayName
						}
					}
				} # foreach capability

				Write-Output $OutputObject
			} # foreach app
		} # invoke-command
	} # process
}


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

<#
.SYNOPSIS
Get capabilities of Windows store app

.DESCRIPTION
Get-AppCapability returns a list of capabilities for an app in one of the following formats:
2. Account display name
3. Account full reference name

.PARAMETER InputObject
One or more Windows store apps for which to retrieve capabilities

.PARAMETER User
Specify user name for which to query app capabilities, this parameter
is required only if input app is not obtained from main store

.PARAMETER Authority
If specified outputs full reference name

.PARAMETER Networking
If specified the result includes only networking capabilities

.EXAMPLE
PS> Get-AppxPackage -Name "*ZuneMusic*" | Get-AppCapability

Your Internet connection
Your home or work networks
Your music library
Removable storage

.EXAMPLE
PS> Get-AppCapability -Authority -InputObject (Get-AppxPackage -Name "*ZuneMusic*") -Networking

APPLICATION PACKAGE AUTHORITY\Your Internet connection
APPLICATION PACKAGE AUTHORITY\Your home or work networks

.INPUTS
[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]]

.OUTPUTS
[string] Capability names or full reference names for capabilities of an app

.NOTES
None.

.LINK
https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations

.LINK
https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest
#>
function Get-AppCapability
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md")]
	[OutputType([string])]
	param (
		[Alias("App", "StoreApp")]
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]] $InputObject,

		[Parameter(Mandatory = $false)]
		[string] $User,

		[Parameter()]
		[switch] $Authority,

		[Parameter()]
		[switch] $Networking
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($StoreApp in $InputObject)
		{
			# Need a copy because of possible modification
			$App = $StoreApp

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing store app: '$($App.Name)'"

			[string[]] $OutputObject = @()

			if ($App.IsBundle -or $App.IsResourcePackage -or $App.IsFramework)
			{
				if ([string]::IsNullOrEmpty($User))
				{
					Write-Error -Category InvalidArgument -TargetObject $User `
						-Message "The app '$($StoreApp.Name)' is not from the main store, please specify 'User' parameter"
					continue
				}

				# If input app was not obtained from main store, get it from main store to be able to query package manifest
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Input app is not from main store, querying main store"
				$App = Get-AppxPackage -User $User -PackageTypeFilter Main -Name $StoreApp.Name

				if (!$App)
				{
					Write-Error -Category ObjectNotFound -TargetObject $StoreApp `
						-Message "The app $($StoreApp.Name) not found in main store, unable to query package manifest"
					continue
				}

				$PackageManifest = ($App | Get-AppxPackageManifest -User $User).Package
			}
			else
			{
				$PackageManifest = ($App | Get-AppxPackageManifest).Package
			}

			if (!$PackageManifest.PSObject.Properties.Name.Contains("Capabilities"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Store app '$($App.Name) has no capabilities"
				continue
			}
			elseif (!$PackageManifest.Capabilities.PSObject.Properties.Name.Contains("Capability"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Store app '$($App.Name) is missing capabilities"
				continue
			}

			[string[]] $AppCapabilities = ($PackageManifest.Capabilities | Select-Object -ExpandProperty Capability).Name

			foreach ($Capability in $AppCapabilities)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing capability: '$Capability'"

				[string] $Name = ""

				$Name = switch ($Capability)
				{
					"internetClient" { "Your Internet connection" }
					"internetClientServer" { "Your Internet connection, including incoming connections from the Internet" }
					"privateNetworkClientServer" { "Your home or work networks" }
					default
					{
						if ($Networking)
						{
							break
						}

						switch ($Capability)
						{
							"picturesLibrary" { "Your pictures library" }
							"videosLibrary" { "Your videos library" }
							"musicLibrary" { "Your music library" }
							"documentsLibrary" { "Your documents library" }
							# TODO: there are multiple capabilities that could match this
							# "" { "Your Windows credentials" }
							"sharedUserCertificates" { "Software and hardware certificates or a smart card" }
							"removableStorage" { "Removable storage" }
							"appointments" { "Your Appointments" }
							"contacts" { "Your Contacts" }
							default
							{
								Write-Error -Category NotImplemented -TargetObject $Capability `
									-Message "Getting capability for '$Capability' not implemented"
							}
						}
					}
				}

				if ([string]::IsNullOrEmpty($Name))
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Capability: '$Capability' not resolved"
					continue
				}
				else
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Capability: '$Capability' resolved to: $Name"
				}

				if ($Authority)
				{
					$OutputObject += ("APPLICATION PACKAGE AUTHORITY\" + $Name)
				}
				else
				{
					$OutputObject += $Name
				}
			} # foreach capability

			Write-Output $OutputObject
		} # foreach app
	} # process
}

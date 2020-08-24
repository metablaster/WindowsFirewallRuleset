
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
. $PSScriptRoot\..\ModulePreferences.ps1

<#
.SYNOPSIS
Get localhost name
.DESCRIPTION
TODO: add description
.EXAMPLE
Get-ComputerName
.INPUTS
None. You cannot pipe objects to Get-ComputerName
.OUTPUTS
[string] computer name in form of COMPUTERNAME
.NOTES
TODO: implement querying computers on network by specifying IP address
#>
function Get-ComputerName
{
	[OutputType([string])]
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$ComputerName = [System.Environment]::MachineName
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Learning computer name: $ComputerName"

	return $ComputerName
}

<#
.SYNOPSIS
Method to get configured adapters
.DESCRIPTION
Return list of all configured adapters and their configuration.
Applies to adapters which have an IP assigned regardless if connected to network.
This conditionally includes virtual and hidden adapters such as Hyper-V adapters on all compartments.
.PARAMETER AddressFamily
IP version for which to obtain adapters, IPv4 or IPv6
.PARAMETER ExcludeHardware
Exclude hardware/physical network adapters
.PARAMETER IncludeAll
Include all possible adapter types present on target computer
.PARAMETER IncludeVirtual
Whether to include virtual adapters
.PARAMETER IncludeHidden
Whether to include hidden adapters
.PARAMETER IncludeDisconnected
Whether to include disconnected
.EXAMPLE
Get-ConfiguredAdapter "IPv4"
.EXAMPLE
Get-ConfiguredAdapter "IPv6"
.INPUTS
None. You cannot pipe objects to Get-ConfiguredAdapter
.OUTPUTS
[NetIPConfiguration] or error message if no adapter configured
.NOTES
TODO: Loopback interface is missing in the output
#>
function Get-ConfiguredAdapter
{
	# TODO: doesn't work [OutputType([System.Net.NetIPConfiguration])]
	[CmdletBinding(DefaultParameterSetName = "Individual")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("IPv4", "IPv6")]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[string] $AddressFamily,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($AddressFamily.ToString() -eq "IPv4")
	{
		if ($IncludeDisconnected -or $IncludeAll)
		{
			$AllConfiguredAdapters = Get-NetIPConfiguration -AllCompartments | Where-Object -Property IPv4Address
		}
		else
		{
			$AllConfiguredAdapters = Get-NetIPConfiguration -AllCompartments | Where-Object {
				$_.IPv4Address -and $_.IPv4DefaultGateway
			}
		}
	}
	else
	{
		if ($IncludeDisconnected -or $IncludeAll)
		{
			$AllConfiguredAdapters = Get-NetIPConfiguration -AllCompartments | Where-Object -Property IPv6Address
		}
		else
		{
			$AllConfiguredAdapters = Get-NetIPConfiguration -AllCompartments | Where-Object {
				$_.IPv6Address -and $_.IPv6DefaultGateway
			}
		}
	}

	if (!$AllConfiguredAdapters)
	{
		Write-Error -Category ObjectNotFound -TargetObject "AllConfiguredAdapters" `
			-Message "None of the adapters is configured for $AddressFamily"
		return $null
	}

	# Get-NetIPConfiguration does not tell us adapter type (hardware, hidden or virtual)
	[PSCustomObject[]] $RequestedAdapters = @()
	if (!$ExcludeHardware)
	{
		$RequestedAdapters = Get-NetAdapter |
		Where-Object { $_.HardwareInterface -eq "True" }
	}

	# Include virtual or hidden to hardware interfaces
	if ($IncludeVirtual -or $IncludeAll)
	{
		$RequestedAdapters += Get-NetAdapter |
		Where-Object { $_.Virtual -eq "True" }
	}
	if ($IncludeHidden -or $IncludeAll)
	{
		$RequestedAdapters += Get-NetAdapter -IncludeHidden |
		Where-Object { $_.Hidden -eq "True" }
	}

	if (!$RequestedAdapters)
	{
		Write-Error -Category ObjectNotFound -TargetObject "RequestedAdapters" `
			-Message "None of the adapters matches search criteria for $AddressFamily"
		return $null
	}

	[Uint32[]] $ValidAdapters = $RequestedAdapters | Select-Object -ExpandProperty ifIndex

	$ConfiguredAdapters = @()
	if (![string]::IsNullOrEmpty($ValidAdapters))
	{
		$ConfiguredAdapters = $AllConfiguredAdapters | Where-Object {
			[array]::Find($ValidAdapters, [System.Predicate[Uint32]] { $_.InterfaceIndex -eq $args[0] })
		}
	}

	$Count = ($ConfiguredAdapters | Measure-Object).Count
	if ($Count -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject "ConfiguredAdapters" `
			-Message "None of the adapters is configured for $AddressFamily with given criteria"
	}
	elseif ($Count -gt 1)
	{
		Write-Information -Tags "User" -MessageData "INFO: Multiple adapters are configured for $AddressFamily"
	}

	return $ConfiguredAdapters
}

<#
.SYNOPSIS
Method to get aliases of configured adapters
.DESCRIPTION
Return list of interface aliases of all configured adapters.
Applies to adapters which have an IP assigned regardless if connected to network.
This may include virtual adapters as well such as Hyper-V adapters on all compartments.
.PARAMETER AddressFamily
IP version for which to obtain adapters, IPv4 or IPv6
.PARAMETER IncludeAll
Include all possible adapter types present on target computer
.PARAMETER IncludeVirtual
Whether to include virtual adapters
.PARAMETER IncludeHidden
Whether to include hidden adapters
.PARAMETER IncludeDisconnected
Whether to include disconnected
.EXAMPLE
Get-InterfaceAlias "IPv4"
.EXAMPLE
Get-InterfaceAlias "IPv6"
.INPUTS
None. You cannot pipe objects to Get-InterfaceAlias
.OUTPUTS
WildcardPattern[] Array of interface aliases
.NOTES
None.
#>
function Get-InterfaceAlias
{
	[OutputType([System.Management.Automation.WildcardPattern[]])]
	[CmdletBinding(DefaultParameterSetName = "Individual")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("IPv4", "IPv6")]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[string] $AddressFamily,

		[Parameter(Mandatory = $false)]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[System.Management.Automation.WildcardOptions]
		$WildCardOption = [System.Management.Automation.WildcardOptions]::None,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($IncludeAll)
	{
		$ConfiguredInterfaces = Get-ConfiguredAdapter $AddressFamily `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredInterfaces = Get-ConfiguredAdapter $AddressFamily `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	if (!$ConfiguredInterfaces)
	{
		# NOTE: Error should be generated and shown by Get-ConfiguredAdapter
		return $null
	}

	[string[]] $InterfaceAliases = $ConfiguredInterfaces | Select-Object -ExpandProperty InterfaceAlias
	if ($InterfaceAliases.Length -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $InterfaceAliases `
			-Message "None of the adapters matches search criteria to get interface aliases from"
		return
	}

	[WildcardPattern[]] $InterfaceAliasPattern = @()
	foreach ($Alias in $InterfaceAliases)
	{
		if ([WildcardPattern]::ContainsWildcardCharacters($Alias))
		{
			Write-Warning -Message "$Alias Interface alias contains wildcard pattern"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Interface alias '$Alias' does not contain wildcard pattern"
		}

		$InterfaceAliasPattern += [WildcardPattern]::new($Alias, $WildCardOption)
	}

	if ($InterfaceAliasPattern.Length -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $InterfaceAliasPattern `
			-Message "Creating interface alias patterns failed"
	}
	elseif ($InterfaceAliasPattern.Length -gt 1)
	{
		Write-Information -Tags "User" -MessageData "INFO: Got multiple adapter aliases"
	}

	return $InterfaceAliasPattern
}

<#
.SYNOPSIS
Method to get list of IP addresses on local machine
.DESCRIPTION
Returns list of IP addresses for all adapters connected to network
Return list of IP addresses for all configured adapter.
This includes both physical and virtual adapters.
.PARAMETER AddressFamily
IP version for which to obtain address, IPv4 or IPv6
.PARAMETER IncludeAll
Include all possible adapter types present on target computer
.PARAMETER IncludeVirtual
Whether to include virtual adapters
.PARAMETER IncludeHidden
Whether to include hidden adapters
.PARAMETER IncludeDisconnected
Whether to include disconnected
.EXAMPLE
Get-IPAddress "IPv4"
.EXAMPLE
Get-IPAddress "IPv6"
.INPUTS
None. You cannot pipe objects to Get-IPAddress
.OUTPUTS
[IPAddress[]] Array of IP addresses  and warning message if no adapter connected
.NOTES
None.
#>
function Get-IPAddress
{
	[OutputType([System.Net.IPAddress[]])]
	[CmdletBinding(DefaultParameterSetName = "Individual")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("IPv4", "IPv6")]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[string] $AddressFamily,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting IP's of connected adapters for $AddressFamily network"

	if ($IncludeAll)
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter $AddressFamily `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter $AddressFamily `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	[IPAddress[]] $IPAddress = $ConfiguredAdapters |
	Select-Object -ExpandProperty ($AddressFamily + "Address") |
	Select-Object -ExpandProperty IPAddress

	$Count = ($IPAddress | Measure-Object).Count
	if ($Count -gt 1)
	{
		# TODO: bind result to custom function
		Write-Information -Tags "Result" -MessageData "INFO: Computer has multiple IP addresses: $IPAddress"
	}
	elseif ($Count -eq 0)
	{
		Write-Warning -Message "Computer not connected to $AddressFamily network, IP address will be missing"
	}

	return $IPAddress
}

<#
.SYNOPSIS
Method to get broadcast addresses on local machine
.DESCRIPTION
Return multiple broadcast addresses, for each configured adapter.
This includes both physical and virtual adapters.
Returned broadcast addresses are only for IPv4
.PARAMETER IncludeAll
Include all possible adapter types present on target computer
.PARAMETER IncludeVirtual
Whether to include virtual adapters
.PARAMETER IncludeHidden
Whether to include hidden adapters
.PARAMETER IncludeDisconnected
Whether to include disconnected
.EXAMPLE
Get-Broadcast
.INPUTS
None. You cannot pipe objects to Get-Broadcast
.OUTPUTS
[IPAddress[]] Array of broadcast addresses
#>
function Get-Broadcast
{
	[OutputType([System.Net.IPAddress[]])]
	[CmdletBinding(DefaultParameterSetName = "Individual")]
	param (
		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting broadcast address of connected adapters"

	# Broadcast address makes sense only for IPv4
	if ($IncludeAll)
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter IPv4 `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter IPv4 `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	$ConfiguredAdapters = $ConfiguredAdapters | Select-Object -ExpandProperty IPv4Address
	$Count = ($ConfiguredAdapters | Measure-Object).Count

	if ($Count -gt 0)
	{
		[IPAddress[]] $Broadcast = @()
		foreach ($Adapter in $ConfiguredAdapters)
		{
			[IPAddress] $IPAddress = $Adapter | Select-Object -ExpandProperty IPAddress
			$SubnetMask = ConvertTo-Mask ($Adapter | Select-Object -ExpandProperty PrefixLength)

			$Broadcast += Get-NetworkSummary $IPAddress $SubnetMask |
			Select-Object -ExpandProperty BroadcastAddress |
			Select-Object -ExpandProperty IPAddressToString
		}

		Write-Information -Tags "Result" -MessageData "INFO: Network broadcast addresses are: $Broadcast"
		return $Broadcast
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] returns null"
}

<#
.SYNOPSIS
Get operating system SKU information
.DESCRIPTION
Get the SKU (Stock Keeping Unit) information for one or multiple target computers,
or translate SKU number to SKU
.PARAMETER SKU
Operating system SKU number, can't be used with ComputerName parameter
.PARAMETER ComputerName
One or more computer names, can't be used with SKU parameter
.EXAMPLE
PS> Get-SystemSKU
Home Premium N
.INPUTS
None. You cannot pipe objects to Get-SystemSKU
.OUTPUTS
[PSCustomObject[]] array with Computer/SKU value pairs
.NOTES
TODO: accept UPN and NETBIOS computer names
TODO: ComputerName default value is just a placeholder to be able to use foreach
which is needed for pipeline, need better design
#>
function Get-SystemSKU
{
	[OutputType([PSCustomObject[]])]
	[CmdletBinding(PositionalBinding = $false)]
	param(
		[Parameter(ValueFromPipeline = $true, ParameterSetName = "Number")]
		[ValidatePattern("^[0-9]+$")]
		[int32] $SKU,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(ValueFromPipeline = $true, ParameterSetName = "Computer")]
		[string[]] $ComputerName = [System.Environment]::MachineName
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values)) $($PSBoundParameters.Values | Get-TypeName)"

		# Unknown if input is SKU number
		[string] $TargetComputer = ""
		[PSCustomObject[]] $Result = @()

		foreach ($Computer in $ComputerName)
		{
			if ($SKU)
			{
				$CimSKU = $SKU
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing SKU: $SKU"
			}
			else
			{
				$CimSKU = $null
				$TargetComputer = $Computer
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing computer: $Computer"

				if (Test-TargetComputer $Computer)
				{
					$CimSKU = Get-CimInstance -Class Win32_OperatingSystem -ComputerName $Computer `
						-OperationTimeoutSec $ConnectionTimeout -Namespace "root\cimv2" |
					Select-Object -ExpandProperty OperatingSystemSku
				}

				if (!$CimSKU)
				{
					# TODO: error should be shown by Get-CimInstance
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Failed getting SKU info from CIM server"

					# Include just computer
					$Result += [PSCustomObject] @{
						Computer = $Computer
						SKU = ""
					}

					continue
				}
			}

			[string] $StringSKU = switch ($CimSKU)
			{
				0 { "An unknown product"; break; }
				1 { "Ultimate"; break; }
				2 { "Home Basic"; break; }
				3 { "Home Premium"; break; }
				4 { "Enterprise"; break; }
				5 { "Home Basic N"; break; }
				6 { "Business"; break; }
				7 { "Server Standard"; break; }
				8 { "Server Datacenter (full installation)"; break; }
				9 { "Windows Small Business Server"; break; }
				10 { "Server Enterprise (full installation)"; break; }
				11 { "Starter"; break; }
				12 { "Server Datacenter (core installation)"; break; }
				13 { "Server Standard (core installation)"; break; }
				14 { "Server Enterprise (core installation)"; break; }
				15 { "Server Enterprise for Itanium-based Systems"; break; }
				16 { "Business N"; break; }
				17 { "Web Server (full installation)"; break; }
				18 { "HPC Edition"; break; }
				19 { "Windows Storage Server 2008 R2 Essentials"; break; }
				20 { "Storage Server Express"; break; }
				21 { "Storage Server Standard"; break; }
				22 { "Storage Server Workgroup"; break; }
				23 { "Storage Server Enterprise"; break; }
				24 { "Windows Server 2008 for Windows Essential Server Solutions"; break; }
				25 { "Small Business Server Premium"; break; }
				26 { "Home Premium N"; break; }
				27 { "Enterprise N"; break; }
				28 { "Ultimate N"; break; }
				29 { "Web Server (core installation)"; break; }
				30 { "Windows Essential Business Server Management Server"; break; }
				31 { "Windows Essential Business Server Security Server"; break; }
				32 { "Windows Essential Business Server Messaging Server"; break; }
				33 { "Server Foundation"; break; }
				34 { "Windows Home Server 2011"; break; }
				35 { "Windows Server 2008 without Hyper-V for Windows Essential Server Solutions"; break; }
				36 { "Server Standard without Hyper-V"; break; }
				37 { "Server Datacenter without Hyper-V (full installation)"; break; }
				38 { "Server Enterprise without Hyper-V (full installation)"; break; }
				39 { "Server Datacenter without Hyper-V (core installation)"; break; }
				40 { "Server Standard without Hyper-V (core installation)"; break; }
				41 { "Server Enterprise without Hyper-V (core installation)"; break; }
				42 { "Microsoft Hyper-V Server"; break; }
				43 { "Storage Server Express (core installation)"; break; }
				44 { "Storage Server Standard (core installation)"; break; }
				45 { "Storage Server Workgroup (core installation)"; break; }
				46 { "Storage Server Enterprise (core installation)"; break; }
				46 { "Storage Server Enterprise (core installation)"; break; }
				47 { "Starter N"; break; }
				48 { "Professional"; break; }
				49 { "Professional N"; break; }
				50 { "Windows Small Business Server 2011 Essentials"; break; }
				51 { "Server For SB Solutions"; break; }
				52 { "Server Solutions Premium"; break; }
				53 { "Server Solutions Premium (core installation)"; break; }
				54 { "Server For SB Solutions EM"; break; }
				55 { "Server For SB Solutions EM"; break; }
				56 { "Windows MultiPoint Server"; break; }
				59 { "Windows Essential Server Solution Management"; break; }
				60 { "Windows Essential Server Solution Additional"; break; }
				61 { "Windows Essential Server Solution Management SVC"; break; }
				62 { "Windows Essential Server Solution Additional SVC"; break; }
				63 { "Small Business Server Premium (core installation)"; break; }
				64 { "Server Hyper Core V"; break; }
				72 { "Server Enterprise (evaluation installation)"; break; }
				76 { "Windows MultiPoint Server Standard (full installation)"; break; }
				77 { "Windows MultiPoint Server Premium (full installation)"; break; }
				79 { "Server Standard (evaluation installation)"; break; }
				80 { "Server Datacenter (evaluation installation)"; break; }
				84 { "Enterprise N (evaluation installation)"; break; }
				95 { "Storage Server Workgroup (evaluation installation)"; break; }
				96 { "Storage Server Standard (evaluation installation)"; break; }
				98 { "Windows 8 N"; break; }
				99 { "Windows 8 China"; break; }
				100 { "Windows 8 Single Language"; break; }
				101 { "Windows 8"; break; }
				103 { "Professional with Media Center"; break; }

				default
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Input SKU not recognized"
					"" # SKU unknown
				}
			} # switch SKU

			if ([string]::IsNullOrEmpty($StringSKU))
			{
				Write-Error -Category ObjectNotFound -TargetObject $CimSKU `
					-Message "Unknown SKU: + $($CimSKU.ToString())"
				continue
			}

			$Result += [PSCustomObject] @{
				Computer = $TargetComputer
				SKU = $StringSKU
			}
		} # foreach computer

		Write-Output $Result
	} # process
}

<#
.SYNOPSIS
Test target computer (policy store) on which to apply firewall
.DESCRIPTION
The purpose of this function is to reduce typing checks depending on whether PowerShell
core or desktop edition is used, since parameters for Test-Connection are not the same
for both PowerShell editions.
.PARAMETER ComputerName
Target computer which to test
.PARAMETER Count
Valid only for PowerShell Core. Specifies the number of echo requests to send. The default value is 4
.PARAMETER Timeout
Valid only for PowerShell Core. The test fails if a response isn't received before the timeout expires
.EXAMPLE
Test-TargetComputer "COMPUTERNAME" 2 1
.EXAMPLE
Test-TargetComputer "COMPUTERNAME"
.INPUTS
None. You cannot pipe objects to Test-TargetMachine
.OUTPUTS
[bool] false or true if target host is responsive
.NOTES
TODO: avoid error message, check all references which handle errors (code bloat)
TODO: this should probably be part of ComputerInfo module
#>
function Test-TargetComputer
{
	[OutputType([bool])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(Mandatory = $true,
			Position = 0)]
		[string] $ComputerName,

		[Parameter()]
		[int16] $Count = $ConnectionCount,

		[Parameter()]
		[int16] $Timeout = $ConnectionTimeout
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Information -Tags "User" -MessageData "INFO: Contacting computer $ComputerName"

	# Test parameters depend on PowerShell edition
	# TODO: changes not reflected in calling code
	# NOTE: Don't suppress error, error details can be of more use than just "unable to contact computer"
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		return Test-Connection -TargetName $ComputerName -Count $Count -TimeoutSeconds $Timeout -IPv4 -Quiet
	}

	return Test-Connection -ComputerName $ComputerName -Count $Count -Quiet
}

<#
.SYNOPSIS
Convert from OS build number to OS version
.DESCRIPTION
Convert from OS build number to OS version associated with build.
Note that "OS version" is not the same as "OS release version"
.PARAMETER Build
Operating system build number
.EXAMPLE
PS> ConvertFrom-OSBuild 18363.1049
1909
.INPUTS
None, you can't p to ConvertFrom-OSBuild
.OUTPUTS
None.
.NOTES
None.
#>
function ConvertFrom-OSBuild
{
	[OutputType([int32])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern("^\d{5}(\.\d{3}\d{0,2})?$")]
		[string] $Build
	)

	# Drop decimal part, not used
	$WholePart = [decimal]::ToUInt32($Build)

	foreach ($Info in $Script:OSBuildInfo)
	{
		if ($Info.Build -eq $WholePart)
		{
			return [int32] $Info.Version
		}
	}

	Write-Error -Category ObjectNotFound -TargetObject $Build `
		-Message "Provided OS build number not recognized"
}

<#
https://docs.microsoft.com/en-us/windows/release-information/
Version	Servicing option				Availability OS build	Latest revision date	End of service
2004	Semi-Annual Channel				2020-05-27	19041.450	2020-08-11	2021-12-14	2021-12-14	Microsoft recommends
1909	Semi-Annual Channel				2019-11-12	18363.1049	2020-08-20	2021-05-11	2022-05-10
1903	Semi-Annual Channel				2019-05-21	18362.1049	2020-08-20	2020-12-08	2020-12-08
1809	Semi-Annual Channel				2019-03-28	17763.1432	2020-08-20	2020-11-10	2021-05-11
1809	Semi-Annual Channel (Targeted)	2018-11-13	17763.1432	2020-08-20	2020-11-10	2021-05-11
1803	Semi-Annual Channel				2018-07-10	17134.1667	2020-08-11	End of service	2020-11-10
1803	Semi-Annual Channel (Targeted)	2018-04-30	17134.1667	2020-08-11	End of service	2020-11-10
1709	Semi-Annual Channel				2018-01-18	16299.2045	2020-08-11	End of service	2020-10-13
1709	Semi-Annual Channel (Targeted)	2017-10-17	16299.2045	2020-08-11	End of service	2020-10-13	# Check OS build

Enterprise and IoT Enterprise LTSB/LTSC editions

Version		Servicing option					Availability OS build	Latest revision date	Mainstream support end date	Extended support end date
1809		Long-Term Servicing Channel (LTSC)	2018-11-13	17763.1432	2020-08-20	2024-01-09	2029-01-09
1607		Long-Term Servicing Branch (LTSB)	2016-08-02	14393.3866	2020-08-11	2021-10-12	2026-10-13
1507 (RTM)	Long-Term Servicing Branch (LTSB)	2015-07-29	10240.18666	2020-08-11	2020-10-13	2025-10-14
#>

Set-Variable -Name OSBuildInfo -Scope Script -Option Constant -Value ([PSCustomObject[]]@(
		[hashtable]@{
			Version = 2004
			Build = 19041
		}
		[hashtable]@{
			Version = 1909
			Build = 18363
		}
		[hashtable]@{
			Version = 1903
			Build = 18362
		}
		[hashtable]@{
			Version = 1809
			Build = 17763
		}
		[hashtable]@{
			Version = 1803
			Build = 17134
		}
		[hashtable]@{
			Version = 1709
			Build = 16299
		}
		[hashtable]@{
			Version = 1607
			Build = 14393
		}
		[hashtable]@{
			Version = 1507
			Build = 10240
		}
	)
) -Description "OS Build\Version map"

#
# Function exports
#

Export-ModuleMember -Function Get-ComputerName
Export-ModuleMember -Function Get-ConfiguredAdapter
Export-ModuleMember -Function Get-InterfaceAlias
Export-ModuleMember -Function Get-IPAddress
Export-ModuleMember -Function Get-Broadcast
Export-ModuleMember -Function Get-SystemSKU
Export-ModuleMember -Function Test-TargetComputer
Export-ModuleMember -Function ConvertFrom-OSBuild

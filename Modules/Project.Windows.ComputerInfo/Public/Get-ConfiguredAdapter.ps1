
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

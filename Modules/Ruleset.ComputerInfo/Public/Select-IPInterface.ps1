
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Select IP configuration for specified network adapters

.DESCRIPTION
Get a list of network adapter IP configuration for specified adapters.
Conditionally select virtual, hidden or connected adapters.
This may include adapters on all or specific compartments.

.PARAMETER AddressFamily
Obtain interfaces configured for specific IP version

.PARAMETER Physical
If specified, include only physical adapters

.PARAMETER Virtual
If specified, include only virtual adapters

.PARAMETER Hidden
If specified, only hidden interfaces are included

.PARAMETER Connected
If specified, only interfaces connected to network are returned

.PARAMETER CompartmentId
Specifies an identifier for network compartment in the protocol stack.
By default, the function gets Net IP configuration in all compartments.

.PARAMETER Detailed
Indicates that the function retrieves additional interface and computer configuration information,
including the computer name, link layer address, network profile, MTU length, and DHCP status.

.EXAMPLE
PS> Select-IPInterface -AddressFamily IPv4 -Connected -Detailed

.EXAMPLE
PS> Select-IPInterface -AddressFamily IPv6 -Virtual

.INPUTS
None. You cannot pipe objects to Select-IPInterface

.OUTPUTS
"NetIPConfiguration" [PSCustomObject] or error message if no adapter configured

.NOTES
None.
#>
function Select-IPInterface
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Select-IPInterface.md")]
	[OutputType("NetIPConfiguration")]
	param (
		[Parameter()]
		[Alias("IPVersion")]
		[ValidateSet("IPv4", "IPv6", "Any")]
		[string] $AddressFamily = "Any",

		[Parameter(ParameterSetName = "Physical")]
		[switch] $Physical,

		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Virtual,

		[Parameter()]
		[switch] $Hidden,

		[Parameter()]
		[switch] $Connected,

		[Parameter()]
		[int32] $CompartmentId,

		[Parameter()]
		[switch] $Detailed
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($CompartmentId)
	{
		# NetIPConfiguration
		$ConfiguredInterface = Get-NetIPConfiguration -Detailed:$Detailed -CompartmentId:$CompartmentId
	}
	else
	{
		$ConfiguredInterface = Get-NetIPConfiguration -Detailed:$Detailed -AllCompartments
	}

	if ($AddressFamily -eq "IPv4")
	{
		$ConfiguredInterface = $ConfiguredInterface | Where-Object -Property IPv4Address

		if ($Connected)
		{
			$ConfiguredInterface = $ConfiguredInterface | Where-Object -Property IPv4DefaultGateway
		}
	}
	elseif ($AddressFamily -eq "IPv6")
	{
		$ConfiguredInterface = $ConfiguredInterface | Where-Object -Property IPv6Address

		if ($Connected)
		{
			$ConfiguredInterface = $ConfiguredInterface | Where-Object -Property IPv6DefaultGateway
		}
	}
	else # Any
	{
		$ConfiguredInterface = $ConfiguredInterface | Where-Object {
			$_.IPv4Address -or $_.IPv6Address
		}

		if ($Connected)
		{
			$ConfiguredInterface = $ConfiguredInterface | Where-Object {
				$_.IPv4DefaultGateway -or $_.IPv6DefaultGateway
			}
		}
	}

	if (!$ConfiguredInterface)
	{
		Write-Error -Category ObjectNotFound -TargetObject "AllConfiguredAdapters" `
			-Message "None of the adapters is configured for $AddressFamily"
		return $null
	}

	# Get-NetIPConfiguration does not tell us adapter type (hardware, hidden or virtual)
	# Microsoft.Management.Infrastructure.CimInstance#ROOT/StandardCimv2/MSFT_NetAdapter
	$RequestedAdapters = @()

	if ($Hidden)
	{
		$RequestedAdapters = Get-NetAdapter -IncludeHidden | Where-Object {
			$_.Hidden -eq $true
		}
	}
	else
	{
		$RequestedAdapters = Get-NetAdapter -IncludeHidden | Where-Object {
			$_.Hidden -eq $false
		}
	}

	if ($Physical)
	{
		$RequestedAdapters = $RequestedAdapters | Where-Object {
			$_.HardwareInterface -eq $true
		}
	}
	elseif ($Virtual)
	{
		$RequestedAdapters = $RequestedAdapters | Where-Object {
			$_.Virtual -eq $true
		}
	}

	if (!$RequestedAdapters)
	{
		Write-Error -Category ObjectNotFound -Message "None of the adapters matches parameter set"
		return $null
	}

	# Compare results for equality
	[int32[]] $InterfaceIndex = $RequestedAdapters | Select-Object -ExpandProperty ifIndex

	$SelectedInterface = $ConfiguredInterface | Where-Object {
		[array]::Find($InterfaceIndex, [System.Predicate[int32]] { $_.InterfaceIndex -eq $args[0] })
	}

	$Count = ($SelectedInterface | Measure-Object).Count
	if ($Count -eq 0)
	{
		Write-Error -Category ObjectNotFound -Message "None of the adapters is configured for $AddressFamily and the specified parameter set"
		return $null
	}
	elseif ($Count -gt 1)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Multiple adapters are configured for '$AddressFamily' address family"
	}

	Write-Output $SelectedInterface
}

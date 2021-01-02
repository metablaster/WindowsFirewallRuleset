
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
Get broadcast address

.DESCRIPTION
Get broadcast addresses, for specified network interfaces.
Returned broadcast addresses are IPv4 and only for adapters connected to network.

.PARAMETER Physical
If specified, include only physical adapters

.PARAMETER Virtual
If specified, include only virtual adapters

.PARAMETER Hidden
If specified, only hidden interfaces are included

.EXAMPLE
PS> Get-Broadcast -Physical

.EXAMPLE
PS> Get-Broadcast -Virtual -Hidden

.INPUTS
None. You cannot pipe objects to Get-Broadcast

.OUTPUTS
[ipaddress] Broadcast addresses

.NOTES
None.
#>
function Get-Broadcast
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-Broadcast.md")]
	[OutputType([ipaddress])]
	param (
		[Parameter(ParameterSetName = "Physical")]
		[switch] $Physical,

		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Virtual,

		[Parameter()]
		[switch] $Hidden
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting broadcast address of connected adapters"

	# Broadcast address makes sense only for IPv4
	if ($Physical)
	{
		$ConfiguredAdapters = Select-IPInterface -AddressFamily IPv4 -Connected -Physical:$Physical -Hidden:$Hidden
	}
	else
	{
		$ConfiguredAdapters = Select-IPInterface -AddressFamily IPv4 -Connected -Virtual:$Virtual -Hidden:$Hidden
	}

	$ConfiguredAdapters = $ConfiguredAdapters | Select-Object -ExpandProperty IPv4Address
	$Count = ($ConfiguredAdapters | Measure-Object).Count

	if ($Count -gt 0)
	{
		[ipaddress[]] $BroadcastAddress = @()
		foreach ($Adapter in $ConfiguredAdapters)
		{
			[ipaddress] $IPAddress = $Adapter | Select-Object -ExpandProperty IPAddress
			$SubnetMask = ConvertTo-Mask ($Adapter | Select-Object -ExpandProperty PrefixLength)

			$BroadcastAddress += Get-NetworkSummary $IPAddress $SubnetMask |
			Select-Object -ExpandProperty BroadcastAddress |
			Select-Object -ExpandProperty IPAddressToString
		}

		Write-Information -Tags "Result" -MessageData "INFO: Network broadcast addresses are: $BroadcastAddress"
		Write-Output $BroadcastAddress
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] returns null"
}

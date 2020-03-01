
<#
Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses bellow
#>

<#
MIT License

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
ISC License

Copyright (C) 2016, Chris Dent

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#>

<#
.SYNOPSIS
Generates a summary describing several properties of a network range
.DESCRIPTION
Get-NetworkSummary uses many of the IP conversion commands to provide a summary of a
network range from any IP address in the range and a subnet mask.
.PARAMETER IPAddress
Either a literal IP address, a network range expressed as CIDR notation,
or an IP address and subnet mask in a string.
.PARAMETER SubnetMask
A subnet mask as an IP address.
.EXAMPLE
Get-NetworkSummary 192.168.0.1 255.255.255.0
.EXAMPLE
Get-NetworkSummary 10.0.9.43/22
.EXAMPLE
Get-NetworkSummary 0/0
.INPUTS
System.String
.OUTPUTS
TODO: describe outputs
.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project: code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function Get-NetworkSummary
{
	[CmdletBinding()]
	[OutputType('Indented.Net.IP.NetworkSummary')]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[string] $IPAddress,

		[Parameter()]
		[string] $SubnetMask
	)

	process
	{
		try
		{
			$network = ConvertTo-Network @psboundparameters
		}
		catch
		{
			throw $_
		}

		$decimalIP = ConvertTo-DecimalIP $Network.IPAddress
		$decimalMask = ConvertTo-DecimalIP $Network.SubnetMask
		$decimalNetwork = $decimalIP -band $decimalMask
		$decimalBroadcast = $decimalIP -bor (-bnot $decimalMask -band [UInt32]::MaxValue)

		$networkSummary = [PSCustomObject]@{
			NetworkAddress = $networkAddress = ConvertTo-DottedDecimalIP $decimalNetwork
			NetworkDecimal = $decimalNetwork
			BroadcastAddress = ConvertTo-DottedDecimalIP $decimalBroadcast
			BroadcastDecimal = $decimalBroadcast
			Mask = $network.SubnetMask
			MaskLength = $maskLength = ConvertTo-MaskLength $network.SubnetMask
			MaskHexadecimal = ConvertTo-HexIP $network.SubnetMask
			CIDRNotation = '{0}/{1}' -f $networkAddress, $maskLength
			HostRange = ''
			NumberOfAddresses = $decimalBroadcast - $decimalNetwork + 1
			NumberOfHosts = $decimalBroadcast - $decimalNetwork - 1
			Class = ''
			IsPrivate = $false
			PSTypeName = 'Indented.Net.IP.NetworkSummary'
		}

		if ($networkSummary.NumberOfHosts -lt 0)
		{
			$networkSummary.NumberOfHosts = 0
		}
		if ($networkSummary.MaskLength -lt 31)
		{
			$networkSummary.HostRange = '{0} - {1}' -f @(
				(ConvertTo-DottedDecimalIP ($decimalNetwork + 1))
				(ConvertTo-DottedDecimalIP ($decimalBroadcast - 1))
			)
		}

		$networkSummary.Class = switch -regex (ConvertTo-BinaryIP $network.IPAddress)
		{
			'^1111' { 'E'; break }
			'^1110' { 'D'; break }
			'^11000000\.10101000' { if ($networkSummary.MaskLength -ge 16) { $networkSummary.IsPrivate = $true } }
			'^110' { 'C'; break }
			'^10101100\.0001' { if ($networkSummary.MaskLength -ge 12) { $networkSummary.IsPrivate = $true } }
			'^10' { 'B'; break }
			'^00001010' { if ($networkSummary.MaskLength -ge 8) { $networkSummary.IsPrivate = $true } }
			'^0' { 'A'; break }
		}

		$networkSummary
	}
}

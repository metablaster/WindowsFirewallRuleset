
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the ISC license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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

Copyright (C) 2016 Chris Dent

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
PS> Get-NetworkSummary 192.168.0.1 255.255.255.0

.EXAMPLE
PS> Get-NetworkSummary 10.0.9.43/22

.EXAMPLE
PS> Get-NetworkSummary 0/0

.INPUTS
[string]

.OUTPUTS
"Ruleset.IP.NetworkSummary" [PSCustomObject]

.NOTES
Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkSummary.md

.LINK
https://github.com/indented-automation/Indented.Net.IP
#>
function Get-NetworkSummary
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkSummary.md")]
	[OutputType("Ruleset.IP.NetworkSummary")]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string] $IPAddress,

		[Parameter()]
		[string] $SubnetMask
	)

	process
	{
		try
		{
			$Network = ConvertTo-Network @PSBoundParameters
		}
		catch
		{
			throw $_
		}

		$DecimalIP = ConvertTo-DecimalIP $Network.IPAddress
		$DecimalMask = ConvertTo-DecimalIP $Network.SubnetMask
		$DecimalNetwork = $DecimalIP -band $DecimalMask
		$DecimalBroadcast = $DecimalIP -bor (-bnot $DecimalMask -band [uint32]::MaxValue)

		$NetworkSummary = [PSCustomObject]@{
			NetworkAddress = $NetworkAddress = ConvertTo-DottedDecimalIP $DecimalNetwork
			NetworkDecimal = $DecimalNetwork
			BroadcastAddress = ConvertTo-DottedDecimalIP $DecimalBroadcast
			BroadcastDecimal = $DecimalBroadcast
			Mask = $Network.SubnetMask
			MaskLength = $MaskLength = ConvertTo-MaskLength $Network.SubnetMask
			MaskHexadecimal = ConvertTo-HexIP $Network.SubnetMask
			CIDRNotation = '{0}/{1}' -f $NetworkAddress, $MaskLength
			HostRange = ""
			NumberOfAddresses = $DecimalBroadcast - $DecimalNetwork + 1
			NumberOfHosts = $DecimalBroadcast - $DecimalNetwork - 1
			Class = ""
			IsPrivate = $false
			# TODO: Not used in Format.ps1xml
			PSTypeName = "Ruleset.IP.NetworkSummary"
		}

		if ($NetworkSummary.NumberOfHosts -lt 0)
		{
			$NetworkSummary.NumberOfHosts = 0
		}
		if ($NetworkSummary.MaskLength -lt 31)
		{
			$NetworkSummary.HostRange = '{0} - {1}' -f @(
				(ConvertTo-DottedDecimalIP ($DecimalNetwork + 1))
				(ConvertTo-DottedDecimalIP ($DecimalBroadcast - 1))
			)
		}

		$NetworkSummary.Class = switch -regex (ConvertTo-BinaryIP $Network.IPAddress)
		{
			'^1111' { "E"; break }
			'^1110' { "D"; break }
			'^11000000\.10101000' { if ($NetworkSummary.MaskLength -ge 16) { $NetworkSummary.IsPrivate = $true } }
			'^110' { "C"; break }
			'^10101100\.0001' { if ($NetworkSummary.MaskLength -ge 12) { $NetworkSummary.IsPrivate = $true } }
			'^10' { "B"; break }
			'^00001010' { if ($NetworkSummary.MaskLength -ge 8) { $NetworkSummary.IsPrivate = $true } }
			'^0' { "A"; break }
		}

		$NetworkSummary
	}
}

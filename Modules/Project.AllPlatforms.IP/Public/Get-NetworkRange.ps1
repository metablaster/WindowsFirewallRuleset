
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
Get a list of IP addresses within the specified network.

.DESCRIPTION
Get-NetworkRange finds the network and broadcast address as decimal values
then starts a counter between the two, returning IPAddress for each.

.PARAMETER IPAddress
Either a literal IP address, a network range expressed as CIDR notation,
or an IP address and subnet mask in a string.

.PARAMETER SubnetMask
A subnet mask as an IP address.

.PARAMETER IncludeNetworkAndBroadcast
Include the network and broadcast addresses when generating a network address range.

.PARAMETER Start
The start address of a range.

.PARAMETER End
The end address of a range.

.EXAMPLE
PS> Get-NetworkRange 192.168.0.0 255.255.255.0

Returns all IP addresses in the range 192.168.0.0/24.

.EXAMPLE
PS> Get-NetworkRange 10.0.8.0/22

Returns all IP addresses in the range 192.168.0.0 255.255.252.0.

.INPUTS
[System.String]

.OUTPUTS
[IPAddress]

.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function Get-NetworkRange
{
	[OutputType([IPAddress])]
	[CmdletBinding(DefaultParameterSetName = "FromIPAndMask",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.IP/Help/en-US/Get-NetworkRange.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0,
			ValueFromPipeline = $true, ParameterSetName = "FromIPAndMask")]
		[string] $IPAddress,

		[Parameter(Position = 1,
			ParameterSetName = "FromIPAndMask")]
		[string] $SubnetMask,

		[Parameter(ParameterSetName = "FromIPAndMask")]
		[switch] $IncludeNetworkAndBroadcast,

		[Parameter(Mandatory = $true,
			ParameterSetName = "FromStartAndEnd")]
		[IPAddress] $Start,

		[Parameter(Mandatory = $true,
			ParameterSetName = "FromStartAndEnd")]
		[IPAddress] $End
	)

	process
	{
		if ($PSCmdlet.ParameterSetName -eq "FromIPAndMask")
		{
			try
			{
				$PSBoundParameters.Remove("IncludeNetworkAndBroadcast") | Out-Null
				$Network = ConvertTo-Network @PSBoundParameters
			}
			catch
			{
				$PSCmdlet.ThrowTerminatingError($_)
			}

			$DecimalIP = ConvertTo-DecimalIP $Network.IPAddress
			$DecimalMask = ConvertTo-DecimalIP $Network.SubnetMask

			$StartDecimal = $DecimalIP -band $DecimalMask
			$EndDecimal = $DecimalIP -bor (-bnot $DecimalMask -band [uint32]::MaxValue)

			if (-not $IncludeNetworkAndBroadcast)
			{
				$StartDecimal++
				$EndDecimal--
			}
		}
		else
		{
			$StartDecimal = ConvertTo-DecimalIP $Start
			$EndDecimal = ConvertTo-DecimalIP $End
		}

		for ($i = $StartDecimal; $i -le $EndDecimal; $i++)
		{
			[IPAddress]([IPAddress]::NetworkToHostOrder([int64] $i) -shr 32 -band [uint32]::MaxValue)
		}
	}
}

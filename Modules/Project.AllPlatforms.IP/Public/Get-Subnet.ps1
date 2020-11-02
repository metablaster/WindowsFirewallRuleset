
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
Get a list of subnets of a given size within a defined supernet.

.DESCRIPTION
Generates a list of subnets for a given network range using either
the address class or a user-specified value.

.PARAMETER IPAddress
Any address in the super-net range. Either a literal IP address,
a network range expressed as CIDR notation, or an IP address and subnet mask in a string.

.PARAMETER SubnetMask
The subnet mask of the network to split. Mandatory if the subnet mask is not included in the IPAddress parameter.

.PARAMETER NewSubnetMask
Split the existing network described by the IPAddress and subnet mask using this mask.

.EXAMPLE
PS> Get-Subnet 10.0.0.0 255.255.255.0 -NewSubnetMask 255.255.255.192

Four /26 networks are returned.

.EXAMPLE
PS> Get-Subnet 0/22 -NewSubnetMask 24

64 /24 networks are returned.

.INPUTS
None. You cannot pipe objects to Get-Subnet

.OUTPUTS
"Project.AllPlatforms.IP.Subnet" Custom object

.NOTES
Change log:
	07/03/2016 - Chris Dent - Cleaned up code, added tests.
	12/12/2015 - Chris Dent - Redesigned.
	13/10/2011 - Chris Dent - Created.

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function Get-Subnet
{
	[OutputType("Project.AllPlatforms.IP.Subnet")]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.IP/Help/en-US/Get-Subnet.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $IPAddress,

		[Parameter(Position = 1)]
		[string] $SubnetMask,

		[Parameter(Mandatory = $true)]
		[string] $NewSubnetMask
	)

	$PSBoundParameters.Remove("NewSubnetMask") | Out-Null

	try
	{
		$Network = ConvertTo-Network @PSBoundParameters
		$NewNetwork = ConvertTo-Network 0 $NewSubnetMask
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}

	if ($Network.MaskLength -gt $NewNetwork.MaskLength)
	{
		$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
			[ArgumentException] "The subnet mask of the new network is shorter (masks fewer addresses) than the subnet mask of the existing network.",
			"NewSubnetMaskTooShort",
			"InvalidArgument",
			$NewNetwork.MaskLength
		)

		$PSCmdlet.ThrowTerminatingError($ErrorRecord)
	}

	$NumberOfNets = [math]::Pow(2, ($NewNetwork.MaskLength - $Network.MaskLength))
	$NumberOfAddresses = [math]::Pow(2, (32 - $NewNetwork.MaskLength))

	$DecimalAddress = ConvertTo-DecimalIP (Get-NetworkAddress $Network.ToString())
	for ($i = 0; $i -lt $NumberOfNets; $i++)
	{
		$NetworkAddress = ConvertTo-DottedDecimalIP $DecimalAddress

		ConvertTo-Subnet -IPAddress $NetworkAddress -SubnetMask $NewNetwork.MaskLength

		$DecimalAddress += $NumberOfAddresses
	}
}

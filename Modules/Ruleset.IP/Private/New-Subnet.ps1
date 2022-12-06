
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
Creates an IP subnet object.

.DESCRIPTION
Creates an IP subnet object.

.PARAMETER NetworkAddress
Network address as either IP address or 32-bit unsigned integer value

.PARAMETER BroadcastAddress
Broadcast address as either IP address or 32-bit unsigned integer value

.PARAMETER SubnetMask
Subnet mask

.PARAMETER MaskLength
Mask length

.EXAMPLE
See Resolve-IPAddress.ps1

.INPUTS
None. You cannot pipe objects to New-Subnet

.OUTPUTS
[PSCustomObject]

.NOTES
None.
#>
function New-Subnet
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "None")]
	param (
		[Parameter(Mandatory = $true)]
		$NetworkAddress,

		[Parameter()]
		$BroadcastAddress,

		[Parameter()]
		[IPAddress] $SubnetMask,

		[Parameter()]
		[uint32] $MaskLength
	)

	if ($PSCmdlet.ShouldProcess($NetworkAddress, "Create new subnet"))
	{
		if ($NetworkAddress -isnot [IPAddress])
		{
			$NetworkAddress = ConvertTo-DottedDecimalIP $NetworkAddress
		}

		if ($BroadcastAddress -and $BroadcastAddress -isnot [IPAddress])
		{
			$BroadcastAddress = ConvertTo-DottedDecimalIP $BroadcastAddress
		}

		if ($NetworkAddress -eq $BroadcastAddress)
		{
			$SubnetMask = "255.255.255.255"
			$MaskLength = 32
			$HostAddresses = 0
		}

		else
		{
			# One of these will be provided
			if (!$SubnetMask)
			{
				$SubnetMask = ConvertTo-Mask $MaskLength
			}

			if (!$MaskLength)
			{
				$MaskLength = ConvertTo-MaskLength $SubnetMask
			}

			$HostAddresses = [Math]::Pow(2, (32 - $MaskLength)) - 2
			if ($HostAddresses -lt 0)
			{
				$HostAddresses = 0
			}
		}

		if (!$BroadcastAddress)
		{
			$BroadcastAddress = Get-BroadcastAddress -IPAddress $NetworkAddress -SubnetMask $SubnetMask
		}

		[PSCustomObject]@{
			Cidr = '{0}/{1}' -f $NetworkAddress, $MaskLength
			NetworkAddress = $NetworkAddress
			BroadcastAddress = $BroadcastAddress
			SubnetMask = $SubnetMask
			MaskLength = $MaskLength
			HostAddresses = $HostAddresses
			PSTypeName = "Ruleset.IP.Subnet"
		} | Add-Member ToString -MemberType ScriptMethod -Force -PassThru -Value {
			return $this.Cidr
		}
	}
}

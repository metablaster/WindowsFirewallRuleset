
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
Converts IP address formats to a set a known styles.
.DESCRIPTION
ConvertTo-Network ensures consistent values are recorded from parameters which must handle differing addressing formats.
This Cmdlet allows all other the other functions in this module to offload parameter handling.
.PARAMETER IPAddress
Either a literal IP address, a network range expressed as CIDR notation,
or an IP address and subnet mask in a string.
.PARAMETER SubnetMask
A subnet mask as an IP address.
.EXAMPLE
TODO: Provide example
.INPUTS
None. You cannot pipe objects to ConvertTo-Network
.OUTPUTS
TODO: describe outputs
.NOTES
Change log:
	05/03/2016 - Chris Dent - Refactored and simplified.
	14/01/2014 - Chris Dent - Created.
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Rename function to approved verb
- Removed unnecessary position arguments, added default argument values explicitly.
#>
function ConvertTo-Network
{
	[OutputType("Project.AllPlatforms.IP.Network")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $IPAddress,

		[Parameter()]
		[AllowNull()]
		[string] $SubnetMask
	)

	$ValidSubnetMaskValues =
	"0.0.0.0", "128.0.0.0", "192.0.0.0",
	"224.0.0.0", "240.0.0.0", "248.0.0.0", "252.0.0.0",
	"254.0.0.0", "255.0.0.0", "255.128.0.0", "255.192.0.0",
	"255.224.0.0", "255.240.0.0", "255.248.0.0", "255.252.0.0",
	"255.254.0.0", "255.255.0.0", "255.255.128.0", "255.255.192.0",
	"255.255.224.0", "255.255.240.0", "255.255.248.0", "255.255.252.0",
	"255.255.254.0", "255.255.255.0", "255.255.255.128", "255.255.255.192",
	"255.255.255.224", "255.255.255.240", "255.255.255.248", "255.255.255.252",
	"255.255.255.254", "255.255.255.255"

	$Network = [PSCustomObject]@{
		IPAddress = $null
		SubnetMask = $null
		MaskLength = 0
		PSTypeName = 'Project.AllPlatforms.IP.Network'
	}

	# Override ToString
	$Network | Add-Member ToString -MemberType ScriptMethod -Force -Value {
		'{0}/{1}' -f $this.IPAddress, $this.MaskLength
	}

	if (-not $PSBoundParameters.ContainsKey('SubnetMask') -or $SubnetMask -eq '')
	{
		$IPAddress, $SubnetMask = $IPAddress.Split([char[]]'\/ ', [StringSplitOptions]::RemoveEmptyEntries)
	}

	# IPAddress
	while ($IPAddress.Split('.').Count -lt 4)
	{
		$IPAddress += '.0'
	}

	if ([IPAddress]::TryParse($IPAddress, [ref] $null))
	{
		$Network.IPAddress = [IPAddress] $IPAddress
	}
	else
	{
		$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
			[ArgumentException]'Invalid IP address.',
			'InvalidIPAddress',
			'InvalidArgument',
			$IPAddress
		)

		$PSCmdlet.ThrowTerminatingError($ErrorRecord)
	}

	# SubnetMask
	if ($null -eq $SubnetMask -or $SubnetMask -eq '')
	{
		$Network.SubnetMask = [IPAddress] $ValidSubnetMaskValues[32]
		$Network.MaskLength = 32
	}
	else
	{
		$MaskLength = 0
		if ([int32]::TryParse($SubnetMask, [ref] $MaskLength))
		{
			if ($MaskLength -ge 0 -and $MaskLength -le 32)
			{
				$Network.SubnetMask = [IPAddress] $ValidSubnetMaskValues[$MaskLength]
				$Network.MaskLength = $MaskLength
			}
			else
			{
				$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
					[ArgumentException]'Mask length out of range (expecting 0 to 32).',
					'InvalidMaskLength',
					'InvalidArgument',
					$SubnetMask
				)
				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}
		}
		else
		{
			while ($SubnetMask.Split('.').Count -lt 4)
			{
				$SubnetMask += '.0'
			}

			$MaskLength = $ValidSubnetMaskValues.IndexOf($SubnetMask)

			if ($MaskLength -ge 0)
			{
				$Network.SubnetMask = [IPAddress] $SubnetMask
				$Network.MaskLength = $MaskLength
			}
			else
			{
				$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
					[ArgumentException]'Invalid subnet mask.',
					'InvalidSubnetMask',
					'InvalidArgument',
					$SubnetMask
				)

				$PSCmdlet.ThrowTerminatingError($ErrorRecord)
			}
		}
	}

	$Network
}

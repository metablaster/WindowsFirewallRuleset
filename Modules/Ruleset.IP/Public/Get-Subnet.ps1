
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

using namespace System.Collections.Generic

<#
.SYNOPSIS
Get a list of subnets of a given size within a defined supernet

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

.PARAMETER Start
The first IP address from a range.

.PARAMETER End
The last IP address from a range.

.EXAMPLE
PS> Get-Subnet 10.0.0.0 255.255.255.0 -NewSubnetMask 255.255.255.192

Four /26 networks are returned.

.EXAMPLE
PS> Get-Subnet 0/22 -NewSubnetMask 24

64 /24 networks are returned.

.INPUTS
None. You cannot pipe objects to Get-Subnet

.OUTPUTS
"Ruleset.IP.Subnet" [PSCustomObject]

.NOTES
Change log:

- 07/03/2016 - Chris Dent - Cleaned up code, added tests.
- 12/12/2015 - Chris Dent - Redesigned.
- 13/10/2011 - Chris Dent - Created.

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-Subnet.md

.LINK
https://github.com/indented-automation/Indented.Net.IP
#>
function Get-Subnet
{
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSPossibleIncorrectUsageOfAssignmentOperator", "", Scope = "Function",
		Justification = "https://github.com/indented-automation/Indented.Net.IP/issues/14#event-7903507075")]
	[CmdletBinding(DefaultParameterSetName = "FromSupernet",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-Subnet.md")]
	[OutputType("Ruleset.IP.Subnet")]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "FromSupernet")]
		[string] $IPAddress,

		[Parameter(Position = 1, ParameterSetName = "FromSupernet")]
		[string] $SubnetMask,

		[Parameter(Mandatory = $true, ParameterSetName = "FromSupernet")]
		[string] $NewSubnetMask,

		[Parameter(Mandatory, ParameterSetName = "FromStartAndEnd")]
		[IPAddress] $Start,

		[Parameter(Mandatory, ParameterSetName = "FromStartAndEnd")]
		[IPAddress] $End
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ParameterSetName -eq "FromSupernet")
	{
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
		$numberOfAddresses = [math]::Pow(2, (32 - $NewNetwork.MaskLength))

		$DecimalAddress = ConvertTo-DecimalIP (Get-NetworkAddress $Network.ToString())
		for ($i = 0; $i -lt $NumberOfNets; $i++)
		{
			$NetworkAddress = ConvertTo-DottedDecimalIP $DecimalAddress

			New-Subnet -NetworkAddress $NetworkAddress -MaskLength $NewNetwork.MaskLength

			$DecimalAddress += $numberOfAddresses
		}
	}
	elseif ($PSCmdlet.ParameterSetName -eq "FromStartAndEnd")
	{
		$Range = @{ Start = ConvertTo-DecimalIP $Start; End = ConvertTo-DecimalIP $End; Type = "Whole" }
		if ($Range["Start"] -gt $Range["End"])
		{
			# Could just swap them, but it implies a problem with the request
			$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
				[ArgumentException] "The end address in the range falls before the start address.",
				"InvalidNetworkRange",
				"InvalidArgument",
				$Range
			)

			$PSCmdlet.ThrowTerminatingError($ErrorRecord)
		}

		$InputQueue = [queue[object]]::new()
		$InputQueue.Enqueue($Range)

		# Find an initial maximum number of host bits. Reduces work in the main loops.
		$MaximumHostBits = 32
		do
		{
			$MaximumHostBits--
		} until (($Range["Start"] -band ([uint32] 1 -shl $MaximumHostBits)) -ne ($Range["End"] -band ([uint32] 1 -shl $MaximumHostBits)))

		$MaximumHostBits++

		# Guards against infinite loops when I've done something wrong
		$MaximumIterations = 200
		$Iteration = 0

		$Subnets = do
		{
			$Range = $InputQueue.Dequeue()
			$RangeSize = $Range["End"] - $Range["Start"] + 1

			if ($RangeSize -eq 1)
			{
				New-Subnet -NetworkAddress $Range["Start"] -BroadcastAddress $Range["End"]
				continue
			}

			$Subnetstart = $subnetEnd = $null
			for ($hostBits = $MaximumHostBits; $hostBits -gt 0; $hostBits--)
			{
				$Subnetsize = [math]::Pow(2, $hostBits)

				if ($Subnetsize -le $RangeSize)
				{
					if ($Remainder = $Range["Start"] % $Subnetsize)
					{
						$Subnetstart = $Range["Start"] - $Remainder + $Subnetsize
					}
					else
					{
						$Subnetstart = $Range["Start"]
					}
					$subnetEnd = $Subnetstart + $Subnetsize - 1

					if ($subnetEnd -gt $Range["End"])
					{
						continue
					}

					New-Subnet -NetworkAddress $Subnetstart -BroadcastAddress $subnetEnd -MaskLength (32 - $hostBits)
					break
				}
			}

			if ($Subnetstart -and $Subnetstart -gt $Range["Start"])
			{
				$InputQueue.Enqueue(@{ Start = $Range["Start"]; End = $Subnetstart - 1; Type = "Start" } )
			}

			if ($subnetEnd -and $subnetEnd -lt $Range["End"])
			{
				$InputQueue.Enqueue(@{ Start = $subnetEnd + 1; End = $Range["End"]; Type = "End" })
			}

			$Iteration++
		} while ($InputQueue.Count -and $Iteration -lt $MaximumIterations)

		if ($Iteration -ge $MaximumIterations)
		{
			Write-Warning "Exceeded the maximum number of iterations while generating subnets"
		}

		$Subnets | Sort-Object { [version] $_.NetworkAddress.ToString() }
	}
}

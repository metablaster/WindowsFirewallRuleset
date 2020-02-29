
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
Resolves an IP address expression using wildcard expressions to individual IP addresses.
.DESCRIPTION
Resolves an IP address expression using wildcard expressions to individual IP addresses.
Resolve-IPAddress expands groups and values in square brackets to generate a list of IP addresses or networks using CIDR-notation.
Ranges of values may be specied using a start and end value using "-" to separate the values.
Specific values may be listed as a comma separated list.
.PARAMETER IPAddress
The IPAddress expression to resolve.
.EXAMPLE
Resolve-IPAddress "10.[1,2].[0-2].0/24"

Returns the addresses 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.2.0.0/24, and so on.
.INPUTS
System.String
.OUTPUTS
TODO: describe outputs
.NOTES
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consisten with project: code formatting and symbol casing.
- Removed unecessary position arguments, added default argument values explicitly.
#>
function Resolve-IPAddress
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[string] $IPAddress
	)

	process
	{
		$groups = [regex]::Matches($IPAddress, '\[(?:(?<Range>\d+(?:-\d+))|(?<Selected>(?:\d+, *)*\d+))\]|(?<All>\*)').Groups.Captures |
		Where-Object { $_ -and $_.Name -ne '0' } |
		ForEach-Object {
			$group = $_

			$values = switch ($group.Name)
			{
				'Range'
				{
					[int32] $start, [int32] $end = $group.Value -split '-'

					if ($start, $end -gt 255)
					{
						$errorRecord = [System.Management.Automation.ErrorRecord]::new(
							[ArgumentException]::new('Value ranges to resolve must use a start and end values between 0 and 255'),
							'RangeExpressionOutOfRange',
							'InvalidArgument',
							$group.Value
						)
						$pscmdlet.ThrowTerminatingError($errorRecord)
					}

					$start..$end
				}
				'Selected'
				{
					$values = [int[]]($group.Value -split ', *')

					if ($values -gt 255)
					{
						$errorRecord = [System.Management.Automation.ErrorRecord]::new(
							[ArgumentException]::new('All selected values must be between 0 and 255'),
							'SelectionExpressionOutOfRange',
							'InvalidArgument',
							$group.Value
						)
						$pscmdlet.ThrowTerminatingError($errorRecord)
					}

					$values
				}
				'All'
				{
					0..255
				}
			}

			[PSCustomObject]@{
				Name = $_.Name
				Position = [int32] $IPAddress.Substring(0, $_.Index).Split('.').Count - 1
				ReplaceWith = $values
				PSTypeName = 'ExpansionGroupInfo'
			}
		}

		if ($groups)
		{
			Get-Permutation $groups -BaseAddress $IPAddress
		}
		elseif (-not [IPAddress]::TryParse(($IPAddress -replace '/\d+$'), [ref] $null))
		{
			Write-Warning -Message 'The IPAddress argument is not a valid IP address and cannot be resolved'
		}
		else
		{
			Write-Debug 'No groups found to resolve'
		}
	}
}

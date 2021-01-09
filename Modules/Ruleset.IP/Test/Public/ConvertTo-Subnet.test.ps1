
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

#region:TestFileHeader
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "Number", Justification = "False positive")]
param (
	[switch] $UseExisting
)

# Initialization
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)
Enter-Test -Pester

if (-not $UseExisting)
{
	$ModuleBase = $PSScriptRoot.Substring(0, $PSScriptRoot.IndexOf("\Test"))
	$StubBase = Resolve-Path (Join-Path $ModuleBase "Test*\Stub\*")

	if ($null -ne $StubBase)
	{
		$StubBase | Import-Module -Force
	}

	Import-Module $ModuleBase -Force
}
#endregion

InModuleScope Ruleset.IP {
	Describe 'ConvertTo-Subnet' {
		BeforeAll {
			Mock Get-NetworkSummary {
				return [PSCustomObject]@{ } | Add-Member -TypeName 'Ruleset.IP.NetworkSummary' -PassThru
			}

			[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
				"PSUseDeclaredVarsMoreThanAssignment", "FromIPAndMask", Justification = "False positive")]
			$FromIPAndMask = @{
				IPAddress = '0.0.0.0/32'
			}

			[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
				"PSUseDeclaredVarsMoreThanAssignment", "FromStartAndEnd", Justification = "False positive")]
			$FromStartAndEnd = @{
				Start = '0.0.0.0'
				End = '255.255.255.255'
			}
		}

		#
		# Default mocks
		#

		#
		# Tests
		#

		It 'Returns a PSObject tagged with the type name Ruleset.IP.Subnet' {
			$Subnet = ConvertTo-Subnet @FromIPAndMask
			$Subnet.PSTypeNames -contains 'Ruleset.IP.Subnet' | Should -BeTrue
		}

		It 'Accepts an address and subnet mask, and a start and end address' {
			{ ConvertTo-Subnet @FromIPAndMask } | Should -Not -Throw
			{ ConvertTo-Subnet @FromStartAndEnd } | Should -Not -Throw
		}

		It 'Converts 192.168.0.225/23 to a subnet' {
			$Subnet = ConvertTo-Subnet 192.168.0.225/23
			$Subnet.NetworkAddress | Should -Be '192.168.0.0'
			$Subnet.HostAddresses | Should -Be 510
		}

		It 'Returns the network 10.0.0.0/24 when passed 10.0.0.10 and 10.0.0.250' {
			(ConvertTo-Subnet -Start 10.0.0.10 -End 10.0.0.250).ToString() | Should -Be '10.0.0.0/24'
		}

		It 'Returns the network 0.0.0.0/0 when passed 0.0.0.0 and 255.255.255.255' {
			(ConvertTo-Subnet -Start 0.0.0.0 -End 255.255.255.255).ToString() | Should -Be '0.0.0.0/0'
		}

		It 'Swaps start and end and calculates the common subnet if end falls -Before start' {
			(ConvertTo-Subnet -Start 10.0.0.20 -End 10.0.0.10).ToString() | Should -Be '10.0.0.0/27'
			(ConvertTo-Subnet -Start 10.0.0.10 -End 10.0.0.20).ToString() | Should -Be '10.0.0.0/27'
		}

		It 'Example <Number> is valid' -TestCases (
			(Get-Help ConvertTo-Subnet).Examples.Example.Code | ForEach-Object -Begin {
				[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
					"PSUseDeclaredVarsMoreThanAssignment", "Number", Justification = "False positive")]
				$Number = 1
			} -Process {
				@{ Number = $Number++; Code = $_ }
			}
		) {
			param (
				$Number,
				$Code
			)

			$ScriptBlock = [scriptblock]::Create($Code.Trim())
			$ScriptBlock | Should -Not -Throw
		}
	}
}

Exit-Test -Pester

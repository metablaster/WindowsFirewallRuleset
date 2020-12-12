
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
	"PSReviewUnusedParameter", "Number", Justification = "Likely false positive")]
param (
	[switch] $UseExisting
)

# Initialization
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )
Enter-Test -Private -Pester

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
	Describe 'Get-NetworkRange' {
		It 'Returns an array of IPAddress' {
			Get-NetworkRange 1.2.3.4/32 -IncludeNetworkAndBroadcast | Should -BeOfType [ipaddress]
		}

		It 'Returns 255.255.255.255 when passed 255.255.255.255/32' {
			$Range = Get-NetworkRange 0/30
			$Range -contains '0.0.0.1' | Should -BeTrue
			$Range -contains '0.0.0.2' | Should -BeTrue

			$Range = Get-NetworkRange 0.0.0.0/30
			$Range -contains '0.0.0.1' | Should -BeTrue
			$Range -contains '0.0.0.2' | Should -BeTrue

			$Range = Get-NetworkRange 0.0.0.0 255.255.255.252
			$Range -contains '0.0.0.1' | Should -BeTrue
			$Range -contains '0.0.0.2' | Should -BeTrue
		}

		It 'Accepts pipeline input' {
			'20/24' | Get-NetworkRange | Select-Object -First 1 | Should -Be '20.0.0.1'
		}

		It 'Throws an error if passed something other than an IPAddress' {
			{ Get-NetworkRange "abcd" } | Should -Throw
		}

		It 'Returns correct values when used with Start and End parameters' {
			$StartIP = [ipaddress] '192.168.1.1'
			$EndIP = [ipaddress] '192.168.2.10'
			$Assertion = Get-NetworkRange -Start $StartIP -End $EndIP

			$Assertion.Count | Should -BeExactly 266
			$Assertion[0].IPAddressToString | Should -Be '192.168.1.1'
			$Assertion[-1].IPAddressToString | Should -Be '192.168.2.10'
		}

		It 'Example <Number> is valid' -TestCases (
			(Get-Help Get-NetworkRange).Examples.Example.Code | ForEach-Object -Begin {
				[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
					"PSUseDeclaredVarsMoreThanAssignment", "", Justification = "FalsePositive")]
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

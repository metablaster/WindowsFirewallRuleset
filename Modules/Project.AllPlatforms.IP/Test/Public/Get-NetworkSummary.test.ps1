
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

#region:TestFileHeader
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Number', Justification = 'Likely false positive')]
param (
	[bool] $UseExisting
)

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}

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

InModuleScope Project.AllPlatforms.IP {
	Describe 'Get-NetworkSummary' {
		It 'Returns an object tagged with the type Project.AllPlatforms.IP.NetworkSummary' {
			$NetworkSummary = Get-NetworkSummary 0/24
			$NetworkSummary.PSTypeNames -contains 'Project.AllPlatforms.IP.NetworkSummary' | Should -Be $true
		}

		It 'Identifies ranges with a first octet from 0 to 127 as class A' {
			(Get-NetworkSummary 0/24).Class | Should -Be 'A'
			(Get-NetworkSummary 127/24).Class | Should -Be 'A'
		}

		It 'Identifies ranges with a first octet from 128 to 191 as class B' {
			(Get-NetworkSummary 128/24).Class | Should -Be 'B'
			(Get-NetworkSummary 191/24).Class | Should -Be 'B'
		}

		It 'Identifies ranges with a first octet of 192 to 223 as class C' {
			(Get-NetworkSummary 192/24).Class | Should -Be 'C'
			(Get-NetworkSummary 223/24).Class | Should -Be 'C'
		}

		It 'Identifies ranges with a first octet of 224 to 239 as class D' {
			(Get-NetworkSummary 224/24).Class | Should -Be 'D'
			(Get-NetworkSummary 239/24).Class | Should -Be 'D'
		}

		It 'Identifies ranges with a first octet of 240 to 255 as class E' {
			(Get-NetworkSummary 240/24).Class | Should -Be 'E'
			(Get-NetworkSummary 255/24).Class | Should -Be 'E'
		}

		It 'Identifies 10/8 as a private range' {
			(Get-NetworkSummary 10/8).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 10.0.0.0/8).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 10.0.0.0 255.0.0.0).IsPrivate | Should -BeTrue
		}

		It 'Identifies 172.16/12 as a private range' {
			(Get-NetworkSummary 172.16/12).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 172.16.0.0/12).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 172.16.0.0 255.240.0.0).IsPrivate | Should -BeTrue
		}

		It 'Identifies 192.168/16 as a private range' {
			(Get-NetworkSummary 192.168/16).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 192.168.0.0/16).IsPrivate | Should -BeTrue
			(Get-NetworkSummary 192.168.0.0 255.255.0.0).IsPrivate | Should -BeTrue
		}

		It 'Accepts pipeline input' {
			('20/24' | Get-NetworkSummary).NetworkAddress | Should -Be '20.0.0.0'
		}

		It 'Throws an error if passed something other than an IPAddress' {
			{ Get-NetworkSummary 'abcd' } | Should -Throw
		}

		It 'Example <Number> is valid' -TestCases (
			(Get-Help Get-NetworkSummary).Examples.Example.Code | ForEach-Object -Begin {
				[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignment', '', Justification = 'FalsePositive')]
				$Number = 1
			} -Process {
				@{ Number = $Number++; Code = $_ }
			}
		) {
			param (
				$Number,
				$Code
			)

			$ScriptBlock = [ScriptBlock]::Create($Code.Trim())
			$ScriptBlock | Should -Not -Throw
		}
	}
}

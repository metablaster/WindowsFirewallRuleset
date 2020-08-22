
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

if (-not $UseExisting)
{
	$moduleBase = $psscriptroot.Substring(0, $psscriptroot.IndexOf("\test"))
	$stubBase = Resolve-Path (Join-Path $moduleBase "test*\stub\*")

	if ($null -ne $stubBase)
	{
		$stubBase | Import-Module -Force
	}

	Import-Module $moduleBase -Force
}
#endregion

InModuleScope Indented.Net.IP {
	Describe 'Test-SubnetMember' {
		It 'Returns a Boolean' {
			Test-SubnetMember 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/8 | Should -BeOfType [bool]
		}

		It 'Returns true if the subject falls within the object network' {
			Test-SubnetMember 1.2.3.4 -ObjectIPAddress 1.2.3.0/24 | Should -BeTrue
		}

		It 'Returns false if the subject does fall within the object network' {
			Test-SubnetMember 1.2.3.4 -ObjectIPAddress 2.0.0.0/24 | Should -BeFalse
		}

		It 'Throws an error if passed something other than an IPAddress for Subject or Object' {
			{ Test-SubnetMember -SubjectIPAddress 'abcd' -ObjectIPAddress 10.0.0.0/8 } | Should -Throw
			{ Test-SubnetMember -SubjectIPAddress 10.0.0.0/8 -ObjectIPAddress 'abcd' } | Should -Throw
		}

		It 'Example <Number> is valid' -TestCases (
			(Get-Help Test-SubnetMember).Examples.Example.Code | ForEach-Object -Begin {
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


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

Describe 'ConvertTo-Network' {
	BeforeAll {
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSUseDeclaredVarsMoreThanAssignment", "Module", Justification = "False Positive")]
		$Module = @{
			ModuleName = 'Ruleset.IP'
		}

		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSUseDeclaredVarsMoreThanAssignment", "MaskTable", Justification = "False Positive")]
		$MaskTable = @(
			@{ MaskLength = 0; Mask = '0.0.0.0' }
			@{ MaskLength = 1; Mask = '128.0.0.0' }
			@{ MaskLength = 2; Mask = '192.0.0.0' }
			@{ MaskLength = 3; Mask = '224.0.0.0' }
			@{ MaskLength = 4; Mask = '240.0.0.0' }
			@{ MaskLength = 5; Mask = '248.0.0.0' }
			@{ MaskLength = 6; Mask = '252.0.0.0' }
			@{ MaskLength = 7; Mask = '254.0.0.0' }
			@{ MaskLength = 8; Mask = '255.0.0.0' }
			@{ MaskLength = 9; Mask = '255.128.0.0' }
			@{ MaskLength = 10; Mask = '255.192.0.0' }
			@{ MaskLength = 11; Mask = '255.224.0.0' }
			@{ MaskLength = 12; Mask = '255.240.0.0' }
			@{ MaskLength = 13; Mask = '255.248.0.0' }
			@{ MaskLength = 14; Mask = '255.252.0.0' }
			@{ MaskLength = 15; Mask = '255.254.0.0' }
			@{ MaskLength = 16; Mask = '255.255.0.0' }
			@{ MaskLength = 17; Mask = '255.255.128.0' }
			@{ MaskLength = 18; Mask = '255.255.192.0' }
			@{ MaskLength = 19; Mask = '255.255.224.0' }
			@{ MaskLength = 20; Mask = '255.255.240.0' }
			@{ MaskLength = 21; Mask = '255.255.248.0' }
			@{ MaskLength = 22; Mask = '255.255.252.0' }
			@{ MaskLength = 23; Mask = '255.255.254.0' }
			@{ MaskLength = 24; Mask = '255.255.255.0' }
			@{ MaskLength = 25; Mask = '255.255.255.128' }
			@{ MaskLength = 26; Mask = '255.255.255.192' }
			@{ MaskLength = 27; Mask = '255.255.255.224' }
			@{ MaskLength = 28; Mask = '255.255.255.240' }
			@{ MaskLength = 29; Mask = '255.255.255.248' }
			@{ MaskLength = 30; Mask = '255.255.255.252' }
			@{ MaskLength = 31; Mask = '255.255.255.254' }
			@{ MaskLength = 32; Mask = '255.255.255.255' }
		)
	}

	It 'Translates the string 0/0 to 0.0.0.0/0 (mask 0.0.0.0)' {
		$Network = InModuleScope @module { ConvertTo-Network 0/0 }

		$Network.IPAddress | Should -Be '0.0.0.0'
		$Network.SubnetMask | Should -Be '0.0.0.0'
		$Network.MaskLength | Should -Be 0
	}

	It 'Translates the string 1.2/27 to 1.2.0.0/27 (mask 255.255.255.224)' {
		$Network = InModuleScope @module { ConvertTo-Network 1.2/27 }

		$Network.IPAddress | Should -Be '1.2.0.0'
		$Network.SubnetMask | Should -Be '255.255.255.224'
		$Network.MaskLength | Should -Be 27
	}

	It 'Translates a string containing "3.4.5 255.255.0.0" to 3.4.5.0/16 (mask 255.255.0.0)' {
		$Network = InModuleScope @module { ConvertTo-Network "3.4.5 255.255.0.0" }

		$Network.IPAddress | Should -Be '3.4.5.0'
		$Network.SubnetMask | Should -Be '255.255.0.0'
		$Network.MaskLength | Should -Be 16
	}

	It 'Translates IPAddress argument 1.2.3.4 and SubnetMask argument 24 to 1.2.3.4/24 (mask 255.255.255.0)' {
		$Network = InModuleScope @module { ConvertTo-Network 1.2.3.4 -SubnetMask 24 }

		$Network.IPAddress | Should -Be '1.2.3.4'
		$Network.SubnetMask | Should -Be '255.255.255.0'
		$Network.MaskLength | Should -Be 24
	}

	It 'Translates IPAddress argument 212.44.56.21 and SubnetMask argument 255.255.128.0 to 212.44.56.21/17' {
		$Network = InModuleScope @module { ConvertTo-Network 212.44.56.21 255.255.128.0 }

		$Network.IPAddress | Should -Be '212.44.56.21'
		$Network.SubnetMask | Should -Be '255.255.128.0'
		$Network.MaskLength | Should -Be 17
	}

	It 'Translates IPAddres argument 1.0.0.0 with no SubnetMask argument to 1.0.0.0/32 (mask 255.255.255.255)' {
		$Network = InModuleScope @module { ConvertTo-Network 1.0.0.0 }

		$Network.IPAddress | Should -Be '1.0.0.0'
		$Network.SubnetMask | Should -Be '255.255.255.255'
		$Network.MaskLength | Should -Be 32
	}

	It 'Converts CIDR formatted subnets from <MaskLength> to <Mask>' -TestCases $MaskTable {
		# BUG: Unable to suppress
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSReviewUnusedParameter", "MaskLength", Justification = "False Positive")]
		param (
			$MaskLength,

			$Mask
		)

		$ErrorRecord = $null
		try
		{
			$Network = InModuleScope @module { ConvertTo-Network "10.0.0.0/$MaskLength" }
		}
		catch
		{
			$ErrorRecord = $_
		}

		$ErrorRecord | Should -BeNullOrEmpty
		$Network.SubnetMask | Should -Be $Mask
	}

	It 'Converts dotted-decimal formatted subnets from <Mask> to <MaskLength>' -TestCases $MaskTable {
		# BUG: Unable to suppress
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSReviewUnusedParameter", "Mask", Justification = "False Positive")]
		param (
			$MaskLength,

			$Mask
		)

		$ErrorRecord = $null
		try
		{
			$Network = InModuleScope @module { ConvertTo-Network 10.0.0.0 $Mask }
		}
		catch
		{
			$ErrorRecord = $_
		}

		$ErrorRecord | Should -BeNullOrEmpty
		$Network.MaskLength | Should -Be $MaskLength
	}

	It 'Pads a partial subnet mask' {
		$Network = InModuleScope @module { ConvertTo-Network "10.0.0.0" "255.255" }

		$Network.SubnetMask | Should -Be '255.255.0.0'
	}

	It 'Raises a terminating error when the IP address is invalid' {
		{ InModuleScope @module { ConvertTo-Network InvalidIP/24 } } | Should -Throw -ErrorId 'InvalidIPAddress,ConvertTo-Network'
	}

	It 'Raises a terminating error when the mask length is invalid' {
		{ InModuleScope @module { ConvertTo-Network "10.0.0.0/33" } } | Should -Throw -ErrorId 'InvalidMaskLength,ConvertTo-Network'
		{ InModuleScope @module { ConvertTo-Network "10.0.0.0/-1" } } | Should -Throw -ErrorId 'InvalidMaskLength,ConvertTo-Network'
	}

	It 'Raises a terminating error when the subnet mask is invalid' {
		{ InModuleScope @module { ConvertTo-Network "10.0.0.0" "255.255.255.1" } } | Should -Throw -ErrorId 'InvalidSubnetMask,ConvertTo-Network'
	}
}

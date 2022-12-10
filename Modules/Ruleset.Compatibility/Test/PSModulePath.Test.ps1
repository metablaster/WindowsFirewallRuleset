
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

Describe "Test Add-WindowsPSModulePath cmdlet" {
	BeforeAll {
		Import-Module -Force "$ScriptPath\..\Ruleset.Compatibility.psd1"
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSUseDeclaredVarsMoreThanAssignment", "OriginalPsModulePath", Justification = "False positive")]
		$OriginalPsModulePath = $env:PSModulePath
	}

	AfterAll {
		Remove-Module -Force Ruleset.Compatibility
		$env:PSModulePath = $OriginalPsModulePath
	}

	It 'Validate that the system environment variable PSModulePath components are added to the $ENV:PSModulePath' {
		Add-WindowsPSModulePath | Should -BeNullOrEmpty
		# a table of the current PSModulePath components
		[hashtable] $CurrentPathTable = @{}
		$env:PSModulePath.Split(";").foreach{ $CurrentPathTable[$_] = $true }
		$WindowsPSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", [System.EnvironmentVariableTarget]::Machine)
		$AllComponentsInPath = $true

		# Verify that all of the path components in the machine-scoped PSModulePath are
		# also in the session module path.
		foreach ($Path in $WindowsPSModulePath.Split(";"))
		{
			if ( -not $CurrentPathTable.ContainsKey($Path) )
			{
				$AllComponentsInPath = $false
				break
			}
		}

		$AllComponentsInPath | Should -Be $true
	}
}

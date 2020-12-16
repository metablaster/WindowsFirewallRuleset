
# Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved
# Licensed under the MIT License

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

Describe "Test Add-WindowsPSModulePath cmdlet" {
	BeforeAll {
		Import-Module -Force "$ScriptPath\..\Ruleset.Compatibility.psd1"
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
		$env:PSModulePath.Split(';').foreach{ $CurrentPathTable[$_] = $true }
		$WindowsPSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", [System.EnvironmentVariableTarget]::Machine)
		$AllComponentsInPath = $true

		# Verify that all of the path components in the machine-scoped PSModulePath are
		# also in the session module path.
		foreach ($Path in $WindowsPSModulePath.Split(';'))
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

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

Describe "Test Add-WindowsPSModulePath cmdlet" {
	BeforeAll {
		Import-Module -Force "$scriptPath\..\bin\WindowsCompatibility.psd1"
		$originalPsModulePath = $env:PSModulePath
	}

	AfterAll {
		Remove-Module -Force WindowsCompatibility
		$env:PSModulePath = $originalPsModulePath
	}

	It 'Validate that the system environment variable PSModulePath components are added to the $ENV:PSModulePath' {
		Add-WindowsPSModulePath | Should -BeNullOrEmpty
		# a table of the current PSModulePath components
		[hashtable] $currentPathTable = @{}
		$env:PSModulePath.split(';').foreach{ $currentPathTable[$_] = $true }
		$WindowsPSModulePath = [System.Environment]::GetEnvironmentVariable("psmodulepath", [System.EnvironmentVariableTarget]::Machine)
		$allComponentsInPath = $true
		# Verify that all of the path components in the machine-scoped PSModulePath are
		# also in the session module path.
		foreach ($pc in $WindowsPSModulePath.Split(';'))
		{
			if ( -not $currentPathTable.ContainsKey($pc) )
			{
				$allComponents = $false
			}
		}
		$allComponents | Should -Be $true:w
	}
}

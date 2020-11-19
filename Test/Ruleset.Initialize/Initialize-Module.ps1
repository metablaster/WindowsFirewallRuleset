
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
.SYNOPSIS
Unit test for Initialize-Module

.DESCRIPTION
Unit test for Initialize-Module

.EXAMPLE
PS> .\Initialize-Module.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Module.ps1

.OUTPUTS
None. Initialize-Module.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

if ($Force -or $PSCmdlet.ShouldContinue("Possible modify installed modules", "Accept dangerous unit test"))
{
	[string] $Repository = "PSGallery"

	Start-Test "Initialize-Module PackageManagement"
	Initialize-Module @{ ModuleName = "PackageManagement"; ModuleVersion = $RequirePackageManagementVersion } `
		-Repository $Repository -Trusted

	Start-Test "Initialize-Module PowerShellGet"
	Initialize-Module @{ ModuleName = "PowerShellGet"; ModuleVersion = $RequirePowerShellGetVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "PowerShellGet >= $($RequirePowerShellGetVersion.ToString()) is required otherwise updating modules might fail"

	Start-Test "Initialize-Module posh-git"
	Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = $RequirePoshGitVersion }  `
		-Repository $Repository -Trusted -AllowPrerelease `
		-InfoMessage "posh-git is recommended for better git experience in PowerShell"

	Start-Test "Initialize-Module PSScriptAnalyzer"
	Initialize-Module @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = $RequireAnalyzerVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "PSScriptAnalyzer >= $($RequireAnalyzerVersion.ToString()) is required otherwise code will start missing while editing"

	Start-Test "Initialize-Module Pester"
	$Result = Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = $RequirePesterVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "Pester is required to run pester tests"

	$Result
	Test-Output $Result -Command Initialize-Module
}

Update-Log
Exit-Test

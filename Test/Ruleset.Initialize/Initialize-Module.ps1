
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Test correctness of Initialize-Module function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Initialize-Module.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Module.ps1

.OUTPUTS
None. Initialize-Module.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Initialize-Module"

if ($Force -or $PSCmdlet.ShouldContinue("Possible modify installed modules", "Accept potentially dangerous unit test"))
{
	if (!($ProjectCheck -and $ModulesCheck))
	{
		Write-Error -Category NotEnabled -TargetObject $ThisScript `
			-Message "This unit test requires ProjectCheck and ModulesCheck variables to be set"
		return
	}

	[string] $Repository = "PSGallery"

	Start-Test "PackageManagement"
	Initialize-Module @{ ModuleName = "PackageManagement"; ModuleVersion = $RequirePackageManagementVersion } `
		-Repository $Repository -Trusted

	Start-Test "PowerShellGet"
	Initialize-Module @{ ModuleName = "PowerShellGet"; ModuleVersion = $RequirePowerShellGetVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "PowerShellGet >= $($RequirePowerShellGetVersion.ToString()) is required otherwise updating modules might fail"

	Start-Test "posh-git"
	Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = $RequirePoshGitVersion }  `
		-Repository $Repository -Trusted -AllowPrerelease `
		-InfoMessage "posh-git is recommended for better git experience in PowerShell"

	Start-Test "PSScriptAnalyzer"
	Initialize-Module @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = $RequireAnalyzerVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "PSScriptAnalyzer >= $($RequireAnalyzerVersion.ToString()) is required otherwise code will start missing while editing"

	Start-Test "Pester"
	$Result = Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = $RequirePesterVersion } `
		-Repository $Repository -Trusted `
		-InfoMessage "Pester is required to run pester tests"

	$Result
	Test-Output $Result -Command Initialize-Module
}

Update-Log
Exit-Test

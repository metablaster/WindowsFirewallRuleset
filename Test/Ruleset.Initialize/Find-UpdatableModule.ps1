
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Unit test for Find-UpdatableModule

.DESCRIPTION
Test correctness of Find-UpdatableModule function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Find-UpdatableModule.ps1

.INPUTS
None. You cannot pipe objects to Find-UpdatableModule.ps1

.OUTPUTS
None. Find-UpdatableModule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test -Private

Start-Test "Find-UpdatableModule"
$Result = Find-UpdatableModule
$Result

Start-Test "Test-Output"
$Result | Test-Output -Command Find-UpdatableModule

Start-Test "'PowerShellGet' | Find-UpdatableModule"
"PowerShellGet" | Find-UpdatableModule

Start-Test "Find-UpdatableModule -Module 'PowerShellGet'"
Find-UpdatableModule -Module "PowerShellGet"

Start-Test 'Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US'
Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US

Start-Test '@{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule'
$Result = @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule
$Result

Start-Test "Get-TypeName"
$Result | Get-TypeName

Start-Test 'Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }'
Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }

Start-Test 'Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")'
$Result = Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")
$Result

Start-Test '@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule'
@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule

Test-Output $Result -Command Find-UpdatableModule

Update-Log
Exit-Test

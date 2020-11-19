
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
Unit test for Find-UpdatableModule

.DESCRIPTION
Unit test for Find-UpdatableModule

.EXAMPLE
PS> .\Find-UpdatableModule.ps1

.INPUTS
None. You cannot pipe objects to Find-UpdatableModule.ps1

.OUTPUTS
None. Find-UpdatableModule.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

Enter-Test -Private

Start-Test "Find-UpdatableModule"
$Result = Find-UpdatableModule @Logs
$Result

Start-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Start-Test "'PowerShellGet' | Find-UpdatableModule"
"PowerShellGet" | Find-UpdatableModule @Logs

Start-Test "Find-UpdatableModule -Module 'PowerShellGet'"
Find-UpdatableModule -Module "PowerShellGet" @Logs

Start-Test 'Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US'
Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US @Logs

Start-Test '@{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule'
$Result = @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule @Logs
$Result

Start-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Start-Test 'Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }'
Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } @Logs

Start-Test 'Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")'
$Result = Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") @Logs
$Result

Start-Test '@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule'
@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule @Logs

Test-Output $Result -Command Find-UpdatableModule @Logs

Update-Log
Exit-Test

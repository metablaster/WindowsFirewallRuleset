
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

#
# Unit test for Find-UpdatableModule
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

New-Test "Find-UpdatableModule"
$Result = Find-UpdatableModule @Logs
$Result

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

New-Test "'PowerShellGet' | Find-UpdatableModule"
"PowerShellGet" | Find-UpdatableModule @Logs

New-Test "Find-UpdatableModule -Module 'PowerShellGet'"
Find-UpdatableModule -Module "PowerShellGet" @Logs

New-Test 'Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US'
Find-UpdatableModule "PowerShellGet" -UICulture ja-JP, en-US @Logs

New-Test '@{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule'
$Result = @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Find-UpdatableModule @Logs
$Result

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

New-Test 'Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }'
Find-UpdatableModule -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } @Logs

New-Test 'Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")'
$Result = Find-UpdatableModule @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") @Logs
$Result

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

New-Test '@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule'
@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Find-UpdatableModule @Logs

Update-Log
Exit-Test

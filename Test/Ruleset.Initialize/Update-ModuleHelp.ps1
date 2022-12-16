
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Unit test for Update-ModuleHelp

.DESCRIPTION
Test correctness of Update-ModuleHelp function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Update-ModuleHelp.ps1

.INPUTS
None. You cannot pipe objects to Update-ModuleHelp.ps1

.OUTPUTS
None. Update-ModuleHelp.ps1 does not generate any output

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
. $PSScriptRoot\..\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

Start-Test "Update-ModuleHelp"
$Result = Update-ModuleHelp
$Result

Test-Output $Result -Command Update-ModuleHelp

Start-Test "Update-ModuleHelp -Name 'PowerShellGet'"
Update-ModuleHelp -Name "PowerShellGet"

Start-Test 'Update-ModuleHelp "PowerShellGet" -UICulture ja-JP, en-US'
Update-ModuleHelp "PowerShellGet" -UICulture ja-JP, en-US

Start-Test '@{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Update-ModuleHelp'
@{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" } | Update-ModuleHelp

Start-Test 'Update-ModuleHelp -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }'
Update-ModuleHelp -FullyQualifiedName @{ ModuleName = "WindowsErrorReporting"; ModuleVersion = "1.0" }

Start-Test 'Update-ModuleHelp @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")'
$Result = Update-ModuleHelp @("PowerShellGet", "PackageManagement", "PSScriptAnalyzer")
$Result

Start-Test '@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Update-ModuleHelp'
@("PowerShellGet", "PackageManagement", "PSScriptAnalyzer") | Update-ModuleHelp

Start-Test "Get-TypeName"
$Result | Get-TypeName

Test-Output $Result -Command Update-ModuleHelp

Update-Log
Exit-Test

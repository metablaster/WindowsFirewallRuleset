
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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
# Unit test for Test-ModuleRecommendation
#
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test
[string] $Repository = "powershellgallery.com"

New-Test "Test-ModuleRecommendation PackageManagement"
Test-ModuleRecommendation @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository $Repository @Logs

New-Test "Test-ModuleRecommendation PowerShellGet"
Test-ModuleRecommendation @{ ModuleName = "PowerShellGet"; ModuleVersion = "2.2.4" } -Repository $Repository `
	-InfoMessage "PowerShellGet >= 2.2.4 is required otherwise updating modules might fail" @Logs

New-Test "Test-ModuleRecommendation posh-git"
if (Test-ModuleRecommendation @{ ModuleName = "posh-git"; ModuleVersion = "0.7.3" } -Repository $Repository -AllowPrerelease `
		-InfoMessage "posh-git is recommended for better git experience in PowerShell" @Logs)
{
	Add-PoshGitToProfile -AllHosts
}

New-Test "Test-ModuleRecommendation PSScriptAnalyzer"
Test-ModuleRecommendation @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1" } -Repository $Repository `
	-InfoMessage "PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing" @Logs

New-Test "Test-ModuleRecommendation Pester"
$Result = Test-ModuleRecommendation @{ ModuleName = "Pester"; ModuleVersion = "5.0.3" } -Repository $Repository `
	-InfoMessage "Pester is required to run pester tests" @Logs

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

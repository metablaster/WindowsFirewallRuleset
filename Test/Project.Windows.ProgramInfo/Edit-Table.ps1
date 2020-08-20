
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
# Unit test for Edit-Table
# TODO: can we use Requires -PSSnapin here for Initialize-Table?
#
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	'PSAvoidGlobalVars', '', Justification = 'Global variable used for testing only')]
param()

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}

# Check requirements for this project
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

$User = "haxor"

New-Test "Good system path"
Initialize-Table @Logs
Edit-Table "%SystemRoot%\System32\WindowsPowerShell\v1.0" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Bad system path"
Initialize-Table @Logs
Edit-Table "%ProgramFiles(x86)%\Microsoft Help Viewer\v2.3345345" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Good user profile path"
Initialize-Table @Logs
Edit-Table "C:\\Users\$User\\GitHub\WindowsFirewallRuleset\" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Bad user profile path"
Initialize-Table @Logs
Edit-Table "%HOME%\source\\repos\WindowsFirewallRuleset\" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Get-TypeName"
# TODO: why this doesn't work?
$global:InstallTable | Get-TypeName @Logs

Update-Log
Exit-Test

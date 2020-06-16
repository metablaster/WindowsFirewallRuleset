
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
# Unit test for Update-Table
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
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

New-Test "-UserProfile switch Fill table with Greenshot"
Initialize-Table @Logs
Update-Table "Greenshot" -UserProfile @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

New-Test "Failure Test"
Initialize-Table @Logs
Update-Table "Failure" -UserProfile @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Test multiple paths"
Initialize-Table @Logs
Update-Table "Visual Studio" -UserProfile @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

New-Test "-Executables switch - Fill table with PowerShell"
Initialize-Table @Logs
Update-Table "PowerShell.exe" -Executables
$global:InstallTable | Format-Table -AutoSize @Logs

New-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

New-Test "Get-TypeName"
$global:InstallTable | Get-TypeName @Logs

Update-Log
Exit-Test

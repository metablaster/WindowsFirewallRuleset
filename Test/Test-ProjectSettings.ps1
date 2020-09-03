
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
# Unit test for ProjectSettings.ps1
#
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Check requirements
Initialize-Project -Abort

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Script level preferences"
Write-Information -Tags "Test" -MessageData "INFO: ErrorActionPreference: $ErrorActionPreference"
Write-Information -Tags "Test" -MessageData "INFO: WarningPreference: $WarningPreference"
Write-Information -Tags "Test" -MessageData "INFO: InformationPreference: $InformationPreference"
Write-Information -Tags "Test" -MessageData "INFO: VerbosePreference: $VerbosePreference"
Write-Information -Tags "Test" -MessageData "INFO: DebugPreference: $DebugPreference"

Start-Test "Module level preferences"
Write-Information -Tags "Test" -MessageData "INFO: ModuleErrorPreference: $ModuleErrorPreference"
Write-Information -Tags "Test" -MessageData "INFO: ModuleWarningPreference: $ModuleWarningPreference"
Write-Information -Tags "Test" -MessageData "INFO: ModuleInformationPreference: $ModuleInformationPreference"
Write-Information -Tags "Test" -MessageData "INFO: ModuleVerbosePreference: $ModuleVerbosePreference"
Write-Information -Tags "Test" -MessageData "INFO: ModuleDebugPreference: $ModuleDebugPreference"

Start-Test "ProjectConstants"
Write-Information -Tags "Test" -MessageData "INFO: PolicyStore: $PolicyStore"
Write-Information -Tags "Test" -MessageData "INFO: Platform: $Platform"
Write-Information -Tags "Test" -MessageData "INFO: ProjectRoot: $ProjectRoot"
Write-Information -Tags "Test" -MessageData "INFO: PSModulePath:"
Split-Path -Path $env:PSModulePath.Split(";")
Write-Information -Tags "Test" -MessageData "INFO: Force: $ForceLoad"
Write-Information -Tags "Test" -MessageData "INFO: Interface: $Interface"

Start-Test "ReadOnlyVariables"
Write-Information -Tags "Test" -MessageData "INFO: ProjectCheck: $ProjectCheck"

Start-Test "RemovableVariables"
Write-Information -Tags "Test" -MessageData "INFO: WarningStatus: $WarningStatus"
Write-Information -Tags "Test" -MessageData "INFO: ErrorStatus: $ErrorStatus"
Write-Information -Tags "Test" -MessageData "INFO: InformationLogging: $InformationLogging"
Write-Information -Tags "Test" -MessageData "INFO: WarningLogging: $WarningLogging"
Write-Information -Tags "Test" -MessageData "INFO: ErrorLogging: $ErrorLogging"
Write-Information -Tags "Test" -MessageData "INFO: ConnectionTimeout: $ConnectionTimeout"
Write-Information -Tags "Test" -MessageData "INFO: ConnectionCount: $ConnectionCount"

Exit-Test

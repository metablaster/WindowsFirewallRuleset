
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

<#
.SYNOPSIS
Unit test for Find-Installation

.DESCRIPTION
Unit test for Find-Installation

.EXAMPLE
PS> .\Find-Installation.ps1

.INPUTS
None. You cannot pipe objects to Find-Installation.ps1

.OUTPUTS
None. Find-Installation.ps1 does not generate any output

.NOTES
None.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalVars", "", Justification = "Needed in this unit test")]
[CmdletBinding()]
param ()

# Initialization
# NOTE: As Administrator because of a test with OneDrive which loads reg hive of other users
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Find-Installation 'EdgeChromium'"
Find-Installation "EdgeChromium" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

Start-Test "Install Root EdgeChromium"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

Start-Test "Find-Installation 'TeamViewer'"
Find-Installation "TeamViewer" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

Start-Test "Find-Installation 'FailureTest'"
Find-Installation "FailureTest" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

Start-Test "Find-Installation 'VisualStudio'"
Find-Installation "VisualStudio" @Logs
$global:InstallTable | Format-Table -AutoSize @Logs

Start-Test "Find-Installation 'Greenshot'"
Find-Installation "Greenshot" @Logs
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

Start-Test "Install Root Greenshot"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

Start-Test "Find-Installation 'OneDrive'"
$Result = Find-Installation "OneDrive" @Logs
$Result
$global:InstallTable | Format-Table -AutoSize @Logs

Start-Test "Install Root OneDrive"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation @Logs

Test-Output $Result -Command Find-Installation @Logs

Update-Log
Exit-Test

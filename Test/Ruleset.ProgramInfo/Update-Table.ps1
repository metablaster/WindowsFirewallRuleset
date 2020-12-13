
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
Unit test for Update-Table

.DESCRIPTION
Unit test for Update-Table

.EXAMPLE
PS> .\Update-Table.ps1

.INPUTS
None. You cannot pipe objects to Update-Table.ps1

.OUTPUTS
None. Update-Table.ps1 does not generate any output

.NOTES
None.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalVars", "", Justification = "Needed in this unit test")]
[CmdletBinding()]
param ()

#region Initialization
# NOTE: As Administrator because of a test with OneDrive which loads reg hive of other users
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "Unit test $ThisScript is enabled only when 'Develop' variable is set to `$true"
	return
}
elseif (!((Get-Command -Name Initialize-Table -EA Ignore) -and
		(Get-Command -Name Update-Table -EA Ignore) -and
		(Get-Variable -Scope Global -Name InstallTable -EA Ignore)))
{
	Write-Error -Category NotEnabled -TargetObject "Private Functions" `
		-Message "This unit test is missing required private functions, please visit Ruleset.ProgramInfo.psd1 to adjust exports"
	return
}

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

Start-Test "-UserProfile switch Fill table with Greenshot"
Initialize-Table
Update-Table -Search "Greenshot" -UserProfile
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "Failure Test"
Initialize-Table
Update-Table -Search "Failure" -UserProfile
$global:InstallTable | Format-Table -AutoSize

Start-Test "Test multiple paths"
Initialize-Table
Update-Table -Search "Visual Studio" -UserProfile
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "-Executables PowerShell.exe"
Initialize-Table
Update-Table -Search "" -Executable "PowerShell.exe"
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "-UserProfile switch Fill table with Greenshot"
Initialize-Table
Update-Table -Search "EdgeChromium" -Executable "msedge.exe"
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "-UserProfile switch Fill table with OneDrive"
Initialize-Table
$Result = Update-Table -Search "OneDrive" -UserProfile
$Result
$global:InstallTable | Format-Table -AutoSize

Test-Output $Result -Command Update-Table

Update-Log
Exit-Test

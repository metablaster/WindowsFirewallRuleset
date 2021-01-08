
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for Search-Installation

.DESCRIPTION
Test correctness of Search-Installation function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Search-Installation.ps1

.INPUTS
None. You cannot pipe objects to Search-Installation.ps1

.OUTPUTS
None. Search-Installation.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
# NOTE: As Administrator because of a test with OneDrive which loads reg hive of other users
#Requires -RunAsAdministrator

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalVars", "", Justification = "Needed in this unit test")]
[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "Unit test $ThisScript is enabled only when 'Develop' variable is set to `$true"
	return
}

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

Start-Test "Search-Installation 'EdgeChromium'"
Search-Installation "EdgeChromium"
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Root EdgeChromium"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "Search-Installation 'FailureTest'"
Search-Installation "FailureTest"
$global:InstallTable | Format-Table -AutoSize

Start-Test "Search-Installation 'VisualStudio'"
Search-Installation "VisualStudio"
$global:InstallTable | Format-Table -AutoSize

Start-Test "Search-Installation 'Greenshot'"
Search-Installation "Greenshot"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "Install Root Greenshot"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Start-Test "Search-Installation 'OneDrive'"
$Result = Search-Installation "OneDrive"
$Result
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Root OneDrive"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Test-Output $Result -Command Search-Installation

Update-Log
Exit-Test

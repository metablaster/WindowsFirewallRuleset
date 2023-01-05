
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Unit test for Confirm-Installation

.DESCRIPTION
Test correctness of Confirm-Installation function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Confirm-Installation.ps1

.INPUTS
None. You cannot pipe objects to Confirm-Installation.ps1

.OUTPUTS
None. Confirm-Installation.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Confirm-Installation"

$VSCodeRoot = ""
$PowerShell86Root = ""
$NETFrameworkRoot = ""

$OneDrive = "unknown"
$OfficeRoot = "%ProgramFiles(x866666)%\Microsoft Office\root\Office16"
$TestBadVariable = "%UserProfile%\crazyFolder"
$TestBadVariable2 = "%UserProfile%\crazyFolder"

$PSDefaultParameterValues["Confirm-Installation:Session"] = $SessionInstance
$PSDefaultParameterValues["Confirm-Installation:CimSession"] = $CimServer

if ($Domain -ne [System.Environment]::MachineName)
{
	# Uses Update-Table
	Start-Test "Remote VSCode"
	Confirm-Installation "VSCode" ([ref] $VSCodeRoot)

	# Uses Edit-Table
	Start-Test "Remote 'PowerShell86'"
	Confirm-Installation "PowerShell86" ([ref] $PowerShell86Root)

	# Uses custom case
	Start-Test "Remote 'NETFramework'"
	Confirm-Installation "NETFramework" ([ref] $NETFrameworkRoot)
}
else
{
	Start-Test "'VSCode' $VSCodeRoot"
	$Result = Confirm-Installation "VSCode" ([ref] $VSCodeRoot)
	$Result

	Start-Test "'OneDrive' $OneDrive"
	Confirm-Installation "OneDrive" ([ref] $OneDrive)

	Start-Test "'MicrosoftOffice' $OfficeRoot"
	Confirm-Installation "MicrosoftOffice" ([ref] $OfficeRoot)

	Start-Test "'VisualStudio' $TestBadVariable"
	Confirm-Installation "VisualStudio" ([ref] $TestBadVariable)

	Start-Test "'FailureTest' $TestBadVariable2" -Force
	Confirm-Installation "FailureTest" ([ref] $TestBadVariable2) -EV +TestEV -EA SilentlyContinue
	Restore-Test

	Test-Output $Result -Command Confirm-Installation
}

Update-Log
Exit-Test

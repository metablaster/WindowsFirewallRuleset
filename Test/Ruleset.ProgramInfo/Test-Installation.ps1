
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
Unit test for Test-Installation

.DESCRIPTION
Unit test for Test-Installation

.EXAMPLE
PS> .\Test-Installation.ps1

.INPUTS
None. You cannot pipe objects to Test-Installation.ps1

.OUTPUTS
None. Test-Installation.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

$OfficeRoot = "%ProgramFiles(x866666)%\Microsoft Office\root\Office16"
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewerZZZZ"
$TestBadVariable = "%UserProfile%\crazyFolder"
$TestBadVariable2 = "%UserProfile%\crazyFolder"
$OneDrive = "unknown"

Start-Test "Test-Installation 'OneDrive' $OneDrive"
$Result = Test-Installation "OneDrive" ([ref] $OneDrive)
$Result

Start-Test "Test-Installation 'MicrosoftOffice' $OfficeRoot"
Test-Installation "MicrosoftOffice" ([ref] $OfficeRoot)

Start-Test "Test-Installation 'TeamViewer' $TeamViewerRoot"
Test-Installation "TeamViewer" ([ref] $TeamViewerRoot)

Start-Test "Test-Installation 'VisualStudio' $TestBadVariable"
Test-Installation "VisualStudio" ([ref] $TestBadVariable)

Start-Test "Test-Installation 'BadVariable' $TestBadVariable2"
Test-Installation "BadVariable" ([ref] $TestBadVariable2)

Test-Output $Result -Command Test-Installation

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Unit test for Show-Table

.DESCRIPTION
Test correctness of Show-Table function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Show-Table.ps1

.INPUTS
None. You cannot pipe objects to Show-Table.ps1

.OUTPUTS
None. Show-Table.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test -Private "Show-Table"

Start-Test "Multiple paths - Visual Studio"
Initialize-Table
Update-Table -Search "Visual Studio" -UserProfile
Show-Table

Start-Test "-Executable PowerShell.exe"
Initialize-Table
Update-Table -Executable "PowerShell.exe"
Show-Table

Start-Test "-Search EdgeChromium -Executable msedge.exe"
Initialize-Table
Update-Table -Search "EdgeChromium" -Executable "msedge.exe"
$Result = Show-Table
$Result

Start-Test "Good user profile path"
Initialize-Table
Edit-Table "C:\\Users\$TestUser\\AppData\\Roaming\\"
Show-Table

Start-Test "Good system path"
Initialize-Table
Edit-Table "%SystemRoot%\System32\WindowsPowerShell\v1.0"
Show-Table

Start-Test "Failure Test"
Initialize-Table
Update-Table "Failure" -UserProfile
Show-Table

Test-Output $Result -Command Show-Table

Update-Log
Exit-Test

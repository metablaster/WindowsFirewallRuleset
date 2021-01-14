
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Unit test for Select-EnvironmentVariable

.DESCRIPTION
Test correctness of Select-EnvironmentVariable function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Select-EnvironmentVariable.ps1

.INPUTS
None. You cannot pipe objects to Select-EnvironmentVariable.ps1

.OUTPUTS
None. Select-EnvironmentVariable.ps1 does not generate any output

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

# TODO: All except ExpandProperty will be blank in bulk test run in this unit
Enter-Test "Select-EnvironmentVariable"

# $private:PSDefaultParameterValues.Add("Select-EnvironmentVariable:IncludeFile", $true)

#
# Scope test
#
New-Section "Scope test"

Start-Test "UserProfile -Force"
# Only one -Force is needed
Select-EnvironmentVariable -From UserProfile -Force

Start-Test "WhiteList"
$Result = Select-EnvironmentVariable -From WhiteList
$Result

Start-Test "FullyQualified"
Select-EnvironmentVariable -From FullyQualified

Start-Test "Rooted"
Select-EnvironmentVariable -From Rooted

Start-Test "FileSystem -Exact"
Select-EnvironmentVariable -From FileSystem -Exact

Start-Test "Relative"
Select-EnvironmentVariable -From Relative

Start-Test "BlackList"
Select-EnvironmentVariable -From BlackList

Start-Test "All"
Select-EnvironmentVariable -From All

#
# By value
#
New-Section "By value"

Start-Test "for C:"
Select-EnvironmentVariable -Value "C:"

Start-Test "for C:\Program Files -Exact"
Select-EnvironmentVariable -Value "C:\Program Files" -Exact

# Try again name select with Exact names
Start-Test "All -Force -Exact | Out-Null"
Select-EnvironmentVariable -From All -Force -Exact | Out-Null

# Make sure input works for both cases with and without: %%
Start-Test "for C: -Exact"
Select-EnvironmentVariable -Value "C:" -Exact

Start-Test "for C:\Program Files"
Select-EnvironmentVariable -Value "C:\Program Files"

#
# By name
#
New-Section "By name"

Start-Test "-Name DOESNOTEXIST" -Expected "FAIL"
Select-EnvironmentVariable -Name "DOESNOTEXIST"

Start-Test "-Name LOGONSERVER"
Select-EnvironmentVariable -Name "LOGONSERVER"

Start-Test "-Name %HOMEPATH% -Exact" -Expected "FAIL"
Select-EnvironmentVariable -Name "%HOMEPATH%" -Exact

Test-Output $Result -Command Select-EnvironmentVariable

#
# Select and sort example
#
New-Section "Select and sort example"

Start-Test "Select Name (WhiteList)"
$Result | Select-Object -ExpandProperty Name

Start-Test "Select Value (WhiteList)"
$Result | Select-Object -ExpandProperty Value

Start-Test "WhiteList | Sort"
Select-EnvironmentVariable -From WhiteList | Sort-Object -Descending { $_.Value.Length }

#
# null or empty
#
New-Section "null or empty"

Start-Test "Select Name null"
Select-EnvironmentVariable -Name $null

Start-Test "Select Name empty"
Select-EnvironmentVariable -Name ""

Start-Test "Select Value null"
Select-EnvironmentVariable -Value $null

Start-Test "Select Value empty"
Select-EnvironmentVariable -Value ""

#
# Wildcard pattern
#
New-Section "Wildcard pattern"

Start-Test "-Name *"
Select-EnvironmentVariable -Name *

Start-Test "*proces[so]o?*"
Select-EnvironmentVariable -Name "*proces[so]o?*"

Start-Test "-Value *Program* -Exact"
Select-EnvironmentVariable -Value "*Program*" -Exact

Start-Test "-Value C:\uSe[er]?*"
Select-EnvironmentVariable -Value "C:\uSe[er]?*"

#
# Selection
#
New-Section "Selection"

Start-Test "-Name *user* -Property Name"
Select-EnvironmentVariable -Name *user* -Property Name

Start-Test "-Name *user* -Property Name -From WhiteList"
Select-EnvironmentVariable -Name *user* -Property Name -From WhiteList

Start-Test "-Name *user* -Property Value"
Select-EnvironmentVariable -Name *user* -Property Value

Start-Test "-Name *user* -Property Value -From WhiteList"
Select-EnvironmentVariable -Name *user* -Property Value -From WhiteList

Start-Test "-Name AND -Value should FAIL"
Select-EnvironmentVariable -Name *user* -Property Value -Value *DESKTOP* -From All

Start-Test "-From UserProfile -Property Name"
Select-EnvironmentVariable -From UserProfile -Property Name

Update-Log
Exit-Test

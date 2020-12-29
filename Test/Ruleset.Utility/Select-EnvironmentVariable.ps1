
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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

.EXAMPLE
PS> .\Select-EnvironmentVariable.ps1

.INPUTS
None. You cannot pipe objects to Select-EnvironmentVariable.ps1

.OUTPUTS
None. Select-EnvironmentVariable.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# TODO: All except ExpandProperty will be blank in bulk test run in this unit
Enter-Test

# $private:PSDefaultParameterValues.Add("Select-EnvironmentVariable:IncludeFile", $true)

Start-Test "Select-EnvironmentVariable UserProfile -Force"
# Only one -Force is needed
Select-EnvironmentVariable -Scope UserProfile -Force

Start-Test "Select-EnvironmentVariable WhiteList"
$Result = Select-EnvironmentVariable -Scope WhiteList
$Result

Start-Test "Select-EnvironmentVariable FullyQualified"
Select-EnvironmentVariable -Scope FullyQualified

Start-Test "Select-EnvironmentVariable Rooted"
Select-EnvironmentVariable -Scope Rooted

Start-Test "Select-EnvironmentVariable FileSystem -Exact"
Select-EnvironmentVariable -Scope FileSystem -Exact

Start-Test "Select-EnvironmentVariable Relative"
Select-EnvironmentVariable -Scope Relative

Start-Test "Select-EnvironmentVariable BlackList"
Select-EnvironmentVariable -Scope BlackList

Start-Test "Select-EnvironmentVariable All"
Select-EnvironmentVariable -Scope All

Start-Test "Select-EnvironmentVariable HOMEPATH"
Select-EnvironmentVariable "HOMEPATH"

Start-Test "Select-EnvironmentVariable LOGONSERVER -Exact"
Select-EnvironmentVariable "LOGONSERVER" -Exact

# Make sure input works for both cases with and without: %%
Start-Test "Select-EnvironmentVariable %HOMEPATH% -Exact"
Select-EnvironmentVariable "%HOMEPATH%" -Exact

# Try again name select with Exact names
Start-Test "Select-EnvironmentVariable All -Force -Exact"
Select-EnvironmentVariable -Scope All -Force -Exact | Out-Null

Start-Test "Select-EnvironmentVariable %HOMEPATH%"
Select-EnvironmentVariable "%HOMEPATH%"

Start-Test "Select-EnvironmentVariable %LOGONSERVER% -Exact"
Select-EnvironmentVariable "%LOGONSERVER%" -Exact

Start-Test "Select-EnvironmentVariable UserProfile"
Select-EnvironmentVariable -Scope UserProfile

Start-Test "Select-EnvironmentVariable DOESNOTEXIST"
Select-EnvironmentVariable "DOESNOTEXIST"

Test-Output $Result -Command Select-EnvironmentVariable

Start-Test "Select Name (WhiteList)"
$Result | Select-Object -ExpandProperty Name

Start-Test "Select Value (WhiteList)"
$Result | Select-Object -ExpandProperty Value

Start-Test "Select-EnvironmentVariable WhiteList | Sort"
Select-EnvironmentVariable -Scope WhiteList | Sort-Object -Descending { $_.Value.Length }

Update-Log
Exit-Test

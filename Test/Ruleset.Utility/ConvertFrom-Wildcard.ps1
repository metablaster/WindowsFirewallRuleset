
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Unit test for ConvertFrom-Wildcard

.DESCRIPTION
Test correctness of ConvertFrom-Wildcard function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\ConvertFrom-Wildcard.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-Wildcard.ps1

.OUTPUTS
None. ConvertFrom-Wildcard.ps1 does not generate any output

.NOTES
TODO: Detailed testing is needed, reorganize/update existing cases.
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

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "ConvertFrom-Wildcard"

Start-Test "*PowerShell*"
[string] $Pattern = ConvertFrom-Wildcard "*PowerShell*"
Write-Output "Pattern: $Pattern"
[regex] $Regex = $Pattern
$Regex.Match("SuperPowerShellUltra")

Start-Test "Power[Sn]ell"
$Pattern = ConvertFrom-Wildcard "Power[Sn]ell"
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("Powernell")

Start-Test "Power?hell*"
$Pattern = ConvertFrom-Wildcard "Power?hell*"
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("Powerxhell")

Start-Test "*Power[a-z]Shell"
$Pattern = ConvertFrom-Wildcard "*Power[a-z]Shell"
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("PowerzShell")

Start-Test "^ha*ha$"
$Pattern = ConvertFrom-Wildcard "^ha*ha$" -Options ([System.Text.RegularExpressions.RegexOptions]::RightToLeft)
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("^ha*ha$")

Start-Test "match 'PowerShell' -AsRegex"
$Regex = ConvertFrom-Wildcard "Po?er[A-Z]hell*" -AsRegex -TimeSpan ([System.TimeSpan]::FromSeconds(3))
$Regex.Match("PowerShellaa")

Start-Test "match '4[PowerShellz'"
$Pattern = ConvertFrom-Wildcard "*[0-9][[]Po?er[A-Z]he*l?"
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("4[PowerShellz")

Start-Test "wildcard"
$Pattern = ConvertFrom-Wildcard "wildcard"
Write-Output "Pattern: $Pattern"
$Regex = $Pattern
$Regex.Match("wildcard")

Test-Output $Regex -Command ConvertFrom-Wildcard

Start-Test "*[0-9][[]Po?er[A-Z]he*l?"
ConvertFrom-Wildcard "*[0-9][[]Po?er[A-Z]he*l?"
# .*[0-9][[]Po.er[A-Z]he.*l.$

Start-Test "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"
ConvertFrom-Wildcard "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"
# ^a_b.*c%d[e\.\.f]\.\..g_%%_.*\?. { 2 }\*\\i[[]. { 2, }[%%]\\Z\\w\+$

Start-Test "MatchThis* -AsRegex IgnoreCase"
$Regex = ConvertFrom-Wildcard "MatchThis*" -AsRegex -Options "IgnoreCase"
$Regex.Match("MatchThis44Whatever")
# ^MatchThis.*

Start-Test "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"
[WildcardPattern] $Wildcard = "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"
ConvertFrom-Wildcard -Wildcard $Wildcard

#
# null or empty
#
New-Section "null or empty"

Start-Test "null" -Expected "Fail on null"
ConvertFrom-Wildcard

Start-Test "empty"
ConvertFrom-Wildcard "" -Expected "Fail on empty"

Start-Test "implicitly AsRegex" -Expected "Fail on null or empty"
ConvertFrom-Wildcard -AsRegex

Update-Log
Exit-Test

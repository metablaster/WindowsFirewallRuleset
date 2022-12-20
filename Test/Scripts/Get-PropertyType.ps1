
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Unit test for Get-PropertyType.ps1

.DESCRIPTION
Test correctness of Get-PropertyType script

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Get-PropertyType.ps1

.INPUTS
None. You cannot pipe objects to Get-PropertyType.ps1

.OUTPUTS
None. Get-PropertyType.ps1 does not generate any output

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

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Get-PropertyType"

Start-Test "sample data" -Command "Get-SystemSoftware"
$SystemSoftware = Get-SystemSoftware

Start-Test "SystemSoftware"
$Result = Get-PropertyType.ps1 $SystemSoftware
$Result

Start-Test "SystemSoftware -Property"
Get-PropertyType.ps1 $SystemSoftware -Property InstallLocation

Start-Test "Array to pipeline"
$Array = [PSCustomObject] @{
	Property1 = "har"
	Property2 = $(Get-Date)
},
[PSCustomObject] @{
	Property1 = "bar"
	Property2 = 2
}

$Array | Get-PropertyType

Start-Test "Not DateTime properties"
$Array | Where-Object { $_.Property2 -isnot [System.DateTime] }

Test-Output $Result -Command Get-PropertyType.ps1

Update-Log
Exit-Test

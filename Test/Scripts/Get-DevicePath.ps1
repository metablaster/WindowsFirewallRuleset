
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
Unit test for Get-DevicePath

.DESCRIPTION
Test correctness of Get-DevicePath.ps1 script

.EXAMPLE
PS> .\Get-DevicePath.ps1

.INPUTS
None. You cannot pipe objects to Get-DevicePath.ps1

.OUTPUTS
None. Get-DevicePath.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -Version 5.1
#requires -PSEdition Desktop
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
#Endregion

Enter-Test

Start-Test "Get-DevicePath"
$Result = Get-DevicePath
$Result
Test-Output $Result -Command Get-DevicePath.ps1

Start-Test "Get-DevicePath -DevicePath"
$Result = Get-DevicePath -DevicePath "\Device\HarddiskVolume4"
$Result
Test-Output $Result -Command Get-DevicePath.ps1

Start-Test "Get-DevicePath -DriveLetter $env:SystemDrive"
$Result = Get-DevicePath -DriveLetter $env:SystemDrive
$Result
Test-Output $Result -Command Get-DevicePath.ps1

Update-Log
Exit-Test

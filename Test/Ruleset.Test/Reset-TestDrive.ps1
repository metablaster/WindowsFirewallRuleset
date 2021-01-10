
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
Unit test for Reset-TestDrive

.DESCRIPTION
Test correctness of Reset-TestDrive function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Reset-TestDrive.ps1

.INPUTS
None. You cannot pipe objects to Reset-TestDrive.ps1

.OUTPUTS
None. Reset-TestDrive.ps1 does not generate any output

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
#Endregion

Enter-Test


Remove-Item -Path $DefaultTestDrive -Recurse -ErrorAction Ignore
$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

if ($Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::User))
{
	Start-Test "Reset-TestDrive non default new drive"
	Reset-TestDrive $DefaultTestDrive\$ThisScript

	Start-Test "Reset-TestDrive non default existing drive"
	Remove-Item -Path $DefaultTestDrive\$ThisScript\README.md -Confirm
	Reset-TestDrive $DefaultTestDrive\$ThisScript
}
else
{
	Start-Test "Reset-TestDrive as Administrator"
	Reset-TestDrive $DefaultTestDrive\$ThisScript

	Start-Test "Reset-TestDrive as Administrator"
	Remove-Item -Path $DefaultTestDrive\$ThisScript\README.md -Confirm
	Reset-TestDrive $DefaultTestDrive\$ThisScript
}

Start-Test "Reset-TestDrive new drive"
Remove-Item -Path $DefaultTestDrive -Recurse -ErrorAction Ignore
$Result = Reset-TestDrive
$Result

Start-Test "Reset-TestDrive existing drive"
Reset-TestDrive

Test-Output $Result -Command Reset-TestDrive

Update-Log
Exit-Test

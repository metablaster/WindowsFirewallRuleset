
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021-2024 metablaster zebal@protonmail.ch

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
Unit test for Initialize-WinRM

.DESCRIPTION
Test correctness of Initialize-WinRM function

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Initialize-WinRM.ps1

.INPUTS
None. You cannot pipe objects to Initialize-WinRM.ps1

.OUTPUTS
None. Initialize-WinRM.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

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

Enter-Test "Initialize-WinRM"

if (!(Get-Command -Name Initialize-WinRM -ErrorAction Ignore) -or
	!(Get-Variable -Name WinRMRules -ErrorAction Ignore) -or
	!(Get-Variable -Name WinRMCompatibilityRules -ErrorAction Ignore))
{
	Write-Error -Category NotEnabled -Message "This unit test requires export of privave functions and variables"
	Update-Log
	Exit-Test
	return
}

if ($Force -or $PSCmdlet.ShouldContinue("Initialize WinRM service", "Accept potentially dangerous unit test"))
{
	Start-Test "Default"
	$Result = Initialize-WinRM
	$Result

	Test-Output $Result -Command Initialize-WinRM
}

Update-Log
Exit-Test

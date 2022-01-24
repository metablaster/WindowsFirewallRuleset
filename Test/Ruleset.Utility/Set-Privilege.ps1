
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
Unit test for Set-Privilege

.DESCRIPTION
Test correctness of Set-Privilege function

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Set-Privilege.ps1

.INPUTS
None. You cannot pipe objects to Set-Privilege.ps1

.OUTPUTS
None. Set-Privilege.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Set-Privilege" -Private

if ($Force -or $PSCmdlet.ShouldContinue("$([System.Diagnostics.Process]::GetCurrentProcess().ProcessName) process", "Adjust process privilege"))
{
	$PSDefaultParameterValues.Add("Set-Privilege:Confirm", $false)

	Start-Test "SeSecurityPrivilege"
	$Result = Set-Privilege "SeSecurityPrivilege"
	$Result

	Test-Output $Result -Command Set-Privilege

	Start-Test "SeSecurityPrivilege -Disable"
	Set-Privilege "SeSecurityPrivilege" -Disable

	Start-Test "SeSecurityPrivilege, SeTakeOwnershipPrivilege"
	Set-Privilege -Privilege SeSecurityPrivilege, SeTakeOwnershipPrivilege

	Start-Test "SeSecurityPrivilege, SeTakeOwnershipPrivilege -Disable"
	Set-Privilege -Privilege SeSecurityPrivilege, SeTakeOwnershipPrivilege -Disable
}

Update-Log
Exit-Test

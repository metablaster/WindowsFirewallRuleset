
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
Unit test to test global variables

.DESCRIPTION
Unit test to test global variables

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\TestModuleVariables.ps1

.INPUTS
None. You cannot pipe objects to TestModuleVariables.ps1

.OUTPUTS
None. TestModuleVariables.ps1 does not generate any output

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
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# User prompt
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test -Private

Start-Test "Ruleset.Utility - ServiceHost:"
$ServiceHost

Start-Test "Ruleset.Utility - CheckInitUtility:"
$CheckInitUtility

Start-Test "Ruleset.Logging - HeaderStack:"
$HeaderStack

if ($Develop)
{
	Import-Module -Name Ruleset.ProgramInfo
	Start-Test "Ruleset.ProgramInfo - InstallTable:"
	$InstallTable
}

Start-Test "Ruleset.UserInfo - NetworkService:"
$NetworkService

Start-Test "Ruleset.UserInfo - LocalService:"
$LocalService

Start-Test "Ruleset.UserInfo - LocalSystem:"
$LocalSystem

Start-Test "Ruleset.UserInfo - AdminGroupSDDL:"
$AdminGroupSDDL

Start-Test "Ruleset.UserInfo - UsersGroupSDDL:"
$UsersGroupSDDL

Start-Test "Ruleset.UserInfo - CheckInitUserInfo:"
$CheckInitUserInfo

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for Get-OneDrive

.DESCRIPTION
Unit test for Get-OneDrive

.EXAMPLE
PS> .\Get-OneDrive.ps1

.INPUTS
None. You cannot pipe objects to Get-OneDrive.ps1

.OUTPUTS
None. Get-OneDrive.ps1 does not generate any output

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
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

$UserGroup = "Users"

Start-Test "Get-GroupPrincipal $UserGroup"
$Principals = Get-GroupPrincipal $UserGroup
# TODO: see also @Get-UserSoftware,
# This Format-Table won't be needed once we have consistent outputs, formats and better pipelines
$Principals | Format-Table

foreach ($Principal in $Principals)
{
	Start-Test "Get-OneDrive $($Principal.User)"
	Get-OneDrive $Principal.User
}

foreach ($Principal in $Principals)
{
	Start-Test "Get-OneDrive $($Principal.User) | InstallLocation"
	Get-OneDrive $Principal.User | Select-Object -ExpandProperty InstallLocation
}

Start-Test "Get-TypeName - $($Principals[0].User)"
$Result = Get-OneDrive $Principals[0].User
$Result

Test-Output $Result -Command Get-OneDrive

Update-Log
Exit-Test

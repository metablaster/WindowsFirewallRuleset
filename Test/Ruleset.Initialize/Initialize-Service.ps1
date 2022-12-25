
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Unit test for Initialize-Service

.DESCRIPTION
Test correctness of Initialize-Service function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Initialize-Service.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Service.ps1

.OUTPUTS
None. Initialize-Service.ps1 does not generate any output

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

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Initialize-Service"
$DebugPreference = "Continue"

Start-Test "Initialize RemoteRegistry"
Set-Service -Name RemoteRegistry -StartupType Disabled
Stop-Service -Name RemoteRegistry
$Result = Initialize-Service "RemoteRegistry" -Status Stopped -StartupType Manual
$Result

Test-Output $Result -Command Initialize-Service

Start-Test "RemoteRegistry already running"
Start-Service -Name RemoteRegistry
Initialize-Service "RemoteRegistry" -Status Stopped -StartupType Manual

Start-Test "pipeline"
$Services = @("lmhosts", "LanmanServer")
Stop-Service -Name $Services
$Services | Set-Service -StartupType Disabled

Start-Service -Name "LanmanWorkstation"
Suspend-Service -Name "LanmanWorkstation"
$Services += "LanmanWorkstation"

$Services | Initialize-Service

Start-Test "restart fpd"
$Services = @("FDResPub", "fdPHost")
Start-Service -Name $Services
$Services | Initialize-Service

Update-Log
Exit-Test

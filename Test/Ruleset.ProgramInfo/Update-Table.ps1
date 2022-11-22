
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Unit test for Update-Table

.DESCRIPTION
Test correctness of Update-Table function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Update-Table.ps1

.INPUTS
None. You cannot pipe objects to Update-Table.ps1

.OUTPUTS
None. Update-Table.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
# NOTE: As Administrator because of a test with OneDrive which loads reg hive of other users
#Requires -RunAsAdministrator

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalVars", "", Justification = "Needed in this unit test")]
[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test -Private "Update-Table"
$RemoteParams = @{}

if ($Domain -ne [System.Environment]::MachineName)
{
	$RemoteParams.CimSession = $CimServer
	$RemoteParams.Session = $SessionInstance
}

Start-Test "Greenshot -UserProfile"
Initialize-Table
Update-Table -Search "Greenshot" -UserProfile @RemoteParams
$global:InstallTable | Format-Table -AutoSize

Start-Test "Failure Test"
Initialize-Table
Update-Table -Search "Failure" -UserProfile @RemoteParams
$global:InstallTable | Format-Table -AutoSize

Start-Test "Multiple paths - Visual Studio"
Initialize-Table
Update-Table -Search "Visual Studio" -UserProfile @RemoteParams
$global:InstallTable | Format-Table -AutoSize

Start-Test "-Executable PowerShell.exe"
Initialize-Table
Update-Table -Executable "PowerShell.exe" @RemoteParams
$global:InstallTable | Format-Table -AutoSize

Start-Test "-Search EdgeChromium -Executable msedge.exe"
Initialize-Table
Update-Table -Search "EdgeChromium" -Executable "msedge.exe" @RemoteParams
$global:InstallTable | Format-Table -AutoSize

Start-Test "OneDrive -UserProfile"
Initialize-Table
$Result = Update-Table -Search "OneDrive" -UserProfile @RemoteParams
$Result
$global:InstallTable | Format-Table -AutoSize

Start-Test "Install Path"
$global:InstallTable | Select-Object -ExpandProperty InstallLocation

Test-Output $Result -Command Update-Table

Update-Log
Exit-Test

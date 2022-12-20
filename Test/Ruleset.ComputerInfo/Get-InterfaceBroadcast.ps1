
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
Unit test for Get-InterfaceBroadcast

.DESCRIPTION
Test correctness of Get-InterfaceBroadcast function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-InterfaceBroadcast.ps1

.INPUTS
None. You cannot pipe objects to Get-InterfaceBroadcast.ps1

.OUTPUTS
None. Get-InterfaceBroadcast.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

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

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-InterfaceBroadcast"
$SessionParams = @{
	Verbose = $true
}

if ($Domain -ne [System.Environment]::MachineName)
{
	$SessionParams.Session = $SessionInstance
}

Start-Test "default"
$Result = Get-InterfaceBroadcast @SessionParams
$Result

Start-Test "-Virtual"
Get-InterfaceBroadcast -Virtual @SessionParams

Start-Test "Physical"
Get-InterfaceBroadcast -Physical @SessionParams

Start-Test "-Hidden"
Get-InterfaceBroadcast -Hidden @SessionParams

Start-Test "-Visible"
Get-InterfaceBroadcast -Visible @SessionParams

Start-Test "-Hidden -Virtual"
Get-InterfaceBroadcast -Hidden -Virtual @SessionParams

Test-Output $Result -Command Get-InterfaceBroadcast

Update-Log
Exit-Test

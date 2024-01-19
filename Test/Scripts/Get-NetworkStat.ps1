
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

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
Unit test for Get-NetworkStat

.DESCRIPTION
Test correctness of Get-NetworkStat.ps1 script

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-NetworkStat.ps1

.INPUTS
None. You cannot pipe objects to Get-NetworkStat.ps1

.OUTPUTS
None. Get-NetworkStat.ps1 does not generate any output

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
#Endregion

Enter-Test
if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "remote Get-NetworkStat -State LISTENING -Protocol TCP"
	Get-NetworkStat -State LISTENING -Protocol TCP -Session $SessionInstance -CimSession $CimServer
}
else
{
	Start-Test "Get-NetworkStat"
	Get-NetworkStat

	Start-Test "Get-NetworkStat -IPAddress 192* -State LISTENING"
	Get-NetworkStat -IPAddress 192* -State LISTENING

	Start-Test "Get-NetworkStat -State LISTENING -Protocol TCP"
	$Result = Get-NetworkStat -State LISTENING -Protocol TCP
	$Result
	Test-Output $Result -Command Get-NetworkStat.ps1
}

Update-Log
Exit-Test


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
Unit test for Get-WindowsKit

.DESCRIPTION
Test correctness of Get-WindowsKit function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-WindowsKit.ps1

.INPUTS
None. You cannot pipe objects to Get-WindowsKit.ps1

.OUTPUTS
None. Get-WindowsKit.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-WindowsKit"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "Remote default"
	Get-WindowsKit -Domain $Domain
}
else
{
	Start-Test "default"
	$WindowsKits = Get-WindowsKit
	$WindowsKits

	Start-Test "DebuggersRoot latest"
	if ($null -ne $WindowsKits)
	{
		$WindowsKits | Where-Object { $_.Product -like "WindowsDebuggersRoot*" } |
		Sort-Object -Property Product |
		Select-Object -Last 1 -ExpandProperty InstallLocation
	}

	Start-Test "default"
	$WindowsKits | Format-List *

	Test-Output $WindowsKits -Command Get-WindowsKit -Force
}

Update-Log
Exit-Test

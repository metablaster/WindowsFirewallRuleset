
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
Unit test for Invoke-Process

.DESCRIPTION
Test correctness of Invoke-Process function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Invoke-Process.ps1

.INPUTS
None. You cannot pipe objects to Invoke-Process.ps1

.OUTPUTS
None. Invoke-Process.ps1 does not generate any output

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

Enter-Test "Invoke-Process"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "gpupdate.exe /target:computer"
	$Result = Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Session $SessionInstance
	$Result

	Start-Test "run git"
	Invoke-Process git.exe -NoNewWindow -ArgumentList "--version" -Session $SessionInstance

	Test-Output $Result -Command Invoke-Process
}
else
{
	Start-Test "gpupdate.exe /target:computer"
	$Result = Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	$Result

	Test-Output $Result -Command Invoke-Process

	Start-Test "path to gpupdate.exe /target:computer -Timeout 100"
	Invoke-Process "C:\WINDOWS\system32\gpupdate.exe" -NoNewWindow -ArgumentList "/target:computer" -Timeout 100

	Start-Test "git.exe status"
	# TODO: Does not work with Desktop edition
	$Result = Invoke-Process "git.exe" -ArgumentList "status" -NoNewWindow -Raw
	$Result

	Test-Output $Result -Command Invoke-Process

	Start-Test "Bad path" -Expected "Error message"
	Invoke-Process "C:\Program F*\Powe?Shell\777\pwsh.exe" -Timeout 5000

	Start-Test "Bad file" -Expected "Error message"
	Invoke-Process "C:\Program F*\Powe?Shell\badfile.exe" -Timeout 5000
}

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Unit test for Find-UnsignedFile.ps1

.DESCRIPTION
Test correctness of Find-UnsignedFile script
Use Find-UnsignedFile.ps1 as a template to test out scripts and module functions

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Find-UnsignedFile

.INPUTS
None. You cannot pipe objects to Find-UnsignedFile.ps1

.OUTPUTS
None. Find-UnsignedFile.ps1 does not generate any output

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
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#Endregion

Enter-Test "Find-UnsignedFile"

[bool] $YesToAll = $false
[bool] $NoToAll = $false

if ($Force -or $PSCmdlet.ShouldContinue("Run this unit test?", "Find unsigned files and perform VirusTotal scan", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	if (!(Test-Path -Path "C:\tools"))
	{
		Write-Warning -Message "[$ThisScript] C:\tools assumed for unit test bug path doesn't exist"
		return
	}

	Start-Test "Default test"
	Find-UnsignedFile -Path "C:\tools" -SigcheckLocation "C:\tools" -Log -VirusTotal

	Start-Test "%ProgramFiles%"
	$Result = Find-UnsignedFile -Path "%ProgramFiles%" -SigcheckLocation "C:\tools" -Log -VirusTotal -Recurse -Append
	$Result

	Test-Output $Result -Command Find-UnsignedFile
}

Update-Log
Exit-Test

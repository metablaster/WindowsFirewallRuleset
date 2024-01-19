
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
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#Endregion

Enter-Test "Find-UnsignedFile"

[bool] $YesToAll = $false
[bool] $NoToAll = $false

if ($Force -or $PSCmdlet.ShouldContinue("Run this unit test?", "Find unsigned files and perform VirusTotal scan", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	$TestPath1 = "C:\tools"
	# Known to have one unsigned file
	$TestPath2 = "${env:ProgramFiles(x86)}\GnuPG\bin"
	$SigcheckLocation = "C:\tools"

	if (!(Test-Path -Path $TestPath1) -or !(Test-Path -Path ))
	{
		Write-Warning -Message "[$ThisScript] '$TestPath1' and '$TestPath2' assumed for unit test but not all paths exist"
		return
	}

	Start-Test "Reset test drive"
	Reset-TestDrive

	Start-Test "$TestPath1 and test download sigcheck"
	Find-UnsignedFile -Path $TestPath1 -Log -VirusTotal -SigcheckLocation $DefaultTestDrive

	Start-Test $TestPath2
	$Result = Find-UnsignedFile -Path $TestPath2 -Log -VirusTotal -Append -Recurse -SigcheckLocation $SigcheckLocation
	$Result

	Test-Output $Result -Command Find-UnsignedFile
}

Update-Log
Exit-Test

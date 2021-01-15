
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
Unit test for Resolve-FileSystemPath

.DESCRIPTION
Test correctness of Resolve-FileSystemPath

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Resolve-FileSystemPath.ps1

.INPUTS
None. You cannot pipe objects to Resolve-FileSystemPath.ps1

.OUTPUTS
None. Resolve-FileSystemPath.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Resolve-FileSystemPath"

#
# Prepare test environment
#

$TestDrive = $DefaultTestDrive
New-Variable -Name TestPath -Option Constant -Value "$ProjectRoot\Tes?\Te*tD[rs]ive"

#
# Bad leaf name test
#

Start-Test "'wildcard leaf'" -Expected "FAIL"
Reset-TestDrive

[string] $FileInfo = "$TestDrive\badf[iz]le.txt"
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Directory test
#

Start-Test "'Existing directory'"
[string] $DirectoryInfo = $TestDrive
$Result = Resolve-FileSystemPath $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'New directory'"

$DirectoryInfo = "$TestDrive\TestDir1"
$Result = Resolve-FileSystemPath $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

$DirectoryInfo = "\User"
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

$DirectoryInfo = "\"
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# File test
#

Start-Test "'Existing file'"
# Reset-TestDrive

$FileInfo = "$TestDrive\infofile1.txt"
New-Item -ItemType File -Path $TestDrive\infofile1.txt | Out-Null
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'Missing file'"
Reset-TestDrive

$FileInfo = "$TestDrive\infofile2.txt"
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'Missing parent directory'" -Expected "FAIL"
Reset-TestDrive

$FileInfo = "$TestDrive\TestDir2\infofile3.txt"
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Not filesystem path
#

Start-Test "'Not file system qualifier'" -Expected "FAIL"
$DirectoryInfo = "HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'Bad qualifier'" -Expected "FAIL"
$DirectoryInfo = "BADDRIVE:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Bad path syntax
#

Start-Test "'Bad path'" -Expected "FAIL"
$DirectoryInfo = "$TestDrive\HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Bad wildcard pattern
#

Start-Test "'Multiple existent paths'" -Expected "FAIL"
Reset-TestDrive

$DirectoryInfo = "$TestDrive\TestDir3"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null
$DirectoryInfo = "$TestDrive\TestDir4"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null

$DirectoryInfo = "$TestDrive\*stDi*"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'Multiple parent paths'" -Expected "FAIL"
$DirectoryInfo = "$TestDrive\*e?tDi*\SubDirectory\NewDir"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "'No match'" -Expected "FAIL"
$DirectoryInfo = "NewDir"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Relative path
#

$DirectoryInfo = ".\.."
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

$DirectoryInfo = "."
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

$DirectoryInfo = "C:\Windows\System32\..\regedit.exe"
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

$DirectoryInfo = "~"
Start-Test $DirectoryInfo
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Update-Log
Exit-Test

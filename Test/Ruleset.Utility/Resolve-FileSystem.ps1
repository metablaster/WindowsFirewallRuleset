
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Unit test for Resolve-FileSystem

.DESCRIPTION
Test correctness of Resolve-FileSystem

.EXAMPLE
PS> .\Resolve-FileSystem.ps1

.INPUTS
None. You cannot pipe objects to Resolve-FileSystem.ps1

.OUTPUTS
None. Resolve-FileSystem.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -Version 5.1
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#Endregion

Enter-Test

#
# Prepare test environment
#

$TestDrive = $DefaultTestDrive
New-Variable -Name TestPath -Option Constant -Value "$ProjectRoot\Tes?\Te*tD[rs]ive"

#
# Bad leaf name test
#

Start-Test "Resolve-FileSystem 'wildcard leaf'"
Reset-TestDrive

[string] $FileInfo = "$TestDrive\badf[iz]le.txt"
$Result = Resolve-FileSystem $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# Directory test
#

Start-Test "Resolve-FileSystem 'Existing directory'"
[string] $DirectoryInfo = $TestPath
# New-Item -ItemType Directory -Path $TestDrive | Out-Null
$Result = Resolve-FileSystem $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'New directory'"

$DirectoryInfo = "$TestPath\TestDir1"
$Result = Resolve-FileSystem $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# File test
#

Start-Test "Resolve-FileSystem 'Existing file'"
# Reset-TestDrive

$FileInfo = "$TestPath\infofile1.txt"
New-Item -ItemType File -Path $TestDrive\infofile1.txt | Out-Null
$Result = Resolve-FileSystem $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'Missing file'"
Reset-TestDrive

$FileInfo = "$TestPath\infofile2.txt"
$Result = Resolve-FileSystem $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'Missing parent directory'"
Reset-TestDrive

$FileInfo = "$TestPath\TestDir2\infofile3.txt"
$Result = Resolve-FileSystem $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# Not filesystem path
#

Start-Test "Resolve-FileSystem 'Not file system qualifier'"
$DirectoryInfo = "HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'Bad qualifier'"
$DirectoryInfo = "DRIVEBAD:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# Bad path syntax
#

Start-Test "Resolve-FileSystem 'Bad path'"
$DirectoryInfo = "$DefaultTestDrive\HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# Bad wildcard pattern
#

Start-Test "Resolve-FileSystem 'Multiple existent paths'"
Reset-TestDrive

$DirectoryInfo = "$DefaultTestDrive\TestDir3"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null
$DirectoryInfo = "$DefaultTestDrive\TestDir4"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null

$DirectoryInfo = "$DefaultTestDrive\*stDi*"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'Multiple parent paths'"
$DirectoryInfo = "$TestDrive\*e?tDi*\SubDirectory\NewDir"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

Start-Test "Resolve-FileSystem 'No match'"
$DirectoryInfo = "NewDir"
$Result = Resolve-FileSystem $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystem
}

#
# TODO: Relative path
#

Update-Log
Exit-Test

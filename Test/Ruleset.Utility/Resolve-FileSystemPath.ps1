
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
If specified, no prompt to run script is shown.

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
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Strict
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
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

Start-Test "Resolve-FileSystemPath 'wildcard leaf'"
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

Start-Test "Resolve-FileSystemPath 'Existing directory'"
[string] $DirectoryInfo = $TestPath
# New-Item -ItemType Directory -Path $TestDrive | Out-Null
$Result = Resolve-FileSystemPath $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'New directory'"

$DirectoryInfo = "$TestPath\TestDir1"
$Result = Resolve-FileSystemPath $DirectoryInfo -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# File test
#

Start-Test "Resolve-FileSystemPath 'Existing file'"
# Reset-TestDrive

$FileInfo = "$TestPath\infofile1.txt"
New-Item -ItemType File -Path $TestDrive\infofile1.txt | Out-Null
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'Missing file'"
Reset-TestDrive

$FileInfo = "$TestPath\infofile2.txt"
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'Missing parent directory'"
Reset-TestDrive

$FileInfo = "$TestPath\TestDir2\infofile3.txt"
$Result = Resolve-FileSystemPath $FileInfo -File -Create

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Not filesystem path
#

Start-Test "Resolve-FileSystemPath 'Not file system qualifier'"
$DirectoryInfo = "HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'Bad qualifier'"
$DirectoryInfo = "DRIVEBAD:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Bad path syntax
#

Start-Test "Resolve-FileSystemPath 'Bad path'"
$DirectoryInfo = "$DefaultTestDrive\HKLM:\SOFTWARE\Microsoft\Clipboard"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# Bad wildcard pattern
#

Start-Test "Resolve-FileSystemPath 'Multiple existent paths'"
Reset-TestDrive

$DirectoryInfo = "$DefaultTestDrive\TestDir3"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null
$DirectoryInfo = "$DefaultTestDrive\TestDir4"
New-Item -ItemType Directory -Path $DirectoryInfo | Out-Null

$DirectoryInfo = "$DefaultTestDrive\*stDi*"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'Multiple parent paths'"
$DirectoryInfo = "$TestDrive\*e?tDi*\SubDirectory\NewDir"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

Start-Test "Resolve-FileSystemPath 'No match'"
$DirectoryInfo = "NewDir"
$Result = Resolve-FileSystemPath $DirectoryInfo

if ($Result)
{
	$Result.FullName
	Test-Output $Result -Command Resolve-FileSystemPath
}

#
# TODO: Relative path
#

Update-Log
Exit-Test

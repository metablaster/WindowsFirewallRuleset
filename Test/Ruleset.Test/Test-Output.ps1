
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
Unit test for Test-Output

.DESCRIPTION
Test correctness of Test-Output function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-Output.ps1

.INPUTS
None. You cannot pipe objects to Test-Output.ps1

.OUTPUTS
None. Test-Output.ps1 does not generate any output

.NOTES
TODO: More tests cases needed, in conjunction with Get-TypeName output
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
#endregion

# Command should be ignored by Test-Output
Enter-Test -Command Test-Output

Start-Test "-Command Test-Path"
$NETObject = Test-Path $env:SystemDrive
Test-Output $NETObject -Command Test-Path

Start-Test "Test-Path pipeline"
Test-Path $env:SystemDrive | Test-Output -Command Test-Path

# TODO: Unsure why error is shown from Get-TypeName if Ignore is specified
# TODO: Ignore won't work with Windows PowerShell
Start-Test "Get-Service and Get-Random" -Expected "FAIL" # -Force
$ServiceController = Get-Service -Name Dhcp
Test-Output $ServiceController -Command Get-Random -Force #-ErrorAction SilentlyContinue -Force
# Restore-Test

<#
.DESCRIPTION
Custom object not case sensitive
#>
function global:Test-CaseSensitive
{
	[OutputType("Custom")]
	param()

	[PSCustomObject]@{
		Name = "Name"
		PSTypeName = "custom"
	}
}

Start-Test "Test-Output not case sensitive"
Test-Output (Test-CaseSensitive) -Command Test-CaseSensitive -Force

<#
.DESCRIPTION
Custom object partial OutputType
#>
function global:Test-CaseSensitive
{
	[OutputType("Custom")]
	param()

	[PSCustomObject]@{
		Name = "Name"
		PSTypeName = "Ruleset.Custom"
	}
}

Start-Test "Test-Output partial OutputType"
Test-Output (Test-CaseSensitive) -Command Test-CaseSensitive -Force

<#
.DESCRIPTION
Custom object partial TypeName
#>
function global:Test-CaseSensitive
{
	[OutputType("Ruleset.Custom")]
	param()

	[PSCustomObject]@{
		Name = "Name"
		PSTypeName = "Custom"
	}
}

Start-Test "Test-Output partial TypeName"
Test-Output (Test-CaseSensitive) -Command Test-CaseSensitive -Force

<#
.DESCRIPTION
Null function
#>
function global:Test-NullFunction
{
	[OutputType([void])]
	param()

	return $null
}

Start-Test "Test-Output NULL"
Test-Output (Test-NullFunction) -Command Test-NullFunction

Start-Test "Array to pipeline"
Get-ChildItem | Test-Output -Command Get-ChildItem

Start-Test "Test-Output self-test"
$Result = Test-Output $NETObject -Command Test-Path -InformationAction Ignore
Test-Output $Result -Command Test-Output

Update-Log
Exit-Test

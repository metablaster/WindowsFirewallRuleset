
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
Unit test for Test-Output

.DESCRIPTION
Unit test for Test-Output

.EXAMPLE
PS> .\Test-Output.ps1

.INPUTS
None. You cannot pipe objects to Test-Output.ps1

.OUTPUTS
None. Test-Output.ps1 does not generate any output

.NOTES
TODO: More tests cases needed, in conjunction with Get-TypeName output
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Test-Output"
$NETObject = Test-Path $env:SystemDrive
Test-Output $NETObject -Command Test-Path @Logs

$TempError = $null

Start-Test "Test-Output FAIL"
$ServiceController = Get-Service
Test-Output $ServiceController -Command Get-Random #-ErrorAction SilentlyContinue -EV TempError
# Write-Warning -Message "Error ignored: $TempError"

<#
.DESCRIPTION
Null function
#>
function global:Test-NullFunction {}

Start-Test "Test-Output NULL"
$NullVariable = $null
Test-Output $NullVariable -Command Test-NullFunction -ErrorAction SilentlyContinue -EV TempError
Write-Warning -Message "Error ignored: $TempError"

Update-Log
Exit-Test

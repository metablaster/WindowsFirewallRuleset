
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
Unit test for Confirm-FileEncoding

.DESCRIPTION
Unit test for Confirm-FileEncoding

.EXAMPLE
PS> .\Confirm-FileEncoding.ps1

.INPUTS
None. You cannot pipe objects to Confirm-FileEncoding.ps1

.OUTPUTS
None. Confirm-FileEncoding.ps1 does not generate any output

.NOTES
As Administrator because of firewall logs in repository
#>

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Initialize ProjectFiles variable"
$ProjectFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Exclude *.cab, *.zip, *.png, *.wav, *.dll, *_HelpInfo.xml, *.pmc |
Where-Object { $_.Mode -notlike "*d*" } | Select-Object -ExpandProperty FullName

Start-Test "Confirm-FileEncoding"
$ProjectFiles | Confirm-FileEncoding @Logs

Start-Test "Confirm-FileEncoding file"
$TestFile = Resolve-Path -Path $PSScriptRoot\Encoding\utf8.txt
$Result = Confirm-FileEncoding $TestFile @Logs
$Result

Test-Output $Result -Command Confirm-FileEncoding @Logs

Update-Log
Exit-Test

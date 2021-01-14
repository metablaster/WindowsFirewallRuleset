
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for Select-IPInterface

.DESCRIPTION
Test correctness of Select-IPInterface function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Select-IPInterface.ps1

.INPUTS
None. You cannot pipe objects to Select-IPInterface.ps1

.OUTPUTS
None. Select-IPInterface.ps1 does not generate any output

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
#endregion

Enter-Test "Select-IPInterface"

Start-Test "default"
Select-IPInterface -Detailed

Start-Test "IPv6 FAILURE TEST"
Select-IPInterface -AddressFamily IPv6 -ErrorAction SilentlyContinue

Start-Test "IPv4 -Physical"
$Result = Select-IPInterface -AddressFamily IPv4 -Physical
$Result

Start-Test "-Physical -Hidden"
Select-IPInterface -Physical -Hidden

Start-Test "IPv4 -Virtual"
Select-IPInterface -AddressFamily IPv4 -Virtual

Start-Test "-Virtual -Hidden"
Select-IPInterface -Virtual -Hidden

Start-Test "-Hidden"
Select-IPInterface -Hidden

Start-Test "-Connected"
Select-IPInterface -Connected -Detailed

Start-Test "binding"
Select-IPInterface -AddressFamily IPv4 -Physical | Select-Object -ExpandProperty IPv4Address

Test-Output $Result -Command Select-IPInterface

Update-Log
Exit-Test

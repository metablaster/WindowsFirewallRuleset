
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
Unit test for Approve-Execute

.DESCRIPTION
Test correctness of Approve-Execute function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Approve-Execute.ps1

.INPUTS
None. You cannot pipe objects to Approve-Execute.ps1

.OUTPUTS
None. Approve-Execute.ps1 does not generate any output

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

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

[string] $Accept2 = "Accept test"
[string] $Deny2 = "Deny test"

Start-Test "Approve-Execute default"
Approve-Execute

Start-Test "Approve-Execute -Unsafe"
$Result = Approve-Execute -Unsafe -Accept $Accept2 -Deny $Deny2
$Result

Start-Test "Approve-Execute title question unsafe"
Approve-Execute -Unsafe -Title "Unable to locate 'SOME FOLDER'" -Question "Do you want to try again?"

[bool] $YesToAll = $false
[bool] $NoToAll = $false
Start-Test "Approve-Execute ToAll"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)

Start-Test "Approve-Execute ToAll full"
Approve-Execute -Unsafe -Accept $Accept2 -Deny $Deny2 -Title "TITLE" -Question "QUESTION" -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)

Test-Output $Result -Command Approve-Execute

Update-Log
Exit-Test

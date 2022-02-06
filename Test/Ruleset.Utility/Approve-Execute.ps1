
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
If specified, no prompt to run script is shown

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
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Approve-Execute"

$TestAccept = "Accept help test"
$TestDeny = "Deny help test"
$TestTitle = "Test title"
$TestQuestion = "Test question?"
$TestContext = "Test context"
$TestContextLeaf = "Test context leaf"
[bool] $YesToAll = $false
[bool] $NoToAll = $false

Start-Test "default"
Approve-Execute

Start-Test "-Force"
Approve-Execute -Force

Start-Test "-Accept -Deny -Unsafe"
$Result = Approve-Execute -Accept $TestAccept -Deny $TestDeny -Unsafe
$Result

Start-Test "-Title -Question"
Approve-Execute -Title $TestTitle -Question $TestQuestion

Start-Test "-Title -Question -Unsafe"
Approve-Execute -Title $TestTitle -Question $TestQuestion -Unsafe

Start-Test "-Context"
Approve-Execute -Context $TestContext

Start-Test "-ContextLeaf"
Approve-Execute -ContextLeaf $TestContextLeaf

Start-Test "-Context -ContextLeaf"
Approve-Execute -Context $TestContext -ContextLeaf $TestContextLeaf

Start-Test "-Title reuse context"
Approve-Execute -Title $TestTitle

Start-Test "regenerate context"
Approve-Execute

Start-Test "-Title -Context"
Approve-Execute -Title $TestTitle -Context $TestContext

Start-Test "-Title -ContextLeaf"
Approve-Execute -Title $TestTitle -ContextLeaf $TestContextLeaf

Start-Test "-YesToAll -NoToAll (choose NoToAll)"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
Write-Information -Tags "Test" -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -Tags "Test" -MessageData "INFO: NoToAll: $NoToAll"

Start-Test "result must be automatically false"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
Write-Information -Tags "Test" -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -Tags "Test" -MessageData "INFO: NoToAll: $NoToAll"

$YesToAll = $false
$NoToAll = $false

Start-Test "-YesToAll -NoToAll (choose YesToAll)"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
Write-Information -Tags "Test" -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -Tags "Test" -MessageData "INFO: NoToAll: $NoToAll"

Start-Test "must be automatically true"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll)
Write-Information -Tags "Test" -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -Tags "Test" -MessageData "INFO: NoToAll: $NoToAll"

$YesToAll = $false
$NoToAll = $false

Start-Test "full"
Approve-Execute -Unsafe -Accept $TestAccept -Deny $TestDeny -Title $TestTitle -Question $TestQuestion `
	-YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Context $TestContext -ContextLeaf $TestContextLeaf

Start-Test "-Unsafe -Force FAILURE TEST"
Approve-Execute -Unsafe -Force

Start-Test "-YesToAll -Force FAILURE TEST"
Approve-Execute -YesToAll ([ref] $YesToAll) -Force

Start-Test "-NoToAll -Unsafe FAILURE TEST"
Approve-Execute -NoToAll ([ref] $NoToAll) -Unsafe

Start-Test "-YesToAll FAILURE TEST"
Approve-Execute -YesToAll ([ref] $YesToAll)

Test-Output $Result -Command Approve-Execute

Update-Log
Exit-Test

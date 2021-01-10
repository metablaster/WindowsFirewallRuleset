
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
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

$TestAccept = "Accept help test"
$TestDeny = "Deny help test"
$TestTitle = "Test title"
$TestQuestion = "Test question?"
$TestContext = "Test context"
$TestContextLeaf = "Test context leaf"
[bool] $YesToAll = $false
[bool] $NoToAll = $false

Start-Test "Approve-Execute default"
Approve-Execute

Start-Test "Approve-Execute -Force"
Approve-Execute -Force

Start-Test "Approve-Execute -Accept -Deny -Unsafe"
$Result = Approve-Execute -Accept $TestAccept -Deny $TestDeny -Unsafe
$Result

Start-Test "Approve-Execute -Title -Question"
Approve-Execute -Title $TestTitle -Question $TestQuestion

Start-Test "Approve-Execute -Title -Question -Unsafe"
Approve-Execute -Title $TestTitle -Question $TestQuestion -Unsafe

Start-Test "Approve-Execute -Context"
Approve-Execute -Context $TestContext

Start-Test "Approve-Execute -ContextLeaf"
Approve-Execute -ContextLeaf $TestContextLeaf

Start-Test "Approve-Execute -Context -ContextLeaf"
Approve-Execute -Context $TestContext -ContextLeaf $TestContextLeaf

Start-Test "Approve-Execute -Title reuse context"
Approve-Execute -Title $TestTitle

Start-Test "Approve-Execute regenerate context"
Approve-Execute

Start-Test "Approve-Execute -Title -Context"
Approve-Execute -Title $TestTitle -Context $TestContext

Start-Test "Approve-Execute -Title -ContextLeaf"
Approve-Execute -Title $TestTitle -ContextLeaf $TestContextLeaf

Start-Test "Approve-Execute -YesToAll -NoToAll (choose NoToAll)"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Debug
Write-Information -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -MessageData "INFO: NoToAll: $NoToAll"

Start-Test "Approve-Execute result must be automatically false"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Debug
Write-Information -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -MessageData "INFO: NoToAll: $NoToAll"

$YesToAll = $false
$NoToAll = $false

Start-Test "Approve-Execute -YesToAll -NoToAll (choose YesToAll)"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Debug
Write-Information -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -MessageData "INFO: NoToAll: $NoToAll"

Start-Test "Approve-Execute must be automatically true"
Approve-Execute -YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Debug
Write-Information -MessageData "INFO: YesToAll: $YesToAll"
Write-Information -MessageData "INFO: NoToAll: $NoToAll"

$YesToAll = $false
$NoToAll = $false

Start-Test "Approve-Execute full"
Approve-Execute -Unsafe -Accept $TestAccept -Deny $TestDeny -Title $TestTitle -Question $TestQuestion `
	-YesToAll ([ref] $YesToAll) -NoToAll ([ref] $NoToAll) -Context $TestContext -ContextLeaf $TestContextLeaf

Start-Test "Approve-Execute -Unsafe -Force FAILURE TEST"
Approve-Execute -Unsafe -Force

Start-Test "Approve-Execute -YesToAll -Force FAILURE TEST"
Approve-Execute -YesToAll ([ref] $YesToAll) -Force

Start-Test "Approve-Execute -NoToAll -Unsafe FAILURE TEST"
Approve-Execute -NoToAll ([ref] $NoToAll) -Unsafe -Debug

Start-Test "Approve-Execute -YesToAll FAILURE TEST"
Approve-Execute -YesToAll ([ref] $YesToAll) -Debug

Test-Output $Result -Command Approve-Execute

Update-Log
Exit-Test

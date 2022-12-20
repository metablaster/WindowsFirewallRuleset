
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
Unit test for Write-LogFile

.DESCRIPTION
Test correctness of Write-LogFile function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Write-LogFile.ps1

.INPUTS
None. You cannot pipe objects to Write-LogFile.ps1

.OUTPUTS
None. Write-LogFile.ps1 does not generate any output

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

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test

Start-Test "Write log no header"
Write-LogFile -Tags "Test" -Message "Test no header" -LogName "TestLog1" -Path $LogsFolder\Test

Start-Test "Write log new header"
$HeaderStack.Push("Test case header 1")
Write-LogFile -Tags "Test" -Message "Test header 1" -LogName "TestLog2" -Path $LogsFolder\Test

Start-Test "Write log 2nd header"
$HeaderStack.Push("Test case header 2")
Write-LogFile -Tags "Test" -Message "Test header 2" -LogName "TestLog3" -Path $LogsFolder\Test

Start-Test "Write log -Raw"
$HeaderStack.Push("Raw message")
Write-LogFile -Tags "Test" -Message "Raw message" -LogName "TestLog3" -Path $LogsFolder\Test -Raw
$HeaderStack.Pop() | Out-Null

Start-Test "Write log 2nd header after raw"
Write-LogFile -Tags "Test" -Message "Test header 2" -LogName "TestLog3" -Path $LogsFolder\Test

Start-Test "Write log previous header" -Expected "Test case header 1"
$HeaderStack.Pop() | Out-Null
Write-LogFile -Tags "Test" -Message "Test previous header" -LogName "TestLog4" -Path $LogsFolder\Test

Start-Test "Write log initial header" -Expected "Default header"
$HeaderStack.Pop() | Out-Null
Write-LogFile -Tags "Test" -Message "Test initial header" -LogName "TestLog5" -Path $LogsFolder\Test

Start-Test "Write log -Raw" -Expected "(overridden)"
$HeaderStack.Push("Raw message")
Write-LogFile -Tags "Test" -Message "Raw message" -LogName "TestLog6" -Path $LogsFolder\Test -Raw

Start-Test "Write log -Raw -Overwrite"
$HeaderStack.Pop() | Out-Null
$HeaderStack.Push("Raw message overwrite")
Write-LogFile -Message "Raw message overwrite" -LogName "TestLog6" -Path $LogsFolder\Test -Raw -Overwrite

Start-Test "Write log -Raw"
Write-LogFile -Tags "Test" -Message "New raw message after overwrite" -LogName "TestLog6" -Path $LogsFolder\Test -Raw
$HeaderStack.Pop() | Out-Null

Start-Test "Multiple log records"
$HeaderStack.Push("Test case multiple messages")
Write-LogFile -Tags "Test" -Message "message 1", "message 2", "message 3" -LogName "TestLog7" -Path $LogsFolder\Test

Start-Test "Multiple raw log messages"
$HeaderStack.Push("Test case multiple messages")
Write-LogFile -Tags "Test" -Message "message 1", "message 2", "message 3" -LogName "TestLog7" -Path $LogsFolder\Test -Raw
$HeaderStack.Pop() | Out-Null

Update-Log
Exit-Test

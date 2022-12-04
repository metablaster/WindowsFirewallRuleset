
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Unit test for Write-ColorMessage

.DESCRIPTION
Test correctness of Write-ColorMessage function

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Write-ColorMessage.ps1

.INPUTS
None. You cannot pipe objects to Write-ColorMessage.ps1

.OUTPUTS
None. Write-ColorMessage.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

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
#Endregion

Enter-Test "Write-ColorMessage"

Start-Test "Green text"
Write-ColorMessage "text in green" -Foregroundcolor Green

$Result = Write-ColorMessage "text in green" -Foregroundcolor Green
Test-Output $Result -Command Write-ColorMessage

Start-Test "White text red background"
Write-ColorMessage "White text red background" White -BackGroundColor Red

# Not implemented
if ($false)
{
	$TestHash = @{
		Item1 = "abc"
		Item2 = "123"
	}

	Start-Test "Hashtable in red"
	Write-ColorMessage $TestHash Red
}

Start-Test "red text and blank line"
Write-ColorMessage "red text" Red
Write-ColorMessage
Write-ColorMessage "red text" Red

Start-Test "Cyan text pipeline"
"Cyan pipeline" | Write-ColorMessage -Foregroundcolor Cyan

Update-Log
Exit-Test

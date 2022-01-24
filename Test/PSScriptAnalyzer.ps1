
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Run PSScriptAnalyzer on repository

.DESCRIPTION
Run PSScriptAnalyzer on repository and format detailed and relevant output

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\PSScriptAnalyzer.ps1

.INPUTS
None. You cannot pipe objects to PSScriptAnalyzer.ps1

.OUTPUTS
None. PSScriptAnalyzer.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

if (Approve-Execute -Accept "Run PSScriptAnalyzer on repository" -Deny "Skip code analysis operation" -Force:$Force)
{
	Write-Information -Tags "Test" -MessageData "INFO: Starting code analysis..."
	Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -Settings $ProjectRoot\Config\PSScriptAnalyzerSettings.psd1 |
	Format-List -Property Severity, RuleName, RuleSuppressionID, Message, Line, ScriptPath
}

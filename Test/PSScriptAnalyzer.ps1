
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

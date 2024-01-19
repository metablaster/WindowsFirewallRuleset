
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

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
Check encoding of files

.DESCRIPTION
Test-FileEncoding.ps1 checks all files in repository are properly encoded

.PARAMETER Force
If specified, no prompt to run encoding analysis is shown

.EXAMPLE
PS> .\Test-FileEncoding.ps1

.INPUTS
None. You cannot pipe objects to Test-FileEncoding.ps1.

.OUTPUTS
None. Test-FileEncoding.ps1 does not generate any output.

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

if (Approve-Execute -Accept "Check encoding of files in repository" -Deny "Skip checking for file encoding" -Force:$Force)
{
	Write-Information -Tags "Test" -MessageData "INFO: Checking file encoding analysis on repository"

	$Excludes = @(
		"*.cab"
		"*.zip"
		"*.png"
		"*.wav"
		"*.dll"
		"*.pmc"
		"*.pmf"
		"*.msc"
		"*.lnk"
		"*.cer"
		"*.gif"
	)

	if ($PSVersionTable.PSEdition -eq "Core")
	{
		# NOTE: Ignoring, see New-ExternalHelpCab in Scripts\Update-HelpContent.ps1 for more info
		$Excludes += "*_HelpInfo.xml"
	}

	# NOTE: This will exclude .git directory since it's attribute is "Hidden"
	$Directories = Get-ChildItem -Path $ProjectRoot -Recurse -Attributes Directory | Where-Object {
		# Exclude test files and firewall logs
		$_.FullName -notmatch "(Ruleset\.Utility\\Encoding)|(Logs\\Firewall)|(Test\\PssaTest)"
	}

	[string[]] $Files = @()
	foreach ($Directory in $Directories.FullName)
	{
		$Files += Get-ChildItem -Path "$Directory\*" -Exclude $Excludes -File |
		Select-Object -ExpandProperty FullName
	}

	Confirm-FileEncoding -Path $Files

	Write-Information -Tags "Test" -MessageData "INFO: Total items processed was $($Directories.Count) directories and $($Files.Count) files"
	Update-Log
}

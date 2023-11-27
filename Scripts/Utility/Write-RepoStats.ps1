
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.16.1

.GUID a0429bba-93eb-4178-9da6-78d2dc242c0a

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging
#>

<#
.SYNOPSIS
Calculate repository stats

.DESCRIPTION
Write-RepoStats.ps1 calculates repository stats by parsing all files and
creating a log with stats such as count of lines of code, comment lines count and
count of blank lines.

.PARAMETER Force
If specified, no prompt to run the script is shown

.EXAMPLE
PS> Write-RepoStats

.INPUTS
None. You cannot pipe objects to Write-RepoStats.ps1

.OUTPUTS
None. Write-RepoStats.ps1 does not generate any output

.NOTES
TODO: Not all file formats are handled
TODO: Regex patters need manual tests to confirm they work as precise as possible.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

using namespace System.Text.RegularExpressions
#Requires -Version 5.1

[CmdletBinding()]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

# User prompt
$Accept = "Write file count, LOC and other repo start to log file"
$Deny = "Abort operation"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Write-Information -MessageData "INFO: Initializing files"
$PowerShellIncludes = @(
	"*.ps1"
	"*.psm1"
	"*.psd1"
	"*.pssc"
)

$XmlIncludes = @(
	"*.xml"
	"*.ps1xml"
)

$JsonIncludes = @(
	"*.json"
	"*.code-snippets"
)

$AllScripts = Get-ChildItem -Path $ProjectRoot -Include $PowerShellIncludes -Recurse
$AllXmlFiles = Get-ChildItem -Path $ProjectRoot -Include $XmlIncludes -Recurse
$AllMarkdownFiles = Get-ChildItem -Path $ProjectRoot -Include "*.md" -Recurse
$AllJsonFiles = Get-ChildItem -Path $ProjectRoot -Include $JsonIncludes -Recurse

$ScriptCount = ($AllScripts | Measure-Object).Count
$XmlFileCount = ($AllXmlFiles | Measure-Object).Count
$MarkdownFileCount = ($AllMarkdownFiles | Measure-Object).Count
$JsonFileCount = ($AllJsonFiles | Measure-Object).Count

$AllFilesCount = $ScriptCount + $XmlFileCount + $MarkdownFileCount + $JsonFileCount

#
# All files comments stats
#

# Script comments including blank lines of all scripts
[uint64] $TotalCommentLines = 0
# Script comments excluding blank lines of all scripts
[uint64] $TotalPureCommentLines = 0
# Script comments blank lines only of all scripts
[uint64] $TotalBlankCommentLines = 0

#
# All files code stats
#

# Lines of Code including blank lines
[uint64] $TotalLOC = 0
# Lines of Code excluding blank lines
[uint64] $TotalPureLOC = 0
# Blank lines of code
[uint64] $TotalBlankLOC = 0

#
# All files combined stats
#

# Count of lines in all script including blank lines
[uint64] $TotalLines = 0
# Count of blank lines in all scripts
[uint64] $TotalBlankLines = 0

# Get stats about comment blocks
[ScriptBlock] $CommentBlockProcessor = {
	param (
		$FileData,
		[regex] $CommentBlockRegex,
		[ref] $FileCommentLines,
		[ref] $FileBlankCommentLines
	)

	$FileCommentLinesLocal = 0
	$FileBlankCommentLinesLocal = 0

	# [MatchCollection]
	# MSDN: A collection of the Match objects found by the search.
	# If no matches are found, the method returns an empty collection object.
	$CommentBlockMatch = [regex]::Matches($FileData, $CommentBlockRegex, [RegexOptions]::Multiline)
	if ($CommentBlockMatch.Count -ne 0)
	{
		foreach ($Group in $CommentBlockMatch.Groups)
		{
			if ($Group.Success)
			{
				$FileCommentLinesLocal += Measure-Object -InputObject $Group.Value -Line | Select-Object -ExpandProperty Lines
				$BlankCommentsMatch = [regex]::Match($Group.Value, $BlankLineRegex, [RegexOptions]::Multiline)

				if ($BlankCommentsMatch.Success)
				{
					$FileBlankCommentLinesLocal += $BlankCommentsMatch.Groups.Count
				}
			}
		}
	}

	$FileCommentLines.Value += $FileCommentLinesLocal
	$FileBlankCommentLines.Value += $FileBlankCommentLinesLocal
}

# Get stats about comment lines
[ScriptBlock] $CommentLinesProcessor = {
	param (
		$FileData,
		[regex] $CommentLineRegex,
		[ref] $FileCommentLines
	)

	$FileCommentLinesLocal = 0

	$CommentLineMatch = [regex]::Matches($FileData, $CommentLineRegex, [RegexOptions]::Multiline)
	if ($CommentLineMatch.Count -ne 0)
	{
		foreach ($Group in $CommentLineMatch.Groups)
		{
			if ($Group.Success)
			{
				++$FileCommentLinesLocal
			}
		}
	}

	$FileCommentLines.Value += $FileCommentLinesLocal
}

# Get stats about blank lines
[ScriptBlock] $BlankLinesProcessor = {
	param (
		$FileData,
		[regex] $BlankLineRegex,
		[ref] $FileBlankLines
	)

	$FileBlankLinesLocal = 0

	$BlankLinesMatch = [regex]::Matches($FileData, $BlankLineRegex, [RegexOptions]::Multiline)
	if ($BlankLinesMatch.Count -ne 0)
	{
		foreach ($Group in $BlankLinesMatch.Groups)
		{
			if ($Group.Success)
			{
				++$FileBlankLinesLocal
			}
		}
	}

	$FileBlankLines.Value = $FileBlankLinesLocal
}

#
# Regex patterns for all files
#
[regex] $BlankLineRegex = "^(\r\n|\n|\r)|^\s*$"

Write-Information -MessageData "INFO: Processing script files"

#
# Regex patterns for PS files
#
[regex] $CommentLineRegex = "^#(?!\>).*$"
[regex] $CommentBlockRegex = "\<#(?!PSScriptInfo)[\s\S]+?(?=#\>)"
[regex] $ScriptInfoRegex = "\<#PSScriptInfo[\s\S]+?(?=#\>)"

#
# Script totals
#
$TotalScriptCommentLines = 0
$TotalScriptBlankCommentLines = 0
$TotalScriptPureCommentLines = 0

$TotalScriptLines = 0
$TotalScriptBlankLines = 0

$TotalScriptLOC = 0
$TotalScriptBlankLOC = 0
$TotalScriptPureLOC = 0

foreach ($Script in $AllScripts)
{
	# xml contents
	$FileData = Get-Content -Path $Script.FullName -Raw

	# Count of all lines in xml files
	$FileTotalLines = Measure-Object -InputObject $FileData -Line | Select-Object -ExpandProperty Lines

	# Count of blank lines in file
	$FileBlankLines = 0
	# Blank lines within block comments
	$FileBlankCommentLines = 0
	# Script comments including blank lines (within block comment)
	$FileCommentLines = 0

	# [Match]
	# MSDN: An object that contains information about the match.
	$ScriptInfoMatch = [regex]::Match($FileData, $ScriptInfoRegex, [RegexOptions]::Multiline)
	if ($ScriptInfoMatch.Success)
	{
		$FileCommentLines = Measure-Object -InputObject $ScriptInfoMatch.Value -Line | Select-Object -ExpandProperty Lines
		$BlankCommentsMatch = [regex]::Match($ScriptInfoMatch.Value, $BlankLineRegex, [RegexOptions]::Multiline)

		if ($BlankCommentsMatch.Success)
		{
			$FileBlankCommentLines = $BlankCommentsMatch.Groups.Count
		}
	}

	& $CommentBlockProcessor $FileData $CommentBlockRegex ([ref] $FileCommentLines) ([ref] $FileBlankCommentLines)
	& $CommentLinesProcessor $FileData $CommentLineRegex ([ref] $FileCommentLines)
	& $BlankLinesProcessor $FileData $BlankLineRegex ([ref] $FileBlankLines)

	# File comments excluding blank lines
	$FilePureCommentLines = $FileCommentLines - $FileBlankCommentLines
	# Blank Lines of Code in script
	$FileBlankLOC = $FileBlankLines - $FileBlankCommentLines
	# Lines of Code in script including blank lines but excluding comments
	$FileLOC = $FileTotalLines - $FileCommentLines

	# Update global
	$TotalScriptCommentLines += $FileCommentLines
	$TotalScriptBlankCommentLines += $FileBlankCommentLines
	$TotalScriptPureCommentLines += $FilePureCommentLines

	$TotalScriptLines += $FileTotalLines
	$TotalScriptBlankLines += $FileBlankLines

	$TotalScriptLOC += $FileLOC
	$TotalScriptBlankLOC += $FileBlankLOC
	$TotalScriptPureLOC += ($FileLOC - $FileBlankLOC)
}

Write-Information -MessageData "INFO: Processing XML files"

#
# Regex patterns for XML files
#
[regex] $CommentLineRegex = "<!--"
# TODO: Unclear if this will match block comments
[regex] $CommentBlockRegex = "<!--[\s\S]+?(?=-->)"

#
# XML totals
#
$TotalXmlCommentLines = 0
$TotalXmlBlankCommentLines = 0
$TotalXmlPureCommentLines = 0

$TotalXmlLines = 0
$TotalXmlBlankLines = 0

$TotalXmlLOC = 0
$TotalXmlBlankLOC = 0
$TotalXmlPureLOC = 0

foreach ($XmlFile in $AllXmlFiles)
{
	# xml contents
	$FileData = Get-Content -Path $XmlFile.FullName -Raw

	# Count of all lines in xml files
	$FileTotalLines = Measure-Object -InputObject $FileData -Line | Select-Object -ExpandProperty Lines
	$FileBlankLines = 0
	$FileBlankCommentLines = 0
	$FileCommentLines = 0

	& $CommentBlockProcessor $FileData $CommentBlockRegex ([ref] $FileCommentLines) ([ref] $FileBlankCommentLines)
	& $CommentLinesProcessor $FileData $CommentLineRegex ([ref] $FileCommentLines)
	& $BlankLinesProcessor $FileData $BlankLineRegex ([ref] $FileBlankLines)

	$FilePureCommentLines = $FileCommentLines - $FileBlankCommentLines
	$FileBlankLOC = $FileBlankLines - $FileBlankCommentLines
	$FileLOC = $FileTotalLines - $FileCommentLines

	# Update global
	$TotalXmlCommentLines += $FileCommentLines
	$TotalXmlBlankCommentLines += $FileBlankCommentLines
	$TotalXmlPureCommentLines += $FilePureCommentLines

	$TotalXmlLines += $FileTotalLines
	$TotalXmlBlankLines += $FileBlankLines

	$TotalXmlLOC += $FileLOC
	$TotalXmlBlankLOC += $FileBlankLOC
	$TotalXmlPureLOC += ($FileLOC - $FileBlankLOC)
}

Write-Information -MessageData "INFO: Processing markdown files"

#
# Regex patterns for Markdown files
#
[regex] $CommentLineRegex = "\[\/\/\]:"

#
# Markdown totals
#
$TotalMarkdownCommentLines = 0
$TotalMarkdownBlankCommentLines = 0
$TotalMarkdownPureCommentLines = 0

$TotalMarkdownLines = 0
$TotalMarkdownBlankLines = 0

$TotalMarkdownLOC = 0
$TotalMarkdownBlankLOC = 0
$TotalMarkdownPureLOC = 0

foreach ($MarkdownFile in $AllMarkdownFiles)
{
	# Markdown contents
	$FileData = Get-Content -Path $MarkdownFile.FullName -Raw

	# Count of all lines in markdown files
	$FileTotalLines = Measure-Object -InputObject $FileData -Line | Select-Object -ExpandProperty Lines
	$FileBlankLines = 0
	$FileBlankCommentLines = 0
	$FileCommentLines = 0

	& $CommentLinesProcessor $FileData $CommentLineRegex ([ref] $FileCommentLines)
	& $BlankLinesProcessor $FileData $BlankLineRegex ([ref] $FileBlankLines)

	$FilePureCommentLines = $FileCommentLines - $FileBlankCommentLines
	$FileBlankLOC = $FileBlankLines - $FileBlankCommentLines
	$FileLOC = $FileTotalLines - $FileCommentLines

	# Update global
	$TotalMarkdownCommentLines += $FileCommentLines
	$TotalMarkdownBlankCommentLines += $FileBlankCommentLines
	$TotalMarkdownPureCommentLines += $FilePureCommentLines

	$TotalMarkdownLines += $FileTotalLines
	$TotalMarkdownBlankLines += $FileBlankLines

	$TotalMarkdownLOC += $FileLOC
	$TotalMarkdownBlankLOC += $FileBlankLOC
	$TotalMarkdownPureLOC += ($FileLOC - $FileBlankLOC)
}

Write-Information -MessageData "INFO: Processing JSON files"

#
# Regex patterns for JSON files
#
[regex] $CommentLineRegex = "\/\/.*$"

#
# JSON totals
#
$TotalJsonCommentLines = 0
$TotalJsonBlankCommentLines = 0
$TotalJsonPureCommentLines = 0

$TotalJsonLines = 0
$TotalJsonBlankLines = 0

$TotalJsonLOC = 0
$TotalJsonBlankLOC = 0
$TotalJsonPureLOC = 0

foreach ($JsonFile in $AllJsonFiles)
{
	# JSON contents
	$FileData = Get-Content -Path $JsonFile.FullName -Raw

	# Count of all lines in JSON files
	$FileTotalLines = Measure-Object -InputObject $FileData -Line | Select-Object -ExpandProperty Lines
	$FileBlankLines = 0
	$FileBlankCommentLines = 0
	$FileCommentLines = 0

	& $CommentLinesProcessor $FileData $CommentLineRegex ([ref] $FileCommentLines)
	& $BlankLinesProcessor $FileData $BlankLineRegex ([ref] $FileBlankLines)

	$FilePureCommentLines = $FileCommentLines - $FileBlankCommentLines
	$FileBlankLOC = $FileBlankLines - $FileBlankCommentLines
	$FileLOC = $FileTotalLines - $FileCommentLines

	# Update global
	$TotalJsonCommentLines += $FileCommentLines
	$TotalJsonBlankCommentLines += $FileBlankCommentLines
	$TotalJsonPureCommentLines += $FilePureCommentLines

	$TotalJsonLines += $FileTotalLines
	$TotalJsonBlankLines += $FileBlankLines

	$TotalJsonLOC += $FileLOC
	$TotalJsonBlankLOC += $FileBlankLOC
	$TotalJsonPureLOC += ($FileLOC - $FileBlankLOC)
}

#
# All files totals
#
$TotalCommentLines = $TotalScriptCommentLines + $TotalXmlCommentLines + $TotalMarkdownCommentLines + $TotalJsonCommentLines
$TotalBlankCommentLines = $TotalScriptBlankCommentLines + $TotalXmlBlankCommentLines + $TotalMarkdownBlankCommentLines + $TotalJsonBlankCommentLines
$TotalPureCommentLines = $TotalScriptPureCommentLines + $TotalXmlPureCommentLines + $TotalMarkdownPureCommentLines + $TotalJsonPureCommentLines

$TotalLines = $TotalScriptLines + $TotalXmlLines + $TotalMarkdownLines + $TotalJsonLines
$TotalBlankLines = $TotalScriptBlankLines + $TotalXmlBlankLines + $TotalMarkdownBlankLines + $TotalJsonBlankLines

$TotalLOC = $TotalScriptLOC + $TotalXmlLOC + $TotalMarkdownLOC + $TotalJsonLOC
$TotalBlankLOC = $TotalScriptBlankLOC + $TotalXmlBlankLOC + $TotalMarkdownBlankLOC + $TotalJsonBlankLOC
$TotalPureLOC = $TotalScriptPureLOC + $TotalXmlPureLOC + $TotalMarkdownPureLOC + $TotalJsonPureLOC

Write-Information -MessageData "INFO: Writing log file"

$LogParams = @{
	LogName = "RepoStats"
	Raw = $true
	Path = "$ProjectRoot\Logs"
}

$HeaderStack.Push("Repository statistics")

#
# Scripts
#
Write-LogFile -Message "Script file count: $ScriptCount" @LogParams
Write-LogFile -Message "Total script lines: $TotalScriptLines" @LogParams
Write-LogFile -Message "Total script blank lines: $TotalScriptBlankLines" @LogParams

Write-LogFile -Message "Total script comment lines: $TotalScriptCommentLines" @LogParams
Write-LogFile -Message "Total script blank comment lines: $TotalScriptBlankCommentLines" @LogParams
Write-LogFile -Message "Total script pure comment lines: $TotalScriptPureCommentLines" @LogParams

Write-LogFile -Message "Total script LOC: $TotalScriptLOC" @LogParams
Write-LogFile -Message "Total script blank LOC: $TotalScriptBlankLOC" @LogParams
Write-LogFile -Message "Total script pure LOC: $TotalScriptPureLOC" @LogParams

#
# XML
#
Write-LogFile -Message "XML file count: $XmlFileCount" @LogParams
Write-LogFile -Message "Total XML lines: $TotalXmlLines" @LogParams
Write-LogFile -Message "Total XML blank lines: $TotalXmlBlankLines" @LogParams

Write-LogFile -Message "Total XML comment lines: $TotalXmlCommentLines" @LogParams
Write-LogFile -Message "Total XML blank comment lines: $TotalXmlBlankCommentLines" @LogParams
Write-LogFile -Message "Total XML pure comment lines: $TotalXmlPureCommentLines" @LogParams

Write-LogFile -Message "Total XML LOC: $TotalXmlLOC" @LogParams
Write-LogFile -Message "Total XML blank LOC: $TotalXmlBlankLOC" @LogParams
Write-LogFile -Message "Total XML pure LOC: $TotalXmlPureLOC" @LogParams

#
# Markdown
#
Write-LogFile -Message "Markdown file count: $MarkdownFileCount" @LogParams
Write-LogFile -Message "Total markdown lines: $TotalMarkdownLines" @LogParams
Write-LogFile -Message "Total markdown blank lines: $TotalMarkdownBlankLines" @LogParams

Write-LogFile -Message "Total markdown comment lines: $TotalMarkdownCommentLines" @LogParams
Write-LogFile -Message "Total markdown blank comment lines: $TotalMarkdownBlankCommentLines" @LogParams
Write-LogFile -Message "Total markdown pure comment lines: $TotalMarkdownPureCommentLines" @LogParams

Write-LogFile -Message "Total markdown LOC: $TotalMarkdownLOC" @LogParams
Write-LogFile -Message "Total markdown blank LOC: $TotalMarkdownBlankLOC" @LogParams
Write-LogFile -Message "Total markdown pure LOC: $TotalMarkdownPureLOC" @LogParams

#
# JSON
#
Write-LogFile -Message "JSON file count: $JsonFileCount" @LogParams
Write-LogFile -Message "Total JSON lines: $TotalJsonLines" @LogParams
Write-LogFile -Message "Total JSON blank lines: $TotalJsonBlankLines" @LogParams

Write-LogFile -Message "Total JSON comment lines: $TotalJsonCommentLines" @LogParams
Write-LogFile -Message "Total JSON blank comment lines: $TotalJsonBlankCommentLines" @LogParams
Write-LogFile -Message "Total JSON pure comment lines: $TotalJsonPureCommentLines" @LogParams

Write-LogFile -Message "Total JSON LOC: $TotalJsonLOC" @LogParams
Write-LogFile -Message "Total JSON blank LOC: $TotalJsonBlankLOC" @LogParams
Write-LogFile -Message "Total JSON pure LOC: $TotalJsonPureLOC" @LogParams

#
# All files totals
#
Write-LogFile -Message "Total file count: $AllFilesCount" @LogParams
Write-LogFile -Message "Total lines: $TotalLines" @LogParams
Write-LogFile -Message "Total blank lines: $TotalBlankLines" @LogParams

Write-LogFile -Message "Total comment lines: $TotalCommentLines" @LogParams
Write-LogFile -Message "Total blank comment lines: $TotalBlankCommentLines" @LogParams
Write-LogFile -Message "Total pure comment lines: $TotalPureCommentLines" @LogParams

Write-LogFile -Message "Total LOC: $TotalLOC" @LogParams
Write-LogFile -Message "Total blank LOC: $TotalBlankLOC" @LogParams
Write-LogFile -Message "Total pure LOC: $TotalPureLOC" @LogParams

$HeaderStack.Pop() | Out-Null
Update-Log


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021-2023 metablaster zebal@protonmail.ch

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
Unit test for Convert-EncodingString

.DESCRIPTION
Test correctness of Convert-EncodingString function

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Convert-EncodingString.ps1

.INPUTS
None. You cannot pipe objects to Convert-EncodingString.ps1

.OUTPUTS
None. Convert-EncodingString.ps1 does not generate any output

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

Enter-Test -Private "Convert-EncodingString"

$Encodings = @(
	"ascii", "bigendianunicode", "bigendianutf32", "oem", "unicode", "utf7",
	"utf8", "utf32", "utf8BOM", "utf8NoBOM", "byte", "default", "string", "unknown",
	"us-ascii", "utf-7", "utf-8", "unicodeFFFE", "utf-16BE", "utf-32BE", "utf-16", "utf-32"
)

Start-Test "utf-8 -BOM"
Convert-EncodingString "utf-8" -BOM

Start-Test "utf-8 -BOM:$false"
Convert-EncodingString "utf-8" -BOM:$false

Start-Test "utf8BOM"
$Result = Convert-EncodingString "utf8BOM"
$Result

Start-Test "all strings"
$Encodings | ForEach-Object {
	$LocalResult = Convert-EncodingString $_
	if ($LocalResult)
	{
		Write-Information -Tags "Test" -MessageData "INFO: $_ -> $LocalResult"
	}
}

Test-Output $Result -Command Convert-EncodingString

Update-Log
Exit-Test

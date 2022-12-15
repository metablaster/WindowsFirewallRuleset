
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
Unit test for Confirm-FileEncoding

.DESCRIPTION
Test correctness of Confirm-FileEncoding function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Confirm-FileEncoding.ps1

.INPUTS
None. You cannot pipe objects to Confirm-FileEncoding.ps1

.OUTPUTS
None. Confirm-FileEncoding.ps1 does not generate any output

.NOTES
As Administrator because of firewall logs in repository
#>

#Requires -Version 5.1
# NOTE: As Administrator if firewall writes logs to repository
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
#endregion

Enter-Test "Confirm-FileEncoding"

Start-Test "Initialize ProjectFiles variable"
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

$TestFiles = @(
	"ANSI.ansi"
	"ASCII.test"
	"utf-16LE.test"
	"utf-16LE+NonPrintable.test"
	"utf8.test"
	"utf8BOM.test"
	"utf16BE.test"
	"utf16LE.test"
)

if ($PSVersionTable.PSEdition -eq "Core")
{
	# NOTE: Ignoring, see New-ExternalHelpCab in Scripts\Update-HelpContent.ps1 for more info
	$Excludes += "*_HelpInfo.xml"
}

$ProjectFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Exclude $Excludes |
Where-Object { $_.Mode -notlike "*d*" } | Select-Object -ExpandProperty FullName

Start-Test "all files"
# NOTE: Avoiding errors for test files only
$ProjectFiles | ForEach-Object {
	$FileName = Split-Path $_ -Leaf
	if ($FileName -notin $TestFiles)
	{
		Confirm-FileEncoding -LiteralPath $_
	}
	else # Test files
	{
		$_ | Confirm-FileEncoding -EV Err -EA SilentlyContinue
		if ($Err)
		{
			Write-Information -Tags "Test" -MessageData "Encoding test on file $FileName success"
		}
		else
		{
			Write-Warning -Message "[$ThisScript] Encoding test on file $FileName expected to fail with PowerShell Desktop"
		}
	}
}

Start-Test "utf8.txt"
$TestFile = Resolve-Path -Path $PSScriptRoot\Encoding\utf8.test
$Result = Confirm-FileEncoding $TestFile.Path
$Result

Start-Test "binary file" -Force
Confirm-FileEncoding "$env:SystemRoot\regedit.exe" -EA SilentlyContinue
Restore-Test

Start-Test "binary file -Binary"
Confirm-FileEncoding "$env:SystemRoot\regedit.exe" -Binary

Test-Output $Result -Command Confirm-FileEncoding

Update-Log
Exit-Test

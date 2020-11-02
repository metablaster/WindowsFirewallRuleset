
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Unblock project files that were downloaded from the Internet.

.DESCRIPTION
Unblock project files that were downloaded from the Internet, this is needed to
unblock project that were downloaded from GitHub to prevent spamming YES/NO questions.

.EXAMPLE
PS> .\UnblockProject.ps1

.INPUTS
None. You cannot pipe objects to UnblockProject.ps1

.OUTPUTS
None. UnblockProject.ps1 does not generate any output

.NOTES
If executing scripts after manual download from internet or transfer from
another computer or media, you should "unblock" scripts by using this code.
TODO: We should probably unblock only scripts, not all files.
#>

# Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

Write-Information -Tags "User" -MessageData "INFO: Unblocking project files"
Get-ChildItem $ProjectRoot -Recurse | Unblock-File

Write-Information -Tags "User" -MessageData "INFO: Project files have been unblocked"

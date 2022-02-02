
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

<#PSScriptInfo

.VERSION 0.12.0

.GUID 075e5850-2741-4080-9f03-1d351f659b72

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Unblock project files that were downloaded from the Internet

.DESCRIPTION
Unblock project files that were downloaded from the Internet, this is needed to
unblock project that were downloaded from GitHub to prevent spamming YES/NO questions.

.EXAMPLE
PS> .\Unblock-Project.ps1

.INPUTS
None. You cannot pipe objects to Unblock-Project.ps1

.OUTPUTS
None. Unblock-Project.ps1 does not generate any output

.NOTES
If executing scripts after manual download from internet or transfer from
another computer or media, you should "unblock" scripts by using this code.
TODO: We should probably unblock only scripts, not all files.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding()]
[OutputType([void])]
param ()

New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

Write-Information -Tags $ThisScript -MessageData "INFO: Unblocking repository files" -INFA "Continue"
Get-ChildItem -Path $PSScriptRoot\.. -Recurse | Unblock-File

Write-Verbose -Message "[$ThisScript] $($Files.Count) All repository files have been unblocked"

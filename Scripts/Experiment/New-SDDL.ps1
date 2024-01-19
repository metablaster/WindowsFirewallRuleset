
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

<#PSScriptInfo

.VERSION 0.16.1

.GUID 41f894b5-457a-4167-aa3b-41de461f99c3

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Generate custom SDDL

.DESCRIPTION
Generate custom SDDL string by using a security dialog

.EXAMPLE
PS> .\New-SDDL

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
[OutputType([string])]
param ()

$SessionName = [guid]::NewGuid().Guid
Register-PSSessionConfiguration -Name $SessionName -NoServiceRestart -WarningAction SilentlyContinue `
	-SecurityDescriptorSddl "O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)(A;;GA;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)" | Out-Null

Set-PSSessionConfiguration -ShowSecurityDescriptorUI -Name $SessionName -WarningAction SilentlyContinue
$Session = Get-PSSessionConfiguration -Name $SessionName

Write-Information -MessageData $($Session.Permission) -InformationAction "Continue"
Write-Output ($Session | Select-Object -ExpandProperty SecurityDescriptorSddl)

Unregister-PSSessionConfiguration -Name $SessionName -NoServiceRestart

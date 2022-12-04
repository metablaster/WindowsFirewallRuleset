
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
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
Settings template.
A brief description of the script.

.DESCRIPTION
Use SettingsScript.ps1 as a template to write settings.
A detailed description of the script.

.PARAMETER Force
The description of a parameter.
Repeat ".PARAMETER" keyword for each parameter.

.EXAMPLE
PS> ScriptTemplate

Repeat ".EXAMPLE" keyword for each example

.INPUTS
None. You cannot pipe objects to ScriptTemplate.ps1

.OUTPUTS
None. ScriptTemplate.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSReviewUnusedParameter", "", Justification = "Template settings used by other scripts")]
param (
	[Parameter()]
	[switch] $Force
)

# Utility or settings scripts don't do anything on their own
if ($MyInvocation.InvocationName -ne '.')
{
	Write-Error -Category NotEnabled -TargetObject $MyInvocation.InvocationName `
		-Message "This is settings script and must be dot sourced where needed" -EA Stop
}

# TODO: Define settings here


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
. $PSScriptRoot\..\ModulePreferences.ps1

<#
Changes by metablaster - August 2020:
1. Included variables needed by of project
2. Included modules which are used in imported scripts
3. Separated scripts into Public and Private folder
4. Other significant changes and updates documented inside individual scripts
#>

$PrivateScripts = @(
	"Convert-ArrayToList"
	"Convert-ListToArray"
	"Convert-ListToMultiLine"
	"Convert-MultiLineToList"
	"Convert-ValueToBoolean"
)

$PublicScripts = @(
	"Export-FirewallRules"
	"Import-FirewallRules"
	"Remove-FirewallRules"
	"Format-Output"
	"Find-RulePrincipal"
)

foreach ($Script in $PrivateScripts)
{
	Write-Debug -Message "[$ThisModule] Importing private script: $Script.ps1"
	. ("{0}\Private\{1}.ps1" -f $PSScriptRoot, $Script)
}

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing public script: $Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

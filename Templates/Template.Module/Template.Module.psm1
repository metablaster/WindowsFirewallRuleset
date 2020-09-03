
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

# TODO: Update Copyright and start writing code

# Initialization
Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
# TODO: Update path, this one is adjusted for testing template module
. $PSScriptRoot\..\..\Modules\ModulePreferences.ps1

#
# Script imports
# TODO: remove unneeded imports
#

$PrivateScripts = @(
)

foreach ($Script in $PrivateScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: $Script.ps1"
	. ("{0}\Private\{1}.ps1" -f $PSScriptRoot, $Script)
}

$PublicScripts = @(
	"New-Function"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: $Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

#
# TODO: Module variables
#

# Template variable
Set-Variable -Name TemplateModuleVariable -Scope Global -Value $null

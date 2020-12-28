
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

# Initialization
using namespace System.Management.Automation # Get-InterfaceAlias
New-Variable -Name ThisModule -Scope Script -Option ReadOnly -Value (Split-Path $PSScriptRoot -Leaf)

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $ProjectRoot\Modules\ModulePreferences.ps1

# TODO: Functions for remote administration should be part of new module "Ruleset.NetworkInfo"

#
# Script imports
#

$PublicScripts = @(
	"ConvertFrom-OSBuild"
	"Get-Broadcast"
	"Get-ComputerName"
	"Get-InterfaceAlias"
	"Get-SystemSKU"
	"Resolve-Host"
	"Select-IPInterface"
	"Test-NetBiosName"
	"Test-TargetComputer"
	"Test-UNC"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. "$PSScriptRoot\Public\$Script.ps1"
}

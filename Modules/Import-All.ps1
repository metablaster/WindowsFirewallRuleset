
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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

[CmdletBinding()]
param ()

# Imports
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

#
# Import all modules into current session, useful to quickly load all module functions into session
#

$ModulesToImport = @(
	"Ruleset.ComputerInfo"
	"Ruleset.Firewall"
	"Ruleset.Initialize"
	"Ruleset.IP"
	"Ruleset.Logging"
	"Ruleset.PolicyFileEditor"
	"Ruleset.ProgramInfo"
	"Ruleset.Remote"
	"Ruleset.Test"
	"Ruleset.UserInfo"
	"Ruleset.Utility"
	"VSSetup"
)

if ($PSVersionTable.PSEdition -eq "Core")
{
	$ModulesToImport += "Ruleset.Compatibility"
}

foreach ($Module in $ModulesToImport)
{
	Import-Module -Name "$ProjectRoot\Modules\$Module" -Scope Global -Force
}

Update-Log

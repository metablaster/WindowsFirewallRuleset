
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
# TODO Use -InModule to avoid creating connection and just import module
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

#
# Import all modules into current session, useful to quickly load module functions into session
#

if ($PSVersionTable.PSEdition -eq "Desktop")
{
	$Modules = Get-ChildItem -Name Ruleset.* -Path "$ProjectRoot\Modules" -Directory -Exclude Ruleset.Compatibility
}
else
{
	$Modules = Get-ChildItem -Name Ruleset.* -Path "$ProjectRoot\Modules" -Directory
}

Import-Module -Name $Modules -Scope Global -Force
Update-Log

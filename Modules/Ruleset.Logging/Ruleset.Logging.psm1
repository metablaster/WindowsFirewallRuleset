
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

# Initialization
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\..\ModulePreferences.ps1

# TODO: stream logging instead of open/close file for performance

#
# Script imports
#

$PublicScripts = @(
	"Initialize-Log"
	"Update-Log"
	"Write-LogFile"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

#
# Module variables
#

if (!(Get-Variable -Name CheckInitLogging -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant: CheckInitLogging"
	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitLogging -Scope Global -Option Constant -Value $null

	# To prevent callers from overwriting a log header of each other we need a stack of headers
	New-Variable -Name HeaderStack -Scope Global -Value ([System.Collections.Stack]::new(@("")))
}

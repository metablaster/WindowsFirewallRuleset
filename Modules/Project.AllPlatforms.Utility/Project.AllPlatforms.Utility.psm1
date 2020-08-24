
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
. $PSScriptRoot\..\ModulePreferences.ps1

#
# Module variables
#

if (!(Get-Variable -Name CheckInitUtility -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant: CheckInitUtility"
	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUtility -Scope Global -Option Constant -Value $null

	Write-Debug -Message "[$ThisModule] Initialize global constant: ServiceHost"
	# Most used program
	New-Variable -Name ServiceHost -Scope Global -Option Constant -Value "%SystemRoot%\System32\svchost.exe"
}

Write-Debug -Message "[$ThisModule] Initialize module variable: Context"
# Global execution context, used in Approve-Execute
New-Variable -Name Context -Scope Script -Value "Context not set"

Write-Debug -Message "[$ThisModule] Initialize module variable: RecommendedBuffer"
# Recommended vertical screen buffer value, to ensure user can scroll back all the output
New-Variable -Name RecommendedBuffer -Scope Script -Option Constant -Value 1500

#
# Script imports
#

$ExternalExports = @(
	"Get-TypeName"
)

foreach ($Script in $ExternalExports)
{
	Write-Debug -Message "[$ThisModule] Importing script: $Script.ps1"
	. ("{0}\External\{1}.ps1" -f $PSScriptRoot, $Script)
}

$PublicScripts = @(
	"Approve-Execute"
	"Update-Context"
	"Convert-SDDLToACL"
	"Show-SDDL"
	"Get-NetworkService"
	"Set-ScreenBuffer"
	"Set-NetworkProfile"
	"Get-FileEncoding"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: $Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}


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
New-Variable -Name ThisModule -Scope Script -Option ReadOnly -Value (Split-Path $PSScriptRoot -Leaf)

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $ProjectRoot\Modules\ModulePreferences.ps1

#
# Script imports
#

$PrivateScripts = @(
	"External\Set-Privilege"
)

foreach ($Script in $PrivateScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Private\$Script.ps1"
	. "$PSScriptRoot\Private\$Script.ps1"
}

$PublicScripts = @(
	"Approve-Execute"
	"Compare-Path"
	"Confirm-FileEncoding"
	"Convert-SDDLToACL"
	"Get-EnvironmentVariable"
	"Get-FileEncoding"
	"Get-NetworkService"
	"Get-ProcessOutput"
	"Get-TypeName"
	"Resolve-Directory"
	"Set-NetworkProfile"
	"Set-Permission"
	"Set-ScreenBuffer"
	"Set-Shortcut"
	"Show-SDDL"
	"Update-Context"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. "$PSScriptRoot\Public\$Script.ps1"
}

#
# Module aliases
#

New-Alias -Name gt -Value Get-TypeName -Scope Global

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# Default execution context, used in Approve-Execute
New-Variable -Name Context -Scope Script -Value "Context not set"

if (!(Get-Variable -Name CheckInitUtility -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initializing module constants"

	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUtility -Scope Global -Option Constant -Value $null

	# Most used program
	# TODO: Should be part of ProgramInfo, which means importing module
	New-Variable -Name ServiceHost -Scope Global -Option Constant -Value "%SystemRoot%\System32\svchost.exe"
}


<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

# Set to true to indicate development phase, forces unloading modules and removing variables.
# In addition to this do (CTRL SHIFT + F) global search and uncomment symbols for: "to export from this module"
Set-Variable -Name Develop -Scope Global -Value $true

<#
Preference Variables default values
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7

$ConfirmPreference	High
$DebugPreference	SilentlyContinue
$ErrorActionPreference	Continue
$ErrorView	ConciseView
$FormatEnumerationLimit	4
$InformationPreference	SilentlyContinue
$LogCommandHealthEvent	False (not logged)
$LogCommandLifecycleEvent	False (not logged)
$LogEngineHealthEvent	True (logged)
$LogEngineLifecycleEvent	True (logged)
$LogProviderLifecycleEvent	True (logged)
$LogProviderHealthEvent	True (logged)
$MaximumHistoryCount	4096
$OFS	(Space character (" "))
$OutputEncoding	UTF8Encoding object
$ProgressPreference	Continue
$PSDefaultParameterValues	(None - empty hash table)
$PSEmailServer	(None)
$PSModuleAutoLoadingPreference	All
$PSSessionApplicationName	wsman
$PSSessionConfigurationName	https://schemas.microsoft.com/powershell/Microsoft.PowerShell
$PSSessionOption	See $PSSessionOption
$VerbosePreference	SilentlyContinue
$WarningPreference	Continue
$WhatIfPreference	False
#>

if ($Develop)
{
	# Override above defaults here however you wish, will be globally set except in modules
	$DebugPreference = "Continue"
	# $VerbosePreference = "Continue"
	
	# Preferences for modules
	Set-Variable -Name ModuleDebugPreference -Scope Global -Value $DebugPreference

	Write-Debug "Setting -> Clean up environment"

	#
	# Remove loaded modules, usefull for module debugging
	# and to avoid restarting powershell every time.
	#

	Remove-Module -Name System -ErrorAction Ignore
	Remove-Module -Name FirewallModule -ErrorAction Ignore
	Remove-Module -Name Test -ErrorAction Ignore
	Remove-Module -Name UserInfo -ErrorAction Ignore
	Remove-Module -Name ComputerInfo -ErrorAction Ignore
	Remove-Module -Name ProgramInfo -ErrorAction Ignore
}

if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug "Setting -> Project constants"

	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

	# Repository root directory, realocating scripts should be easy if root directory is constant
	New-Variable -Name RepoDir -Scope Global -Option Constant -Value (Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)
	# Windows 10, Windows Server 2019 and above
	New-Variable -Name Platform -Scope Global -Option Constant -Value "10.0+"
	# Machine where to apply rules (default: Local Group Policy)
	New-Variable -Name PolicyStore -Scope Global -Option Constant -Value "localhost"
	# Default network interface card, change this to NIC which your target PC uses
	New-Variable -Name Interface -Scope Global -Option Constant -Value "Wired, Wireless"
	# To force loading rules regardless of presence of program set to true
	New-Variable -Name Force -Scope Global -Option Constant -Value $false
}

if (!(Get-Variable -Name CheckRemovableVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug "Setting -> Project variables"

	# check if removable variables already initialized
	Set-Variable -Name CheckRemovableVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Set to false to avoid checking system requirements
	Set-Variable -Name SystemCheck -Scope Global -Option ReadOnly -Force -Value $false

	# Global variable to tell if all scripts ran clean
	Set-Variable -Name WarningStatus -Scope Global -Value $false
}

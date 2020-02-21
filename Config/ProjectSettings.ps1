
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

#
# NOTE: In this file various project settings and preferences are set, these are grouped into
# 1. settings for development
# 2. settings for end users
# 3. settings that apply to both use cases
#

# Set to true to indicate development phase, forces unloading modules and removing variables.
Set-Variable -Name Develop -Scope Global -Value $true

# Name of this script for debugging messages, do not modify!.
Set-Variable -Name ThisScript -Scope Local -Option ReadOnly -Value $($MyInvocation.MyCommand.Name -replace ".{4}$")

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

# These settings apply only for development phase
if ($Develop)
{
	#
	# Override preference defaults for scripts here,
	#

	# $ErrorActionPreference = "SilentlyContinue"
	# $WarningPreference = "SilentlyContinue"
	$VerbosePreference = "Continue"
	$DebugPreference = "Continue"
	$InformationPreference = "Continue"

	# Must be after debug preference
	Write-Debug -Message "[$ThisScript] Setup clean environment"

	#
	# Preferences for modules
	#

	Set-Variable -Name ModuleErrorPreference -Scope Global -Value $ErrorActionPreference
	Set-Variable -Name ModuleWarningPreference -Scope Global -Value $WarningPreference
	Set-Variable -Name ModuleVerbosePreference -Scope Global -Value $VerbosePreference
	Set-Variable -Name ModuleDebugPreference -Scope Global -Value $DebugPreference
	Set-Variable -Name ModuleInformationPreference -Scope Global -Value $InformationPreference

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
else # Normal use case
{
	# These are set to default values for normal use case,
	# modify to customize your experience
	$ErrorActionPreference = "Continue"
	$WarningPreference = "Continue"
	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"
	$InformationPreference = "Continue"

	# Preferences for modules not used, do not modify!
	Remove-Variable -Name ModuleErrorPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleWarningPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleVerbosePreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleDebugPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleInformationPreference -Scope Global -ErrorAction Ignore
}

# These are set only once per session, changing these requires powershell restart
if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup constant variables"

	# check if constants alreay initialized, used for module reloading, do not modify!
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

	# Repository root directory, realocating scripts should be easy if root directory is constant
	New-Variable -Name RepoDir -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)

	# Windows 10, Windows Server 2019 and above
	New-Variable -Name Platform -Scope Global -Option Constant -Value "10.0+"

	# Machine where to apply rules (default: Local Group Policy)
	New-Variable -Name PolicyStore -Scope Global -Option Constant -Value "localhost"

	# Default network interface card, change this to NIC which your target PC uses
	New-Variable -Name Interface -Scope Global -Option Constant -Value "Wired, Wireless"

	# To force loading rules regardless of presence of program set to true
	New-Variable -Name Force -Scope Global -Option Constant -Value $false
}

# These are set only once per session, changing these requires powershell restart, except if Develop = $true
if ($Develop -or !(Get-Variable -Name CheckRemovableVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup removable variables"

	# check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckRemovableVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Set to false to avoid checking system requirements
	Set-Variable -Name SystemCheck -Scope Global -Option ReadOnly -Force -Value $false

	# Set to false to disable logging errors
	Set-Variable -Name ErrorLogging -Scope Global -Value $true

	# Set to false to disable logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value $true

	# Set to false to disable logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value $true
}

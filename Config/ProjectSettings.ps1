
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
# TODO: we could auto include this file with module manifests
# NOTE: In this file various project settings and preferences are set, these are grouped into
# 1. settings for development
# 2. settings for end users
# 3. settings that apply to both use cases
#

Set-StrictMode -Version Latest

# Set to true to indicate development phase, it does following at a minimum:
# 1. Forces unloading modules and removing variables.
# 2. Loads troubleshooting rules defined in Temporary.ps1
# 3. Performs some additional checks
# 4. Enables some unit tests
Set-Variable -Name Develop -Scope Global -Value $false

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
	$InformationPreference = "Continue"
	# $VerbosePreference = "Continue"
	# $DebugPreference = "Continue"

	# Must be after debug preference
	Write-Debug -Message "[$ThisScript] Setup clean environment"

	#
	# Preferences for modules
	#

	Set-Variable -Name ModuleErrorPreference -Scope Global -Value $ErrorActionPreference
	Set-Variable -Name ModuleWarningPreference -Scope Global -Value $WarningPreference
	Set-Variable -Name ModuleInformationPreference -Scope Global -Value $InformationPreference
	Set-Variable -Name ModuleVerbosePreference -Scope Global -Value $VerbosePreference
	Set-Variable -Name ModuleDebugPreference -Scope Global -Value $DebugPreference

	#
	# Remove loaded modules, useful for module debugging
	# and to avoid restarting powershell every time.
	#

	Remove-Module -Name Project.AllPlatforms.System -ErrorAction Ignore
	Remove-Module -Name Project.AllPlatforms.Test -ErrorAction Ignore
	Remove-Module -Name Project.AllPlatforms.Logging -ErrorAction Ignore
	Remove-Module -Name Project.AllPlatforms.Utility -ErrorAction Ignore
	Remove-Module -Name Project.Windows.UserInfo -ErrorAction Ignore
	Remove-Module -Name Project.Windows.ComputerInfo -ErrorAction Ignore
	Remove-Module -Name Project.Windows.ProgramInfo -ErrorAction Ignore
}
else # Normal use case
{
	# These are set to default values for normal use case,
	# modify to customize your experience, note that this has no effect on modules!
	$ErrorActionPreference = "Continue"
	$WarningPreference = "Continue"
	$InformationPreference = "Continue"
	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"

	# Must be after verbose preference
	Write-Verbose -Message "[$ThisScript] Project mode: User"

	# Preferences for modules not used, do not modify!
	Remove-Variable -Name ModuleErrorPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleWarningPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleVerbosePreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleDebugPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleInformationPreference -Scope Global -ErrorAction Ignore
}

# Constant variables, not possible to change in any case.
# These are set only once per session, changing these requires powershell restart
if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup constant variables"

	# check if constants already initialized, used for module reloading, do not modify!
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

	# Repository root directory, reallocating scripts should be easy if root directory is constant
	New-Variable -Name ProjectRoot -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)

	# Windows 10, Windows Server 2019 and above
	New-Variable -Name Platform -Scope Global -Option Constant -Value "10.0+"

	# Machine where to apply rules (default: Local Group Policy)
	New-Variable -Name PolicyStore -Scope Global -Option Constant -Value ([System.Environment]::MachineName)

	# If you changed PolicyStore variable, but the project is not yet ready for remote administration
	if ($Develop -and $PolicyStore -ne [System.Environment]::MachineName)
	{
		# To force loading rules regardless of presence of program set to true
		New-Variable -Name RemoteCredentials -Scope Global -Option Constant -Value (
			Get-Credential -Message "Credentials are required to access $PolicyStore")

		try
		{
			Write-Information -Tags "Project" -MessageData "Testing Windows Remote Management to: $PolicyStore"
			Test-WSMan -ComputerName $PolicyStore -Credential $RemoteCredentials
		}
		catch
		{
			Write-Error -TargetObject $_.TargetObject `
				-Message "Windows Remote Management connection test to '$PolicyStore' failed: $_"
			exit
		}
	}

	# Default network interface card, change this to NIC which your target PC uses
	New-Variable -Name Interface -Scope Global -Option Constant -Value "Wired, Wireless"

	# To force loading rules regardless of presence of program set to true
	New-Variable -Name ForceLoad -Scope Global -Option Constant -Value $false
}

# Read only variables, meaning these can be modified by code at any time,
# and, only once per session by users.
# Changing these requires powershell restart, except if Develop = $true
if ($Develop -or !(Get-Variable -Name CheckReadOnlyVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup read only variables"

	# check if read only variables already initialized, do not modify!
	Set-Variable -Name CheckReadOnlyVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Set to false to avoid checking system requirements
	Set-Variable -Name SystemCheck -Scope Global -Option ReadOnly -Force -Value $true
}

# Removable variables, meaning these can be modified by code at any time,
# And, only once per session by users.
# Changing these requires powershell restart, except if Develop = $true
if ($Develop -or !(Get-Variable -Name CheckRemovableVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup removable variables"

	# check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckRemovableVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Amount of connection tests against remote computers
	Set-Variable -Name ConnectionCount -Scope Global -Value 2

	# Timeout in seconds to contact remote computers
	Set-Variable -Name ConnectionTimeout -Scope Global -Value 1

	# Set to false to disable logging errors
	Set-Variable -Name ErrorLogging -Scope Global -Value $true

	# Set to false to disable logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value $true

	# Set to false to disable logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value $true
}

# Protected variables, meaning these can be modified but only by code (excluded from Develop mode)
# These are initially set only once per session, changing these requires powershell restart.
if (!(Get-Variable -Name CheckProtectedVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup protected variables"

	# check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckProtectedVariables -Scope Global -Option Constant -Force -Value $null

	# Global variable to tell if errors were generated, do not modify!
	# Will not be set if ErrorActionPreference is "SilentlyContinue"
	Set-Variable -Name ErrorStatus -Scope Global -Value $false

	# Global variable to tell if warnings were generated, do not modify!
	# Will not be set if WarningPreference is "SilentlyContinue"
	Set-Variable -Name WarningStatus -Scope Global -Value $false
}

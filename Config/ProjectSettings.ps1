
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

#
# TODO: we could auto include this file with module manifests
# NOTE: In this file project settings and preferences are set, these are grouped into
# 1. settings for development
# 2. settings for release
# 3. settings that apply to both use cases
# NOTE: Make sure not to modify variables commend as "do not modify" or "do not decrement"
#

param(
	# modules must call this script with the value of $true
	[bool] $InsideModule = $false
)

# Set to true to enable development features, it does following at a minimum:
# 1. Forces reloading modules and removable variables.
# 2. Loads troubleshooting rules defined in Temporary.ps1
# 3. Performs additional requirements checks needed or recommended for development
# 4. Enables some disabled unit tests and disables logging
# 5. Enables setting preference variables for modules
Set-Variable -Name Develop -Scope Global -Value $true

if ($Develop)
{
	# The Set-PSDebug cmdlet turns script debugging features on and off, sets the trace level, and toggles strict mode.
	# Strict: Turns on strict mode for the global scope, this is equivalent to Set-StrictMode -Version 1
	# Trace 1: each line of script is traced as it runs.
	# Trace 2: variable assignments, function calls, and script calls are also traced.
	# Step: You're prompted before each line of the script runs.
	Set-PSDebug -Strict # -Trace 1

	# Override version set by et-PSDebug
	Set-StrictMode -Version Latest
}
else
{
	# The Set-StrictMode configures strict mode for the current scope and all child scopes
	# Use it in a script or function to override the setting inherited from the global scope.
	Set-StrictMode -Version Latest
}

# Name of this script for debugging messages, do not modify!.
Set-Variable -Name ThisScript -Scope Local -Option ReadOnly -Value $($MyInvocation.MyCommand.Name -replace ".{4}$")

<#
Preference Variables default values
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7

$ConfirmPreference			High
$DebugPreference			SilentlyContinue
$ErrorActionPreference		Continue
$ErrorView					ConciseView
$FormatEnumerationLimit		4
$InformationPreference		SilentlyContinue
$LogCommandHealthEvent		False (not logged)
$LogCommandLifecycleEvent	False (not logged)
$LogEngineHealthEvent		True (logged)
$LogEngineLifecycleEvent	True (logged)
$LogProviderLifecycleEvent	True (logged)
$LogProviderHealthEvent		True (logged)
$MaximumHistoryCount		4096
$OFS						(Space character (" "))

Applies to how PowerShell communicates with external programs (what encoding PowerShell uses when sending strings to them)
it has nothing to do with the encoding that the output redirection operators and PowerShell cmdlets use to save to files.
$OutputEncoding				UTF8Encoding object

$ProgressPreference	Continue
$PSDefaultParameterValues	(None - empty hash table)
$PSEmailServer				(None)
$PSModuleAutoLoadingPreference	All
$PSSessionApplicationName	wsman
$PSSessionConfigurationName	https://schemas.microsoft.com/powershell/Microsoft.PowerShell
$PSSessionOption			See $PSSessionOption
$VerbosePreference			SilentlyContinue
$WarningPreference			Continue
$WhatIfPreference			False
#>

# These settings apply only for development phase
if ($Develop)
{
	#
	# Override preference defaults for scripts here
	# NOTE: do not modify warning and information preference
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
	# Remove loaded modules, useful for module debugging and to avoid restarting powershell every time.
	#

	if (!$InsideModule)
	{
		# Skip removing modules if this script is called inside module which would
		# cause removing modules prematurely
		Remove-Module -Name Project.AllPlatforms.Initialize -ErrorAction Ignore
		Remove-Module -Name Project.AllPlatforms.Test -ErrorAction Ignore
		Remove-Module -Name Project.AllPlatforms.Logging -ErrorAction Ignore
		Remove-Module -Name Project.AllPlatforms.Utility -ErrorAction Ignore
		Remove-Module -Name Project.Windows.UserInfo -ErrorAction Ignore
		Remove-Module -Name Project.Windows.ComputerInfo -ErrorAction Ignore
		Remove-Module -Name Project.Windows.ProgramInfo -ErrorAction Ignore
		Remove-Module -Name Project.Windows.Firewall -ErrorAction Ignore
		Remove-Module -Name Indented.Net.IP -ErrorAction Ignore
	}
}
else # Normal use case
{
	# These are set to default values for normal use case,
	# modify to customize your experience, note that this has no effect on modules

	# To control how and if errors are displayed
	$ErrorActionPreference = "Continue"

	# To control how and if warnings are displayed, do not modify!
	$WarningPreference = "Continue"

	# To control how and if informational messages are displayed, do not modify!
	$InformationPreference = "Continue"

	# To show verbose output in the console set to "Continue"
	# If you want to see a bit more
	$VerbosePreference = "SilentlyContinue"

	# To show debugging messages in the console set to "Continue"
	# Not recommended except to troubleshoot problems with project
	$DebugPreference = "SilentlyContinue"

	# Must be after verbose preference
	Write-Verbose -Message "[$ThisScript] Project mode: User"

	# Preferences for modules not used in this context, do not modify
	Remove-Variable -Name ModuleErrorPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleWarningPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleVerbosePreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleDebugPreference -Scope Global -ErrorAction Ignore
	Remove-Variable -Name ModuleInformationPreference -Scope Global -ErrorAction Ignore
}

# TODO: encoding variable
# Constant variables, not possible to change in any case.
# These are set only once per session, changing these requires powershell restart
if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisScript] Setup constant variables"

	# check if constants already initialized, used for module reloading, do not modify!
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

	# Project version, does not apply to non migrated 3rd party modules which follow their own version increment, do not modify!
	New-Variable -Name ProjectVersion -Scope Global -Option Constant -Value ([version]::new(0, 6, 0))

	# Required minimum PSScriptAnalyzer version for code editing, do not decrement!
	# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing probably due to analyzer settings
	# https://github.com/PowerShell/PSScriptAnalyzer#requirements
	New-Variable -Name RequireAnalyzerVersion -Scope Global -Option Constant -Value ([version]::new(1, 19, 1))

	# Recommended minimum posh-git version for git in PowerShell
	# NOTE: pre-release minimum 1.0.0-beta4 will be installed
	New-Variable -Name RequirePoshGitVersion -Scope Global -Option Constant -Value ([version]::new(0, 7, 3))

	# Recommended minimum Pester version for code testing
	# NOTE: Analyzer 1.19.1 requires pester v5
	# TODO: we need pester v4 for tests, but why does analyzer require pester?
	New-Variable -Name RequirePesterVersion -Scope Global -Option Constant -Value ([version]::new(5, 0, 3))

	# Required minimum PackageManagement version prior to installing other modules, do not decrement!
	New-Variable -Name RequirePackageManagementVersion -Scope Global -Option Constant -Value ([version]::new(1, 4, 7))

	# Required minimum PowerShellGet version prior to installing other modules, do not decrement!
	New-Variable -Name RequirePowerShellGetVersion -Scope Global -Option Constant -Value ([version]::new(2, 2, 4))

	# Recommended minimum Git version needed for contributing and required by posh-git
	# https://github.com/dahlbyk/posh-git#prerequisites
	New-Variable -Name RequireGitVersion -Scope Global -Option Constant -Value ([version]::new(2, 28, 0))

	# Recommended minimum PowerShell Core
	# NOTE: 6.1.0 will not work, but 7.0.3 works, verify with PSUseCompatibleCmdlets
	New-Variable -Name RequireCoreVersion -Scope Global -Option Constant -Value ([version]::new(7, 0, 3))

	# Required minimum Windows PowerShell, do not decrement!
	# NOTE: 5.1.14393.206 (system v1607) will not work, but 5.1.19041.1 (system v2004) works, verify with PSUseCompatibleCmdlets
	# NOTE: replacing build 19041 (system v2004) with 18362 (system v1903) which is minimum required for rules and .NET
	New-Variable -Name RequirePowerShellVersion -Scope Global -Option Constant -Value ([version]::new(5, 1, 18362))

	# Required minimum operating system version (v1903)
	# https://docs.microsoft.com/en-us/windows/release-information
	# https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
	New-Variable -Name RequireWindowsVersion -Scope Global -Option Constant -Value ([version]::new(10, 0, 18362))

	# Required minimum .NET version, valid for the PowerShell Desktop edition only, do not decrement!
	# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies
	# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
	# https://docs.microsoft.com/en-us/dotnet/framework/get-started/system-requirements
	# https://stackoverflow.com/questions/63520845/determine-net-and-clr-requirements-for-your-powershell-modules/63547710
	# https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/windows-powershell-system-requirements?view=powershell-7.1
	# NOTE: v1703 includes .NET 4.7
	# NOTE: v1903-v2004 includes .NET 4.8
	New-Variable -Name RequireNETVersion -Scope Global -Option Constant -Value ([version]::new(4, 8, 0))

	# Repository root directory, reallocating scripts should be easy if root directory is constant
	New-Variable -Name ProjectRoot -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)

	# Add project module directory to session module path
	$ModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath")
	$ModulePath += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Modules"
	[System.Environment]::SetEnvironmentVariable("PSModulePath", $ModulePath)

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
			# TODO: should be part of Initialize-Project script
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
	Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value (!$Develop)

	# Set to false to avoid checking if modules are up to date
	Set-Variable -Name ModulesCheck -Scope Global -Option ReadOnly -Force -Value $Develop

	# Set to false to avoid checking if required system services are started
	Set-Variable -Name ServicesCheck -Scope Global -Option ReadOnly -Force -Value $true

	# Required minimum NuGet version prior to installing other modules
	# NOTE: Core >= 3.0.0, Desktop >= 2.8.5, Desktop will be set in Initialize-Project
	New-Variable -Name RequireNuGetVersion -Scope Global -Option ReadOnly -Force -Value ([version]::new(3, 0, 0))
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
	Set-Variable -Name ErrorLogging -Scope Global -Value (!$Develop)

	# Set to false to disable logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value (!$Develop)

	# Set to false to disable logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value (!$Develop)
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

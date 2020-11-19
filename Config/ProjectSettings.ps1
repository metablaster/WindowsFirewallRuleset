
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

<#
.SYNOPSIS
Global project settings and preferences

.DESCRIPTION
In this file project settings and preferences are set, these are grouped into
1. settings for development
2. settings for release
3. settings that apply to both use cases

.PARAMETER InsideModule
Script modules must call this script with this parameter

.PARAMETER ShowPreference
If specified displays preferences and/or variables of current scope

.EXAMPLE
PS> .\ProjectSettings.ps1

.INPUTS
None. You cannot pipe objects to ProjectSettings.ps1

.OUTPUTS
None. ProjectSettings.ps1 does not generate any output

.NOTES
TODO: We could auto include this file with module manifests or dynamic module
NOTE: Make sure not to modify variables commented as "do not modify" or "do not decrement"
TODO: Use advanced parameters to control Verbose, Debug, Confirm and WhatIf locally
TODO: Variable description should be part of variable object
#>

[CmdletBinding(PositionalBinding = $false)]
param(
	[Parameter()]
	[switch] $InsideModule,

	[Parameter()]
	[switch] $ShowPreference
)

# Name of this script for debugging messages, do not modify!.
Set-Variable -Name SettingsScript -Scope Local -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{4}$")
Write-Debug -Message "[$SettingsScript] params($($PSBoundParameters.Values))"

if ($MyInvocation.InvocationName -ne ".")
{
	Write-Error -Category InvalidOperation -TargetObject $SettingsScript `
		-Message "$SettingsScript must be dot sourced"

	Write-Information -Tags "Project" -MessageData "$SettingsScript called from: $((Get-PSCallStack)[1].Command)"
	exit
}

# Set to true to enable development features, it does following at a minimum:
# 1. Forces reloading modules and removable variables.
# 2. Loads troubleshooting rules defined in Temporary.ps1
# 3. Performs additional requirements checks needed or recommended for development
# 4. Enables some disabled unit tests and disables logging
# 5. Enables setting preference variables for modules
# NOTE: If changed to $true, the change requires PowerShell restart
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

	# Enable showing values of preference variables in requested scope
	if ($PSBoundParameters.ContainsKey("ShowPreference"))
	{
		$PSBoundParameters.Remove("ShowPreference") | Out-Null
		Set-Variable -Name ShowPreference -Scope Global -Value $true
	}
	else
	{
		Set-Variable -Name ShowPreference -Scope Global -Value $false
	}
}
else
{
	# The Set-StrictMode configures strict mode for the current scope and all child scopes
	# Use it in a script or function to override the setting inherited from the global scope.
	Set-StrictMode -Version Latest
}

# NOTE: This variable is needed early
if (!(Get-Variable -Name ProjectRoot -Scope Global -ErrorAction Ignore))
{
	# Repository root directory, reallocating scripts should be easy if root directory is constant
	New-Variable -Name ProjectRoot -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)
}

<#
Preference Variables default values (Core / Desktop)
# TODO: Add valid values column and defaults per edition
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1

$ErrorActionPreference		Continue
$WarningPreference			Continue
$InformationPreference		SilentlyContinue
$VerbosePreference			SilentlyContinue
$DebugPreference			SilentlyContinue

$ConfirmPreference			High
$WhatIfPreference			False

$ProgressPreference			Continue
$PSModuleAutoLoadingPreference	All
$PSDefaultParameterValues	(None - empty hash table)

$LogCommandHealthEvent		False (not logged)
$LogCommandLifecycleEvent	False (not logged)
$LogEngineHealthEvent		True (logged)
$LogEngineLifecycleEvent	True (logged)
$LogProviderLifecycleEvent	True (logged)
$LogProviderHealthEvent		True (logged)

$ErrorView					ConciseView / NormalView
$MaximumHistoryCount		4096
$FormatEnumerationLimit		4
$OFS						(Space character (" "))
$PSEmailServer				(None)

NOTE: Applies to how PowerShell communicates with external programs
(what encoding PowerShell uses when sending strings to them)
it has nothing to do with the encoding that the output redirection operators and
PowerShell cmdlets use to save to files.
$OutputEncoding				System.Text.UTF8Encoding / System.Text.ASCIIEncoding

$PSSessionApplicationName	wsman
$PSSessionConfigurationName	https://schemas.microsoft.com/powershell/Microsoft.PowerShell
$PSSessionOption			See $PSSessionOption

$Transcript					$Home\My Documents directory as \PowerShell_transcript.<time-stamp>.txt

NOTE: Windows PowerShell only
$MaximumAliasCount		4096
$MaximumDriveCount		4096
$MaximumErrorCount		256
$MaximumFunctionCount	4096
$MaximumVariableCount	4096
#>

# NOTE: Following preferences should be always the same, do not modify!
# The rest of preferences are either default or depending on "Develop" variable

# To control how and if errors are displayed
$ErrorActionPreference = "Continue"

# To control how and if warnings are displayed
$WarningPreference = "Continue"

# To control how and if informational messages are displayed
$InformationPreference = "Continue"

# Determines how PowerShell responds to progress bar updates generated by the Write-Progress cmdlet
$ProgressPreference	= "Continue"

# To control if modules automatically load
# Values: All, ModuleQualified or None
$PSModuleAutoLoadingPreference = "All"

# TODO: $PSDefaultParameterValues = $null

if ($Develop)
{
	#
	# Following preferences apply only for development phase,
	# must be explicitly set to avoid inheriting parent scope preferences
	#

	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"
	$ConfirmPreference = "High"
	$WhatIfPreference = "False"
	# TODO: $ErrorView = "ConciseView"

	# Two variables for each of the three logging components:
	# The engine (the PowerShell program), the providers and the commands.
	# The LifeCycleEvent variables log normal starting and stopping events.
	# The Health variables log error events.
	# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_eventlogs?view=powershell-5.1#selecting-events-for-the-windows-powershell-event-log

	# TODO: Report issue, unable to set single SuppressMessageAttribute
	# Logs the start and stop of PowerShell
	$LogEngineLifeCycleEvent = $false

	# Logs PowerShell program errors
	$LogEngineHealthEvent = $false

	# Logs the start and stop of PowerShell providers
	$LogProviderLifeCycleEvent = $false

	# Logs PowerShell provider errors
	$LogProviderHealthEvent = $false

	# Logs the starting and completion of commands
	$LogCommandLifeCycleEvent = $false

	# Logs command errors
	$LogCommandHealthEvent = $false

	# Must be after debug preference
	Write-Debug -Message "[$SettingsScript] Clean up PowerShell session"

	if (!$InsideModule)
	{
		# Remove loaded modules, useful for module debugging and to avoid restarting powershell every time.
		# Skip removing modules if this script is called from inside a module which would
		# cause removing modules prematurely
		foreach ($Module in @(Get-ChildItem -Name -Path "$ProjectRoot\Modules" -Directory))
		{
			Remove-Module -Name $Module -ErrorAction Ignore
		}
	}
}
else # Normal use case
{
	# These are set to default values for normal use case, the rest is default,
	# modify to customize your experience

	# To show verbose output in the console set to "Continue"
	# If you want to see a bit more
	$VerbosePreference = "SilentlyContinue"

	# To show debugging messages in the console set to "Continue"
	# Not recommended except to troubleshoot problems with code
	$DebugPreference = "SilentlyContinue"

	$ConfirmPreference = "High"

	$WhatIfPreference = "False"

	# Must be after verbose preference
	Write-Verbose -Message "[$SettingsScript] Project mode: Release"
}

# Constant variables, not possible to change in any case.
# These are set only once per session, changing these requires powershell restart
# TODO: Skip setting variables which are used only when checking specific requirements
if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setup constant variables"

	# check if constants already initialized, used for module reloading, do not modify!
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

	# Project version, does not apply to non migrated 3rd party modules which follow their own version increment, do not modify!
	New-Variable -Name ProjectVersion -Scope Global -Option Constant -Value ([version]::new(0, 8, 1))

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
	New-Variable -Name RequirePesterVersion -Scope Global -Option Constant -Value ([version]::new(5, 0, 4))

	# Required minimum PackageManagement version prior to installing other modules, do not decrement!
	New-Variable -Name RequirePackageManagementVersion -Scope Global -Option Constant -Value ([version]::new(1, 4, 7))

	# Required minimum PowerShellGet version prior to installing other modules, do not decrement!
	New-Variable -Name RequirePowerShellGetVersion -Scope Global -Option Constant -Value ([version]::new(2, 2, 5))

	# Recommended minimum platyPS version used to generate online help files for modules, do not decrement!
	New-Variable -Name RequirePlatyPSVersion -Scope Global -Option Constant -Value ([version]::new(0, 14, 0))

	# Recommended minimum VSCode version, do not decrement!
	New-Variable -Name RequireVSCodeVersion -Scope Global -Option Constant -Value ([version]::new(1, 51, 1))

	# Recommended minimum PSReadline version for command line editing experience of PowerShell
	# Needs the 1.6.0 or a higher version of PowerShellGet to install the latest prerelease version of PSReadLine
	New-Variable -Name RequirePSReadlineVersion -Scope Global -Option Constant -Value ([version]::new(2, 1, 0))

	# Recommended minimum Git version needed for contributing and required by posh-git
	# https://github.com/dahlbyk/posh-git#prerequisites
	New-Variable -Name RequireGitVersion -Scope Global -Option Constant -Value ([version]::new(2, 29, 0))

	# Recommended minimum PowerShell Core
	# NOTE: 6.1.0 will not work, but 7.0.3 works, verify with PSUseCompatibleCmdlets
	New-Variable -Name RequireCoreVersion -Scope Global -Option Constant -Value ([version]::new(7, 1, 0))

	# Required minimum Windows PowerShell, do not decrement!
	# NOTE: 5.1.14393.206 (system v1607) will not work, but 5.1.19041.1 (system v2004) works, verify with PSUseCompatibleCmdlets
	# NOTE: replacing build 19041 (system v2004) with 17763 (system v1809) which is minimum required for rules and .NET
	New-Variable -Name RequirePowerShellVersion -Scope Global -Option Constant -Value ([version]::new(5, 1, 17763))

	# Required minimum operating system version (v1809)
	# TODO: v1809 needs to be replaced with minimum v1903, downgraded here because of Server 2019
	# https://docs.microsoft.com/en-us/windows/release-information
	# https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
	New-Variable -Name RequireWindowsVersion -Scope Global -Option Constant -Value ([version]::new(10, 0, 17763))

	# Required minimum .NET version, valid for the PowerShell Desktop edition only, do not decrement!
	# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies
	# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
	# https://docs.microsoft.com/en-us/dotnet/framework/get-started/system-requirements
	# https://stackoverflow.com/questions/63520845/determine-net-and-clr-requirements-for-your-powershell-modules/63547710
	# https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/windows-powershell-system-requirements?view=powershell-7.1
	# NOTE: v1703 includes .NET 4.7
	# NOTE: v1903-v2004 includes .NET 4.8
	# TODO: Last test on Server 2019 which comes with .NET 4.7 run just fine,
	# modules loaded even though .NET 4.8 is specified as minimum required
	New-Variable -Name RequireNETVersion -Scope Global -Option Constant -Value ([version]::new(4, 8, 0))

	# TODO: Should not be visible
	# Add project module directory to session module path
	New-Variable -Name TempPath -Scope Script -Value ([System.Environment]::GetEnvironmentVariable("PSModulePath"))
	# $ModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath")
	$TempPath += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Modules"
	[System.Environment]::SetEnvironmentVariable("PSModulePath", $TempPath)

	# Add project script directory to session path
	$TempPath = [System.Environment]::GetEnvironmentVariable("Path")
	$TempPath = $TempPath.TrimEnd(";")
	$TempPath += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts"
	$TempPath += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\External"
	[System.Environment]::SetEnvironmentVariable("Path", $TempPath)
	Remove-Variable -Name TempPath -Scope Script

	# Windows 10, Windows Server 2019 and above
	New-Variable -Name Platform -Scope Global -Option Constant -Value "10.0+"

	# Machine where to apply rules (default: Local Group Policy)
	New-Variable -Name PolicyStore -Scope Global -Option Constant -Value ([System.Environment]::MachineName)

	# If you changed PolicyStore variable, but the project is not yet ready for remote administration
	if ($Develop -and $PolicyStore -ne ([System.Environment]::MachineName))
	{
		# TODO: Need to verify non GPO stores to prevent asking for credentials for ex. "PersistentStore"
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

	# Default network interface card to use if not locally specified
	# TODO: We can learn this value programatically but, problem is the same as with specifying local IP
	New-Variable -Name DefaultInterface -Scope Global -Option Constant -Value "Wired, Wireless"

	# Default network profile to use if not locally specified.
	# NOTE: Do not modify except to to debug rules or unless absolutely needed!
	New-Variable -Name DefaultProfile -Scope Global -Option Constant -Value "Private, Public"

	# To force loading rules regardless of presence of program set to true
	New-Variable -Name ForceLoad -Scope Global -Option Constant -Value $false

	# Project logs folder
	New-Variable -Name LogsFolder -Scope Global -Option Constant -Value "$ProjectRoot\Logs"

	# Firewall logs folder
	# NOTE: Set this value to $LogsFolder\Firewall to enable reading logs in VSCode with syntax highlighting
	# In that case for changes to take effect run Scripts\SetupProfile.ps1 and reboot system
	# NOTE: System default is %SystemRoot%\System32\LogFiles\Firewall
	if ($Develop)
	{
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value $LogsFolder\Firewall
	}
	else
	{
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value "%SystemRoot%\System32\LogFiles\Firewall"
	}
}

# Read only variables, these can be only modified by code at any time, and, only once per session by users.
# Changing these requires powershell restart
if (!(Get-Variable -Name CheckReadOnlyVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setup read only variables"

	# check if read only variables already initialized, do not modify!
	Set-Variable -Name CheckReadOnlyVariables -Scope Global -Option Constant -Force -Value $null

	# Set to false to avoid checking system requirements
	Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value $false

	# Set to false to avoid checking if modules are up to date
	Set-Variable -Name ModulesCheck -Scope Global -Option ReadOnly -Force -Value $Develop

	# Set to false to avoid checking if required system services are started
	Set-Variable -Name ServicesCheck -Scope Global -Option ReadOnly -Force -Value $true

	# NuGet version and Encoding used to write and read files
	# TODO: use $OutputEncoding preference
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		# UTF8 without BOM
		# https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding?view=netcore-3.1
		Set-Variable -Name DefaultEncoding -Scope Global -Option ReadOnly -Force -Value (
			New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false)

		# Required minimum NuGet version prior to installing other modules
		# NOTE: Core >= 3.0.0, Desktop >= 2.8.5
		Set-Variable -Name RequireNuGetVersion -Scope Global -Option ReadOnly -Force -Value ([version]::new(3, 0, 0))
	}
	else
	{
		# TODO: need some workaround to make Windows PowerShell read/write BOM-less
		# UTF8 with BOM
		# https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding?view=powershellsdk-1.1.0
		Set-Variable -Name DefaultEncoding -Scope Global -Option ReadOnly -Force -Value "utf8"

		# NOTE: Setting this variable in Initialize-Project would override it in develop mode
		Set-Variable -Name RequireNuGetVersion -Scope Global -Option ReadOnly -Force -Value ([version]::new(2, 8, 5))
	}

	# These drives will help to have shorter prompt and to be able to jump to them with less typing
	# TODO: Should we use these drives instead of "ProjectRoot" variable?
	# HACK: In some cases there is problem using those drives soon after being created, also running
	# scripts while prompt at drive will cause issues setting location
	# for more info see: https://github.com/dsccommunity/SqlServerDsc/issues/118
	New-PSDrive -Name root -Root $ProjectRoot -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name test -Root "$ProjectRoot\Test" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip4 -Root "$ProjectRoot\Rules\IPv4" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip6 -Root "$ProjectRoot\Rules\IPv6" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name mod -Root "$ProjectRoot\Modules" -Scope Global -PSProvider FileSystem | Out-Null
}

# Removable variables, these can be modified or removed by code at any time, and, only once per session by users
# Changing these requires powershell restart if develop mode is off
if ($Develop -or !(Get-Variable -Name CheckRemovableVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setup removable variables"

	# check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckRemovableVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Set to false to use IPv6 instead of IPv4
	Set-Variable -Name ConnectionIPv4 -Scope Global -Value $true

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

	# User account name for which to search executables in user profile and non standard paths by default
	# Also used for other defaults where standard user account is expected, ex. development as standard user
	# NOTE: Set this value to username for which to create rules by default, if there are multiple
	# users and to affect them all set this value to non existent user
	# TODO: needs testing info messages for this value
	# TODO: We are only assuming about accounts here as a workaround due to often need to modify variable
	Set-Variable -Name DefaultUser -Scope Global -Value (Split-Path -Path (Get-LocalGroupMember -Group Users | Where-Object {
				$_.ObjectClass -EQ "User" -and
				($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
			} | Select-Object -ExpandProperty Name -Last 1) -Leaf)

	# Administrative user account name which will perform unit testing
	Set-Variable -Name TestAdmin -Scope Global -Value (Split-Path -Path (Get-LocalGroupMember -Group Administrators | Where-Object {
				$_.ObjectClass -EQ "User" -and
				($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
			} | Select-Object -ExpandProperty Name -Last 1) -Leaf)

	# Standard user account name which will perform unit testing
	Set-Variable -Name TestUser -Scope Global -Value $DefaultUser
}

# Removable variables, these can be modified or removed by code at any time, and, only once per session by users
# Changing these requires powershell restart
if (!(Get-Variable -Name CheckProtectedVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setup protected variables"

	# check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckProtectedVariables -Scope Global -Option Constant -Force -Value $null

	# Global variable to tell if errors were generated, do not modify!
	# Will not be set if ErrorActionPreference is "SilentlyContinue"
	Set-Variable -Name ErrorStatus -Scope Global -Value $false

	# Global variable to tell if warnings were generated, do not modify!
	# Will not be set if WarningPreference is "SilentlyContinue"
	Set-Variable -Name WarningStatus -Scope Global -Value $false
}

Remove-Module -Name Dynamic.Preference -ErrorAction Ignore

if ($ShowPreference)
{
	# This function needs to run in a sanbox to prevent changing preferences for real
	New-Module -Name Dynamic.Preference -ScriptBlock {
		<#
		.SYNOPSIS
		Show values of preference variables in requested scope

		.DESCRIPTION
		Showing values of preference variables in different scopes is useful
		to troubleshoot problems with preferences or just to confirm preferences are set as expected.

		.PARAMETER Target
		A script which calls this function

		.PARAMETER All
		If specified, shows all variables from this script

		.EXAMPLE
		PS> Show-Preference ModuleName

		.NOTES
		None.
		#>
		function Show-Preference
		{
			[CmdletBinding(PositionalBinding = $false)]
			param(
				[Parameter()]
				[string] $Target = (Get-PSCallStack)[1].Command -replace ".{4}$",

				[Parameter()]
				[switch] $All
			)

			Set-Variable -Name IsValidParent -Scope Local -Value "Scope test"
			Write-Debug -Message "[Dynamic.Preference] DebugPreference before: $DebugPreference" -Debug

			& Get-CallerPreference.ps1 -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
			Write-Debug -Message "[Dynamic.Preference] DebugPreference after: $DebugPreference" -Debug

			$Variables = Get-ChildItem -Path Variable:\*Preference

			if ($All)
			{
				# TODO: This does not catch all the variables from this script
				$Variables += Get-ChildItem -Path Variable:\Log*Event,
				Variable:\*Version,
				"Variable:\Default*",
				Variable:\Test*,
				Variable:\*Folder,
				Variable:\*Check,
				Variable:\*Logging,
				Variable:\Connection*
			}

			$Variables = $Variables.GetEnumerator() | Sort-Object -Property Name
			foreach ($Variable in $Variables)
			{
				Write-Host "[$Target] $($Variable.Name) = $($Variable.Value)" -ForegroundColor Cyan
			}
		}
	} | Import-Module -Scope Global

	if (!$InsideModule)
	{
		Write-Debug -Message "[$SettingsScript] DebugPreference: $DebugPreference" -Debug
		Show-Preference # -All
	}
}

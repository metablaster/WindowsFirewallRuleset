
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Almost every script file and module dot sources this script before doing anything else.
In this file project settings and preferences are set by setting various global variables.
These variables represent:
1. Settings for development
2. Settings for release
3. Settings for firewall deployment
4. Settings for unit testing
5. Settings which apply to multiple use cases

.PARAMETER Cmdlet
PSCmdlet object of the calling script

.PARAMETER TargetHost
Target host or policy store name

.PARAMETER InModule
Script modules must call this script with this parameter

.PARAMETER ShowPreference
If specified, displays preferences and optionally variables in the calling scope.
To be used for debugging purposes

.EXAMPLE
PS> ProjectSettings $PSCmdlet

.EXAMPLE
PS> ProjectSettings -InModule

.EXAMPLE
PS> ProjectSettings -InModule -ShowPreference

.INPUTS
None. You cannot pipe objects to ProjectSettings.ps1

.OUTPUTS
None. ProjectSettings.ps1 does not generate any output

.NOTES
TODO: We could auto include this file with module manifests or dynamic module
NOTE: Make sure not to modify variables commented as "do not modify" or "do not decrement"
TODO: Variable description should be part of variable object
TODO: Some version variables enabled for module initialization are needed in several modules
such as PS edition, PS version etc. and should be always available
TODO: Define OutputType attribute
TODO: Set up try/catch or trap for this script only
TODO: Deploy rules to different PolicyStore on remote host
TODO: Check parameter naming convention
TODO: Remoting using SSH and DCOM\RPC, see Enter-PSSession
HACK: This script become too big and too depending, move non variable code somewhere else
HACK: -Domain parameter would override because script is dot sourced
HACK: Setting PSSessionOption in this script does not affect PSSessionOption in other scopes
NOTE: $PSSessionConfigurationName and $PSSessionOption are handled in Initialize-Connection

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsessionoption

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsession

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSUseDeclaredVarsMoreThanAssignments", "", Justification = "False positive about preference variables")]
[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Script")]
param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Script")]
	[ValidateScript( { $_.GetType().FullName -eq "System.Management.Automation.PSScriptCmdlet" })]
	[System.Management.Automation.PSCmdlet]	$Cmdlet,

	[Parameter(ParameterSetName = "Script")]
	[Alias("ComputerName", "CN", "Domain", "PolicyStore")]
	[string] $TargetHost,

	[Parameter(Mandatory = $true, ParameterSetName = "Module")]
	[ValidateScript( { $_ -eq $true } )]
	[switch] $InModule,

	[Parameter()]
	[switch] $ListPreference
)

# Name of this script for debugging messages, do not modify!
Set-Variable -Name SettingsScript -Scope Private -Option ReadOnly -Force -Value ((Get-Item $PSCommandPath).Basename)

# Replace localhost and dot with NETBIOS computer name
if (($TargetHost -eq "localhost") -or ($TargetHost -eq "."))
{
	$TargetHost = [System.Environment]::MachineName
}

#region Preference variables
Write-Debug -Message "[$SettingsScript] Setting up preference variables"

<# Preference Variables default values (Core / Desktop)
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

if ($PSCmdlet.ParameterSetName -eq "Module")
{
	# TODO: If a script uses this parameter, it's bound common parameters wont work as expected
	# Modifying these preferences applies to all module scopes, only common parameters bound to
	# module functions and preferences set in module scope can override preference variables set here.

	# NOTE: The following preferences should be always the same, do not modify!
	$ErrorActionPreference = "Continue"
	$WarningPreference = "Continue"
	$InformationPreference = "Continue"
	$ProgressPreference	= "Continue"

	# Optionall override to debug modules globally
	# ISSUE: Verbose and Debug isn't applied to Invoke-Command ScriptBlock
	# https://github.com/PowerShell/PowerShell/issues/4040
	$VerbosePreference = "SilentlyContinue"
	$DebugPreference = "SilentlyContinue"
	$ConfirmPreference = "High"
	$WhatIfPreference = $false
}
else
{
	# Modifying these preferences applies to all scopes except to module scopes, common parameters
	# bound to scripts and functions are respected, locally set preferences will override these.
	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("ErrorAction"))
	{
		# To control if errors are displayed by default
		$ErrorActionPreference = "Continue"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("WarningAction"))
	{
		# To control if warnings are displayed by default
		$WarningPreference = "Continue"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("InformationAction"))
	{
		# To control if informational messages are displayed by default
		$InformationPreference = "Continue"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose"))
	{
		# To show verbose messages by default in the console set to "Continue"
		$VerbosePreference = "SilentlyContinue"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("Debug"))
	{
		# To show debugging messages by default in the console set to "Continue"
		$DebugPreference = "SilentlyContinue"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("Confirm"))
	{
		# If $ConfirmPreference value is less than or equal to the risk assigned to function.
		# To control confirmation level set to:
		# None, never prompt
		# Low, prompt for low, medium and high impact actions
		# Medium, prompt for medium and high impact actions
		# High, prompt for high impact actions only
		$ConfirmPreference = "High"
	}

	if (!$Cmdlet.MyInvocation.BoundParameters.ContainsKey("WhatIf"))
	{
		# HACK: Run with true, and resolve errors
		# To prompt for confirmation before any function is run set to true
		$WhatIfPreference = $false
	}
}

# Determines how PowerShell responds to progress bar updates generated by the Write-Progress cmdlet
$ProgressPreference = "Continue"

# To control if modules automatically load, do not modify!
# Values: All, ModuleQualified or None
$PSModuleAutoLoadingPreference = "All"

# The $PSSessionApplicationName preference variable is set on the local computer,
# but it specifies a listener on the remote computer.
# The system default application name is wsman
$PSSessionApplicationName = "wsman"

# The Output Field Separator (OFS) specifies the character that separates the elements of an array
# that is converted to a string.
# We declare it to avoid warning in Get-CallerPreference
$OFS = " "

# Set to true to enable development features, it does the following at a minimum:
# 1. Forces reloading modules and removable variables.
# 2. Loads troubleshooting rules defined in Temporary.ps1
# 3. Performs additional requirements checks needed or recommended for development
# 4. Enables some disabled unit tests and disables logging
# 5. Enables setting preference variables for modules
# NOTE: If changed to $true, change requires PowerShell restart
Set-Variable -Name Develop -Scope Global -Value $false

if ($Develop)
{
	if ($PSVersionTable.PSEdition -eq "Desktop")
	{
		# Global because of known issue: https://github.com/PowerShell/PowerShell/issues/3645
		# Set-Variable -Name ErrorView -Scope Global -Value "CategoryView"
	}

	# Two variables for each of the three logging components:
	# The engine (the PowerShell program), the providers and the commands.
	# The LifeCycleEvent variables log normal starting and stopping events.
	# The Health variables log error events.
	# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_eventlogs?view=powershell-5.1#selecting-events-for-the-windows-powershell-event-log

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
}
#endregion

#region Initialization
# Calling script name, to be used for Write-* operations
if ($PSCmdlet.ParameterSetName -eq "Module")
{
	New-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ((Split-Path -Path (Get-PSCallStack)[1].ScriptName -Leaf) -replace "\.\w{2,3}1$")
	Write-Debug -Message "[$SettingsScript] Caller = $ThisModule ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
}
else
{
	# Not constant because of scripts which dot source format files more than once per session, and for unit testing
	New-Variable -Name ThisScript -Scope Private -Option ReadOnly -Force -Value ($Cmdlet.MyInvocation.MyCommand -replace "\.\w{2,3}1$")
	Write-Debug -Message "[$SettingsScript] Caller = $ThisScript ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
}

if ($MyInvocation.InvocationName -ne ".")
{
	Write-Error -Category InvalidOperation -TargetObject $SettingsScript `
		-Message "$SettingsScript script must be dot sourced"
}

if ($Develop)
{
	# The Set-PSDebug cmdlet turns script debugging features on and off, sets the trace level, and toggles strict mode.
	# Strict: Turns on strict mode for the global scope, this is equivalent to Set-StrictMode -Version 1
	# Trace 0: Turn script tracing off.
	# Trace 1: each line of script is traced as it runs.
	# Trace 2: variable assignments, function calls, and script calls are also traced.
	# Step: You're prompted before each line of the script runs.
	Set-PSDebug -Strict -Trace 0
}

# Overrides version set by Set-PSDebug
# The Set-StrictMode configures strict mode for the current scope and all child scopes
# Use it in a script or function to override the setting inherited from the global scope.
# NOTE: Set-StrictMode is effective only in the scope in which it is set and in its child scopes
Set-StrictMode -Version Latest

# Path variables, these can be modified if definition allows
if (!(Get-Variable -Name PathVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up path variables"

	# Check if removable variables already initialized, do not modify!
	New-Variable -Name PathVariables -Scope Global -Option Constant -Value $null

	# Repository root directory, reallocating scripts should be easy if root directory is constant
	New-Variable -Name ProjectRoot -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)

	# Used by Start-Transcript to specify the name and location of the transcript file.
	# TODO: This should be declared in preferences section but we need $ProjectRoot
	# Declared to avoid warning in Get-CallerPreference
	# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables
	$Transcript = "$ProjectRoot\Logs\PowerShell_transcript_$(Get-Date -Format "dd.MM.yy").txt"

	# These drives will help to have shorter prompt and to be able to jump to them with less typing
	# TODO: Should we use these drives instead of "ProjectRoot" variable?
	# HACK: In some cases there is problem using those drives soon after being created, also running
	# scripts while prompt is at drive will cause issues setting location
	# for more info see: https://github.com/dsccommunity/SqlServerDsc/issues/118
	New-PSDrive -Name root -Root $ProjectRoot -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip4 -Root "$ProjectRoot\Rules\IPv4" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip6 -Root "$ProjectRoot\Rules\IPv6" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name mod -Root "$ProjectRoot\Modules" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name test -Root "$ProjectRoot\Test" -Scope Global -PSProvider FileSystem | Out-Null

	# Add project module directory to session module path
	# TODO: We can avoid using Import-Module in this script since this is executed earlier
	New-Variable -Name PathEntry -Scope Private -Value (
		[System.Environment]::GetEnvironmentVariable("PSModulePath").TrimEnd(";") -replace (";;", ";"))

	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Modules"
	[System.Environment]::SetEnvironmentVariable("PSModulePath", $PathEntry)

	# Add project script directory to session script path
	$PathEntry = [System.Environment]::GetEnvironmentVariable("Path").TrimEnd(";") -replace (";;", ";")
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts"
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\Experiment"
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\Security"
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\Utility"
	[System.Environment]::SetEnvironmentVariable("Path", $PathEntry)

	Remove-Variable -Name PathEntry -Scope Private

	# Load format data into session
	Get-ChildItem -Path "$ProjectRoot\Scripts" -Filter *.ps1xml -Recurse | ForEach-Object {
		Update-FormatData -AppendPath $_.FullName
	}
}

if ($Develop -and !$InModule)
{
	# Remove loaded modules, useful for module debugging and to avoid restarting powershell every time.
	# Skip removing modules if this script is called from within a module which would cause removing modules prematurely
	Get-Module -Name Ruleset.* | ForEach-Object {
		Write-Debug -Message "[$SettingsScript] Removing module $_"
		Remove-Module -Name $_ -Force -ErrorAction Stop
	}
}
#endregion

#region Remote session initialization
# Remoting variables, these can be modified if definition allows
if (!(Get-Variable -Name CheckRemotingVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up remoting variables"

	# Check if removable variables already initialized, do not modify!
	New-Variable -Name CheckRemotingVariables -Scope Global -Option Constant -Value $null

	# Valid policy stores
	New-Variable -Name LocalStore -Scope Global -Option Constant -Value @(
		"."
		"localhost"
		([System.Environment]::MachineName)
		"PersistentStore"
		"ActiveStore"
		"RSOP"
		"SystemDefaults"
		"StaticServiceStore"
		"ConfigurableServiceStore"
	)

	# Specify protocol for WinRM configuration and remote deployment, acceptable values are HTTP, HTTPS or Default
	# A value "Default" for remoting means, use HTTPS for remote deployment and if not working fallback to HTTP
	# for local deployment "Default" means use HTTP
	# NOTE: For localhost sessions only HTTP is supported and this setting is ignored for localhost
	# The default value is "Default"
	New-Variable -Name RemotingProtocol -Scope Global -Option Constant -Value "Default"

	# If there are multiple SSL certificates with same CN entries to use for remote host specify
	# certificate thumbprint which to use for HTTPS
	New-Variable -Name SslThumbprint -Scope Global -Option Constant -Value $null

	# Specifies the authentication mechanism to be used at the server.
	# The acceptable values for this parameter are:
	# None, no authentication is performed, request is anonymous.
	# Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
	# Default, use the authentication method implemented by the WS-Management protocol.
	# Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
	# Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
	# Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
	# CredSSP, use Credential Security Support Provider (CredSSP) authentication.
	# NOTE: If you specify an option other than "Default" you also need to ensure the corresponding
	# WinRM authentication is enabled in Modules\Ruleset.Remote\Scripts\WinRMSettings.ps1 -> $AuthenticationOptions
	# NOTE: To use CredSSP it needs to be enabled in GPO or by Enable-WSManCredSSP for both the
	# client and server computers
	# The default value is "Default"
	New-Variable -Name RemotingAuthentication -Scope Global -Option ReadOnly -Value "Default"

	# Authentication options which require credentails, do not modify!
	New-Variable -Name AuthRequiresCredentials -Scope Global -Option Constant -Value @(
		"Basic"
		"CredSSP"
		"Negotiate"
	)

	# Credential object to be used for authentication to remote computer
	New-Variable -Name RemotingCredential -Scope Global -Option ReadOnly -Value $null

	# CIM session holder which is to be used for commands accepting CIM sessions
	New-Variable -Name CimServer -Scope Global -Option ReadOnly -Value $null

	# PS session holder which is to be used for commands accepting PS sessions
	New-Variable -Name SessionInstance -Scope Global -Option ReadOnly -Value $null
}

if ($PSCmdlet.ParameterSetName -eq "Script")
{
	if (Get-Variable -Name PolicyStore -Scope Global -ErrorAction Ignore)
	{
		if ($TargetHost -and ($TargetHost -ne $PolicyStore))
		{
			# TODO: This will invoke module load before calling Initialize-Project
			Disconnect-Computer -Domain $PolicyStore
		}
	}

	# Target machine onto which to deploy firewall (default: Local Group Policy)
	if ([string]::IsNullOrEmpty($TargetHost) -or ($TargetHost -eq [System.Environment]::MachineName))
	{
		Set-Variable -Name PolicyStore -Scope Global -Option ReadOnly -Force -Value ([System.Environment]::MachineName)
	}
	else
	{
		Set-Variable -Name PolicyStore -Scope Global -Option ReadOnly -Force -Value $TargetHost
	}
}
#endregion

#region Removable variables, these can be modified as follows:
# 1. By code at any time
# 2. Only once by user before running any scripts from repository
# 3. Any amount of time by user if "develop" mode is ON
# In all other cases changing variable values requires PowerShell restart
if ($Develop -or !(Get-Variable -Name CheckRemovableVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up removable variables"

	# Check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckRemovableVariables -Scope Global -Option ReadOnly -Force -Value $null

	# Set to false to disable logging errors
	Set-Variable -Name ErrorLogging -Scope Global -Value $true

	# Set to false to disable logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value $true

	# Set to false to disable logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value $true

	# Set to true to disable digital signature verification of executables involved in rules
	Set-Variable -Name SkipSignatureCheck -Scope Global -Value $false

	# Set to true to disable VirusTotal check of executables without valid digital signature
	Set-Variable -Name SkipVirusTotalCheck -Scope Global -Value $false

	# Specify path to sigcheck64.exe if your instance of sigcheck executable isn't in PATH
	# If digital signature check of a program for which firewall rule is being loaded fails, then
	# sigcheck64.exe is used to perform hash based online malware analysis via VirusTotal service.
	# You can get sigcheck64.exe from Microsoft sysinternals site below:
	# https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck
	Set-Variable -Name SigcheckPath -Scope Global -Value "C:\tools"
}
#endregion

#region Conditional preference variables
# Value of these preference variables depend on existing logging variables, do not modify!
if (!$InModule)
{
	Write-Debug -Message "[$SettingsScript] Setting conditional preference variables"

	# NOTE: Not using these parameters inside modules because they will be passed to module functions
	# by top level advanced function in call stack which will pick up all Write-* streams in module functions
	# NOTE: For functions outside module we need to declare PSDefaultParameterValues as private
	# which will hide visibility of PSDefaultParameterValues to functions in child scopes.
	# Advanced functions in child scopes and modules will receive these parameters by the caller,
	# this is needed to avoid duplicate log entries.
	# ISSUE: This won't work with PS extension because scripts aren't meant to be dotsourced
	# see: https://github.com/PowerShell/vscode-powershell/issues/4327
	$private:PSDefaultParameterValues = @{}

	if ($ErrorLogging)
	{
		$private:PSDefaultParameterValues.Add("*:ErrorVariable", "+ErrorBuffer")
	}

	if ($WarningLogging)
	{
		$private:PSDefaultParameterValues.Add("*:WarningVariable", "+WarningBuffer")
	}

	if ($InformationLogging)
	{
		$private:PSDefaultParameterValues.Add("*:InformationVariable", "+InfoBuffer")
	}
}
#endregion

#region Read only variables, these can be modified as follows:
# 1. By code at any time
# 2. Only once by user before running any scripts from repository
# In all other cases changing variable values requires PowerShell restart
if (!(Get-Variable -Name CheckReadOnlyVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up read only variables"

	# check if read only variables already initialized, do not modify!
	New-Variable -Name CheckReadOnlyVariables -Scope Global -Option Constant -Value $null

	# Set to false to avoid checking system and environment requirements
	# This will also disable checking for modules and required services
	New-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Value $true

	# Set to false to avoid checking if modules are up to date
	# Enabling this make sense only for development or code navigation
	New-Variable -Name ModulesCheck -Scope Global -Option ReadOnly -Value $Develop

	# Set to false to avoid checking if required system services are started
	New-Variable -Name ServicesCheck -Scope Global -Option ReadOnly -Value $true
}
#endregion

#region Read only variables 2, these can be modified as follows:
# 1. Never by code
# 2. Only once by user before running any scripts from repository
# 3. Any amount of time by user if "develop" mode is ON
# In all other cases changing variable values requires PowerShell restart
if ($Develop -or !(Get-Variable -Name CheckReadOnlyVariables2 -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up read only variables - user only"

	# Check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckReadOnlyVariables2 -Scope Global -Option ReadOnly -Force -Value $null

	# Specify one or more user groups for which rules are being created by default
	# NOTE: By design, for security reasons rules are created for all users in "Users" group while
	# for Administrators group only those rules which necessary require Administrators online access.
	# If there are no standard users you should set this to "Administrators" or some other group
	# which represents non administrative users on target computer.
	# The default value is "Users"
	# TODO: A good portion of code handles only first group mentioned
	Set-Variable -Name DefaultGroup -Scope Global -Option ReadOnly -Force -Value @(
		# Add or remove groups as needed
		"Users"
	)

	if ($PSCmdlet.ParameterSetName -eq "Script")
	{
		# Windows 10, Windows Server 2019 and above
		Set-Variable -Name Platform -Scope Global -Option ReadOnly -Force -Value "10.0+"

		# Default network interface card to use if not locally specified
		# TODO: We can learn this value programatically, but problem is the same as with specifying local IP
		Set-Variable -Name DefaultInterface -Scope Global -Option ReadOnly -Force -Value @(
			# Accepted values: Any, Wired, Wireless, RemoteAccess
			"Wired"
			"Wireless"
		)

		# Default network profile to use for rules if not locally specified.
		# NOTE: Do not modify except to to debug rules or unless absolutely needed!
		Set-Variable -Name DefaultProfile -Scope Global -Option ReadOnly -Force -Value @(
			# Accepted values: Any, Domain, Private, Public, NotApplicable
			"Private"
			"Public"
		)

		# To force loading rules regardless of presence of an executable or service set to true
		# The purpose of this is to test loading rules that would otherwise be skipped
		# TODO: Some rules are not affected by this setting and will be skipped
		Set-Variable -Name ForceLoad -Scope Global -Option ReadOnly -Force -Value $false

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# Set to false to use IPv6 instead of IPv4 to test connection to target policy store
			# NOTE: Requests for Comments (RFCs) 1001 and 1002 define NetBIOS operation over IPv4.
			# NetBT is not defined for IPv6.
			Set-Variable -Name ConnectionIPv4 -Scope Global -Option ReadOnly -Force -Value $true
		}

		try
		{
			# User account name for which to search executables in user profile and non standard paths by default
			# Also used for other defaults where standard user account is expected, ex. development as standard user
			# NOTE: If there are multiple users and to affect them all set this value to non existent user
			# TODO: Needs testing info messages for this value
			# TODO: We are only assuming about accounts here as a workaround due to often need to modify variable
			# TODO: This should be used for -LocalUser rule parameter too
			# TODO: This should also be all users from default group because some rules use it
			Set-Variable -Name DefaultUser -Scope Global -Option ReadOnly -Force -Value (
				Split-Path -Path (Get-LocalGroupMember -Group $DefaultGroup[0] | Where-Object {
						($_.ObjectClass -EQ "User") -and
					(($_.PrincipalSource -eq "Local") -or ($_.PrincipalSource -eq "MicrosoftAccount"))
					} | Select-Object -ExpandProperty Name -Last 1) -Leaf)
		}
		catch
		{
			Set-Variable -Name DefaultUser -Scope Global -Option ReadOnly -Force -Value "UnknownUser"
			Write-Warning -Message "[$SettingsScript] No users exists in $($DefaultGroup[0]) group"
		}

		# Administrative user account name which will perform unit testing
		if ($PolicyStore -ne [System.Environment]::MachineName)
		{
			Set-Variable -Name TestAdmin -Scope Global -Option ReadOnly -Force -Value "Admin"
		}
		else
		{
			# TODO: This may select inactive admin account, ex Administrator
			Set-Variable -Name TestAdmin -Scope Global -Option ReadOnly -Force -Value (
				Split-Path -Path (Get-LocalGroupMember -Group Administrators | Where-Object {
						($_.ObjectClass -EQ "User") -and
						(($_.PrincipalSource -eq "Local") -or ($_.PrincipalSource -eq "MicrosoftAccount"))
					} | Select-Object -ExpandProperty Name -Last 1) -Leaf)
		}

		# Standard user account name which will perform unit testing
		if ($PolicyStore -ne [System.Environment]::MachineName)
		{
			Set-Variable -Name TestUser -Scope Global -Option ReadOnly -Force -Value "User"
		}
		else
		{
			Set-Variable -Name TestUser -Scope Global -Option ReadOnly -Force -Value $DefaultUser
		}

		# Remote test computer which will perform unit testing
		Set-Variable -Name TestDomain -Scope Global -Option ReadOnly -Force -Value "VM-PRO"
	}
}
#endregion

#region Constant variables, these can be modified as follows:
# 1. Never by code
# 2. Only once by user before running any scripts from repository
# In all other cases changing variable values requires PowerShell restart
if (!(Get-Variable -Name CheckConstantVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up constant variables"

	# Check if constants already initialized, used for module reloading, do not modify!
	New-Variable -Name CheckConstantVariables -Scope Global -Option Constant -Value $null

	# There is a bug in Windows PowerShell which doesn't recognize -ErrorAction Ignore properly
	# for advanced functions (not commandlets), to get around this bug we conditionally define
	# Ignore and use it everywhere where Windows PS errors about this.
	# This issue has been resolved for PS Core but Windows PowerShell is stuck since it isn't updated.
	# ISSUE: https://github.com/PowerShell/PowerShell/issues/4348
	if ($PSVersionTable.PSEdition -eq "Core")
	{
		New-Variable -Name PSCompatibleIgnore -Scope Global -Option Constant -Value "Ignore"
	}
	else
	{
		New-Variable -Name PSCompatibleIgnore -Scope Global -Option Constant -Value "SilentlyContinue"
	}

	# Default remote registry permissions are:
	# MSDN: Security checks are not performed when accessing subkeys or values
	# A security check is performed when trying to open the current key
	# NOTE: Specific scripts override this permission as needed locally
	New-Variable -Name RegistryPermission -Scope Global -Option Constant -Value (
		[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree)

	# Default remote registry permissions are:
	# MSDN: The right to list the subkeys of a registry key
	# The right to query the name/value pairs in a registry key
	# NOTE: Specific scripts add or remove rights as needed locally
	New-Variable -Name RegistryRights -Scope Global -Option Constant -Value (
		[System.Security.AccessControl.RegistryRights] "EnumerateSubKeys, QueryValues")

	# Default registry view:
	# MSDN: On the 64-bit versions of Windows, portions of the registry are stored separately
	# for 32-bit and 64-bit applications.
	# There is a 32-bit view for 32-bit applications and a 64-bit view for 64-bit applications.
	# If view is Registry64 but the remote machine is running a 32-bit operating system,
	# the returned key will use the Registry32 view.
	# NOTE: Specific scripts may modify this to Registry32 locally, in order to access 32 bit values
	New-Variable -Name RegistryView -Scope Global -Option Constant -Value (
		[Microsoft.Win32.RegistryView]::Registry64)

	# Project version, does not apply to non migrated 3rd party modules which follow their own version increment, do not modify!
	New-Variable -Name ProjectVersion -Scope Global -Option Constant -Value ([version]::new(0, 15, 0))

	# Required minimum operating system version (v1809)
	# TODO: v1809 needs to be replaced with minimum v1903, downgraded here because of Server 2019
	# https://docs.microsoft.com/en-us/windows/release-information
	# https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
	New-Variable -Name RequireWindowsVersion -Scope Global -Option Constant -Value ([version]::new(10, 0, 17763))

	# Project logs folder
	New-Variable -Name LogsFolder -Scope Global -Option Constant -Value "$ProjectRoot\Logs"

	if ($PSVersionTable.PSEdition -eq "Core")
	{
		# Encoding used to write and read files, UTF8 without BOM
		# https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding?view=netcore-3.1
		# TODO: Beginning with PowerShell 6.2, the Encoding parameter also allows numeric IDs of registered
		# code pages (like -Encoding 1251) or string names of registered code pages (like -Encoding "windows-1251")
		Set-Variable -Name DefaultEncoding -Scope Global -Option Constant -Value (
			New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false)

		# Recommended minimum PowerShell Core
		# NOTE: 6.1.0 will not work, but 7.0.3 works, verify with PSUseCompatibleCmdlets
		New-Variable -Name RequirePSVersion -Scope Global -Option Constant -Value ([version]::new(7, 3, 2))
	}
	else
	{
		# Encoding used to write and read files, UTF8 with BOM
		# https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding?view=powershellsdk-1.1.0
		# NOTE: System.Text.UTF8Encoding can't be used here because of ValidateSet which expected string
		# TODO: need some workaround to make Windows PowerShell read/write BOM-less
		Set-Variable -Name DefaultEncoding -Scope Global -Option Constant -Value "utf8"

		# Required minimum Windows PowerShell, do not decrement!
		# NOTE: 5.1.14393.206 (system v1607) will not work, but 5.1.19041.1 (system v2004) works, verify with PSUseCompatibleCmdlets
		# NOTE: replacing build 19041 (system v2004) with 17763 (system v1809) which is minimum required for rules and .NET
		New-Variable -Name RequirePSVersion -Scope Global -Option Constant -Value ([version]::new(5, 1, 17763))
	}

	if ($ProjectCheck -and $ModulesCheck)
	{
		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# Required minimum NuGet version prior to installing other modules
			# NOTE: Core >= 3.0.0, Desktop >= 2.8.5
			New-Variable -Name RequireNuGetVersion -Scope Global -Option Constant -Value ([version]::new(3, 0, 0))
		}
		else
		{
			# NOTE: Setting this variable in Initialize-Project would override it in develop mode
			New-Variable -Name RequireNuGetVersion -Scope Global -Option Constant -Value ([version]::new(2, 8, 5))
		}

		# Required minimum PSScriptAnalyzer version for code editing, do not decrement!
		# PSScriptAnalyzer >= 1.19.1 is minimum required otherwise code will start missing while editing probably due to analyzer settings
		# https://github.com/PowerShell/PSScriptAnalyzer#requirements
		New-Variable -Name RequireAnalyzerVersion -Scope Global -Option Constant -Value ([version]::new(1, 21, 0))

		# Recommended minimum posh-git version for git in PowerShell
		# NOTE: pre-release minimum 1.0.0-beta4 will be installed
		New-Variable -Name RequirePoshGitVersion -Scope Global -Option Constant -Value ([version]::new(1, 1, 0))

		# Recommended minimum Pester version for code testing
		# NOTE: PScriptAnalyzer 1.19.1 requires pester v5
		# TODO: we need pester v4 for tests, but why does analyzer require pester?
		New-Variable -Name RequirePesterVersion -Scope Global -Option Constant -Value ([version]::new(5, 4, 0))

		# Required minimum PackageManagement version prior to installing other modules, do not decrement!
		New-Variable -Name RequirePackageManagementVersion -Scope Global -Option Constant -Value ([version]::new(1, 4, 7))

		# Required minimum PowerShellGet version prior to installing other modules, do not decrement!
		# https://www.powershellgallery.com/packages/PowerShellGet
		New-Variable -Name RequirePowerShellGetVersion -Scope Global -Option Constant -Value ([version]::new(2, 2, 5))

		# Recommended minimum platyPS version used to generate online help files for modules, do not decrement!
		New-Variable -Name RequirePlatyPSVersion -Scope Global -Option Constant -Value ([version]::new(0, 14, 2))

		# Recommended minimum PSReadline version for command line editing experience of PowerShell
		# Needs the 1.6.0 or a higher version of PowerShellGet to install the latest prerelease version of PSReadLine
		New-Variable -Name RequirePSReadlineVersion -Scope Global -Option Constant -Value ([version]::new(2, 2, 6))
	}

	if ($Develop -or ($ProjectCheck -and $ModulesCheck))
	{
		# Recommended minimum Git version needed for contributing and required by posh-git
		# https://github.com/dahlbyk/posh-git#prerequisites
		New-Variable -Name RequireGitVersion -Scope Global -Option Constant -Value ([version]::new(2, 39, 0))
	}

	if ($Develop)
	{
		# Required minimum .NET version, valid for the PowerShell Desktop edition only, do not decrement!
		# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies
		# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
		# https://docs.microsoft.com/en-us/dotnet/framework/get-started/system-requirements
		# https://stackoverflow.com/questions/63520845/determine-net-and-clr-requirements-for-your-powershell-modules/63547710
		# https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/windows-powershell-system-requirements?view=powershell-7.1
		# NOTE: v1703 includes .NET 4.7
		# NOTE: v1903-v2004 includes .NET 4.8
		# NOTE: Maximum allowed value to specify in manifest is 4.5
		New-Variable -Name RequireNETVersion -Scope Global -Option Constant -Value ([version]::new(4, 5, 0))

		# Recommended minimum VSCode version, do not decrement!
		New-Variable -Name RequireVSCodeVersion -Scope Global -Option Constant -Value ([version]::new(1, 74, 3))

		# Firewall logs folder
		# NOTE: Set this value to $LogsFolder\Firewall to enable reading logs in VSCode with syntax highlighting
		# In that case for changes to take effect run Scripts\Complete-Firewall.ps1 and either restart firewall or reboot system.
		# Then run Scripts\Grant-Logs -User USERNAME_WHICH_WILL_READ_LOGS
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value $LogsFolder\Firewall
	}
	else
	{
		# Firewall logs folder
		# NOTE: System default is %SystemRoot%\System32\LogFiles\Firewall
		# TODO: Modifying this variable is currently not implemented, for custom log location use Develop version above
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value "%SystemRoot%\System32\LogFiles\Firewall"
	}

	# Default output location for unit tests that produce file system output
	New-Variable -Name DefaultTestDrive -Scope Global -Option Constant -Value $ProjectRoot\Test\TestDrive

	# Controls the language that should be used for UI elements and end-user messages, such as error messages.
	New-Variable -Name DefaultUICulture -Scope Global -Option Constant -Value (
		[System.Globalization.CultureInfo]::new("en-US", $false)
	)

	# Controls the formats used to represent numbers, currency values, and date/time values
	New-Variable -Name DefaultCulture -Scope Global -Option Constant -Value (
		[System.Globalization.CultureInfo]::new("en-US", $false)
	)
}
#endregion

#region Protected variables, these can be modified as follows:
# 1. By code at any time
# 2. Never by user
if (!(Get-Variable -Name CheckProtectedVariables -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up protected variables"

	# check if removable variables already initialized, do not modify!
	New-Variable -Name CheckProtectedVariables -Scope Global -Option Constant -Value $null

	# Global variable to tell if errors were generated, do not modify!
	# Will not be set if ErrorActionPreference is "SilentlyContinue"
	New-Variable -Name ErrorStatus -Scope Global -Value $false

	# Global variable to tell if warnings were generated, do not modify!
	# Will not be set if WarningPreference is "SilentlyContinue"
	New-Variable -Name WarningStatus -Scope Global -Value $false

	# Global variable to tell if target GPO should be updated for changes, do not modify!
	# Will be disabled by Deploy-Firewall.ps1 to run GPO update only once when deployment is done.
	New-Variable -Name UpdateGPO -Scope Global -Value $true
}
#endregion

# Module autoload is triggered for functions only, not for variable exports
if (!$InModule)
{
	# TODO: Need to see if any other modules need to be preloaded here in the future
	Import-Module -Scope Global -Name Ruleset.Logging
}

#region Show variables and preferences
if ($ListPreference)
{
	# This function needs to run in a sanbox to prevent changing preferences for real
	New-Module -Name Dynamic.Preference -ScriptBlock {
		<#
		.SYNOPSIS
		Show values of preference variables in requested scope

		.DESCRIPTION
		Showing values of preference variables in different scopes is useful to troubleshoot
		problems with preferences or just to confirm preferences or variables are set as expected.

		.PARAMETER Name
		Also shows variable of specified name

		.PARAMETER All
		If specified, shows all variables from this script including Path and PSModulePath values

		.PARAMETER SessionOption
		Also shows PSSessionOption values

		.EXAMPLE
		PS> Show-Preference ModuleName

		.NOTES
		None.
		#>
		function Show-Preference
		{
			param (
				[Parameter()]
				[switch] $Name,

				[Parameter()]
				[switch] $All,

				[Parameter()]
				[switch] $SessionOption
			)

			# Get base name of script that called this function
			$Caller = (Split-Path -Path $MyInvocation.ScriptName -Leaf) -replace "\.\w{2,3}1$"

			if ($Caller -eq "ProjectSettings")
			{
				# Get base name of script that dot sourced ProjectSettings.ps1
				$Caller = (Split-Path -Path (Get-PSCallStack)[2].Command -Leaf) -replace "\.\w{2,3}1$"
			}

			Set-Variable -Name IsValidParent -Scope Local -Value "Scope test"
			Write-Debug -Message "[Show-Preference] InformationPreference before Get-CallerPreference is '$InformationPreference'"

			& Get-CallerPreference.ps1 -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
			Write-Debug -Message "[Show-Preference] InformationPreference after Get-CallerPreference is '$InformationPreference'"

			$Variables = Get-ChildItem -Path Variable:\*Preference
			$Variables += Get-ChildItem -Path Variable:\PSSessionApplicationName
			$Variables += Get-ChildItem -Path Variable:\PSSessionConfigurationName

			# NOTE: Sorting before -All and -Name to have preference variables listed first
			$AllVariables = $Variables.GetEnumerator() | Sort-Object -Property Name

			if ($Name)
			{
				# Optionally add requested variables to the list
				$AllVariables += Get-ChildItem -Path Variable:\$Name
			}

			if ($All)
			{
				# TODO: This does not catch all of the variables from this script
				$Variables = Get-ChildItem -Path Variable:\Log*Event,
				Variable:\*Version,
				"Variable:\Default*",
				Variable:\Test*,
				Variable:\*Folder,
				Variable:\*Check,
				Variable:\*Logging,
				Variable:\Connection*

				$Variables += Get-ChildItem -Path Variable:\ProjectRoot
				$Variables += Get-ChildItem -Path Variable:\PolicyStore
				$Variables += Get-ChildItem -Path Variable:\Platform
				$Variables += Get-ChildItem -Path Variable:\ForceLoad
				$Variables += Get-ChildItem -Path Variable:\ErrorStatus
				$Variables += Get-ChildItem -Path Variable:\WarningStatus

				$AllVariables += $Variables.GetEnumerator() | Sort-Object -Property Name
			}

			foreach ($Variable in $AllVariables)
			{
				Write-ColorMessage "[$Caller] $($Variable.Name) = $($Variable.Value)" Cyan
			}

			if ($All)
			{
				$DriveEntry = Get-PSDrive -PSProvider FileSystem -Name root, mod, ip4, ip6, test |
				Select-Object -Property Name, Root

				foreach ($Entry in $DriveEntry)
				{
					Write-ColorMessage "[$Caller] $($Entry.Name):\ = $($Entry.Root)" Cyan
				}

				foreach ($Entry in @($env:PSModulePath.Split(";")))
				{
					Write-ColorMessage "[$Caller] ModulePath = $Entry" Cyan
				}

				foreach ($Entry in @($env:Path.Split(";")))
				{
					Write-ColorMessage "[$Caller] Path = $Entry" Cyan
				}
			}

			if ($SessionOption)
			{
				# HACK: Find better way to enumerate PSSessionOption and use foreach
				$Option = (Get-ChildItem -Path Variable:\PSSessionOption).Value
				Write-ColorMessage "[$Caller.PSSessionOption.MaximumConnectionRedirectionCount] $($Option.MaximumConnectionRedirectionCount)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.NoCompression] $($Option.NoCompression)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.NoMachineProfile] $($Option.NoMachineProfile)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.ProxyAccessType] $($Option.ProxyAccessType)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.ProxyAuthentication] $($Option.ProxyAuthentication)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.ProxyCredential] $($Option.ProxyCredential)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.SkipCACheck] $($Option.SkipCACheck)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.SkipCNCheck] $($Option.SkipCNCheck)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.SkipRevocationCheck] $($Option.SkipRevocationCheck)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.OperationTimeout] $($Option.OperationTimeout)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.NoEncryption] $($Option.NoEncryption)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.UseUTF16] $($Option.UseUTF16)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.IncludePortInSPN] $($Option.IncludePortInSPN)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.OutputBufferingMode] $($Option.OutputBufferingMode)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.MaxConnectionRetryCount] $($Option.MaxConnectionRetryCount)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.Culture] $($Option.Culture)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.UICulture] $($Option.UICulture)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.MaximumReceivedDataSizePerCommand] $($Option.MaximumReceivedDataSizePerCommand)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.MaximumReceivedObjectSize] $($Option.MaximumReceivedObjectSize)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.ApplicationArguments] $($Option.ApplicationArguments)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.OpenTimeout] $($Option.OpenTimeout)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.CancelTimeout] $($Option.CancelTimeout)" Cyan
				Write-ColorMessage "[$Caller.PSSessionOption.IdleTimeout] $($Option.IdleTimeout)" Cyan
			}
		}
	} | Import-Module -Scope Global

	if (!$InModule)
	{
		# NOTE: Scripts which dot source this one are same scope thus Show-Preference pulls both
		Write-Debug -Message "[$SettingsScript] InformationPreference is '$InformationPreference'"
		Show-Preference # -All
		Remove-Module -Name Dynamic.Preference
	}
}
#endregion

if (!$InModule)
{
	# Calling script parameter status info
	Write-Debug -Message "[$ThisScript] ParameterSet = $($Cmdlet.ParameterSetName):$($Cmdlet.MyInvocation.BoundParameters | Out-String)"
}

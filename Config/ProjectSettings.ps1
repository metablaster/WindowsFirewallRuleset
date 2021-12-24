
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
almost every script file and module dot sources this script before doing anything else.
In this file project settings and preferences are set, these are grouped into
1. settings for development
2. settings for release
3. settings which apply to both use cases

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
PS> .\ProjectSettings.ps1 $PSCmdlet

.EXAMPLE
PS> .\ProjectSettings.ps1 -InModule

.EXAMPLE
PS> .\ProjectSettings.ps1 -InModule -ShowPreference

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

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsessionoption

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsession

.LINK
https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "False positive")]
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

#region Preference variables

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

	# NOTE: Following preferences should be always the same, do not modify!
	$ErrorActionPreference = "Continue"
	$WarningPreference = "Continue"
	$InformationPreference = "Continue"
	$ProgressPreference	= "Continue"

	# Optionall override to debug modules globally
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
		# Medium, prompt for medium and hight impact actions
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

# Specifies the default session configuration that is used for PSSessions created in the current session.
# The default value http://schemas.microsoft.com/PowerShell/microsoft.PowerShell indicates
# the "Microsoft.PowerShell" session configuration on the remote computer.
# If you specify only a configuration name, the following schema URI is prepended:
# http://schemas.microsoft.com/PowerShell/
$PSSessionConfigurationName = "RemoteFirewall.$($PSVersionTable.PSEdition)"

# The $PSSessionApplicationName preference variable is set on the local computer,
# but it specifies a listener on the remote computer.
# The system default application name is wsman
$PSSessionApplicationName = "wsman"

# Advanced options for a user-managed remote session
# HACK: These options don't seem to be respected in regard to timeouts
# NOTE: OperationTimeout (in milliseconds), affects both the PS and CIM sessions.
# The maximum time that any operation in the session can run.
# When the interval expires, the operation fails.
# The default value is 180000 (3 minutes). A value of 0 (zero) means no time-out for PS sessions,
# for CIM sessions it means use the default timeout value for the server (usually 3 minutes)
# NOTE: CancelTimeout (in milliseconds), affects only PS sessions
# Determines how long PowerShell waits for a cancel operation (CTRL+C) to finish before ending it.
# The default value is 60000 (one minute). A value of 0 (zero) means no time-out.
# NOTE: OpenTimeout (in milliseconds), affects only PS sessions
# Determines how long the client computer waits for the session connection to be established.
# The default value is 180000 (3 minutes). A value of 0 (zero) means no time-out.
# NOTE: MaxConnectionRetryCount, affects PS session, Test-NetConnection and Invoke-WebRequest
# Specifies count of attempts to make a connection to a target host if the current attempt
# fails due to network issues.
# The default value is 5 for PS session.
# The default value is 4 for Test-NetConnection which specifies echo requests
# [System.Management.Automation.Remoting.PSSessionOption]
# NOTE: Used later, $PSSessionOption = New-PSSessionOption -UICulture en-US -Culture en-US `
# -OpenTimeout 3000 -CancelTimeout 5000 -OperationTimeout 10000 -MaxConnectionRetryCount 2

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
# Name of this script for debugging messages, do not modify!
Set-Variable -Name SettingsScript -Scope Private -Option ReadOnly -Force -Value ((Get-Item $PSCommandPath).Basename)

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

if (!(Get-Variable -Name ProjectRoot -Scope Global -ErrorAction Ignore))
{
	# Repository root directory, reallocating scripts should be easy if root directory is constant
	New-Variable -Name ProjectRoot -Scope Global -Option Constant -Value (
		Resolve-Path -Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path)

	# Valid policy stores
	New-Variable -Name LocalStores -Scope Global -Option Constant -Value @(
		([System.Environment]::MachineName)
		"PersistentStore"
		"ActiveStore"
		"RSOP"
		"SystemDefaults"
		"StaticServiceStore"
		"ConfigurableServiceStore"
	)
}

if ($Develop -and !$InModule)
{
	# Remove loaded modules, useful for module debugging and to avoid restarting powershell every time.
	# Skip removing modules if this script is called from within a module which would cause removing modules prematurely
	Get-Module -Name Ruleset.* | ForEach-Object {
		Write-Debug -Message "[$SettingsScript] Removing module $_"
		Remove-Module -Name $_ -ErrorAction Stop
	}
}
#endregion

#region Remote session initialization
if ($PSCmdlet.ParameterSetName -eq "Script")
{
	if (Get-Variable -Name PolicyStore -Scope Global -ErrorAction Ignore)
	{
		if ($TargetHost -and ($TargetHost -ne $PolicyStore))
		{
			# TODO: Temporarily while working on remoting
			Write-Error -Category InvalidArgument -TargetObject $TargetHost -EA Stop `
				-Message "Unexpected computer name '$TargetHost', remote already set to '$PolicyStore'"
		}
	}
	else
	{
		# Target machine onto which to deploy firewall (default: Local Group Policy)
		if ([string]::IsNullOrEmpty($TargetHost) -or ($TargetHost -eq "localhost"))
		{
			New-Variable -Name PolicyStore -Scope Global -Option ReadOnly -Value ([System.Environment]::MachineName)
		}
		else
		{
			New-Variable -Name PolicyStore -Scope Global -Option ReadOnly -Value $TargetHost
		}
	}

	if (!(Get-Variable -Name SessionEstablished -Scope Global -ErrorAction Ignore))
	{
		Write-Debug -Message "[$SettingsScript] Establishing session to remote computer"

		# NOTE: Global object RemoteRegistry (PSDrive), RemoteCim (CimSession) and RemoteSession (PSSession) are created by Connect-Computer function
		# NOTE: Global variable CimServer is set by Connect-Computer function
		# Destruction of these is done by Disconnect-Computer

		$ConnectParams = @{
			ErrorAction = "Stop"
			Domain = $PolicyStore
			Protocol = "HTTPS"
			ConfigurationName = $PSSessionConfigurationName
			ApplicationName = $PSSessionApplicationName
		}

		# PSPrimitiveDictionary, data to send to remote computer
		$SenderArguments = @{
			Domain = $PolicyStore
		}

		$SessionOptionParams = @{
			UICulture = "en-US"
			Culture = "en-US"
			OpenTimeout = 3000
			CancelTimeout = 5000
			OperationTimeout = 10000
			MaxConnectionRetryCount = 2
			ApplicationArguments = $SenderArguments
			NoEncryption = $false
			NoCompression = $false
		}

		Import-Module -Name $ProjectRoot\Modules\Ruleset.Remote -Scope Global
		$PolicyStoreStatus = $false

		if ($PolicyStore -notin $LocalStores)
		{
			$ConnectParams["Credential"] = Get-Credential -Message "Credentials are required to access '$PolicyStore'"
			Test-WinRM -Protocol HTTPS -Domain $PolicyStore -Credential $ConnectParams["Credential"] -Status ([ref] $PolicyStoreStatus) -Quiet

			# TODO: A new function needed to conditionally configure remote host here
			# TODO: If credentials are not valid, configuring WinRM won't make any difference
			if (!$PolicyStoreStatus)
			{
				# Configure this machine for remote session over SSL
				Set-WinRMClient -Domain $PolicyStore -Confirm:$false
				Enable-RemoteRegistry -Confirm:$false
				Test-WinRM -Protocol HTTPS -Domain $PolicyStore -Credential $ConnectParams["Credential"] `
					-Status ([ref] $PolicyStoreStatus) -Quiet -ErrorAction Stop
			}

			# TODO: Encoding, the acceptable values for this parameter are: Default, Utf8, or Utf16
			# There is global variable that controls encoding, see if it can be used here
			$ConnectParams["CimOptions"] = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture en-US -Culture en-US
		}
		elseif ($PolicyStore -eq [System.Environment]::MachineName)
		{
			Test-WinRM -Protocol HTTP -Status ([ref] $PolicyStoreStatus) -Quiet

			if (!$PolicyStoreStatus)
			{
				# Enable loopback only HTTP
				Set-WinRMClient -Protocol HTTP -Confirm:$false
				Enable-WinRMServer -Protocol HTTP -Confirm:$false
				Disable-WinRMServer -Confirm:$false
			}

			$SessionOptionParams["NoEncryption"] = $true
			$SessionOptionParams["NoCompression"] = $true

			$ConnectParams["Protocol"] = "HTTP"
			# TODO: Culture default values project wide
			$ConnectParams["CimOptions"] = New-CimSessionOption -Protocol Wsman -UICulture en-US -Culture en-US
		}
		else
		{
			Write-Error -Category NotImplemented -TargetObject $PolicyStore -EA Stop `
				-Message "Deployment to specified policy store not implemented '$PolicyStore'"
		}

		Remove-Variable -Name PolicyStoreStatus

		# TODO: Not all options are used, ex. -NoCompression and -NoEncryption could be used for loopback
		$ConnectParams["SessionOption"] = New-PSSessionOption @SessionOptionParams

		try
		{
			Connect-Computer @ConnectParams

			# Check if session is already initialized and established, do not modify!
			# TODO: Connect-Computer may fail without throwing
			Set-Variable -Name SessionEstablished -Scope Global -Option ReadOnly -Force -Value $true

			Remove-Variable -Name ConnectParams
			Remove-Variable -Name SenderArguments
			Remove-Variable -Name SessionOptionParams
		}
		catch
		{
			# To allow trying again
			Remove-Variable -Name PolicyStore -Scope Global -Force
			Write-Error -ErrorRecord $_ -ErrorAction Stop
		}
	}
}
#endregion

#region Removable variables, these can be modified as follows:
# 1. By project code at any time
# 2. Only once by user before running any project scripts
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
}
#endregion

#region Conditional preference variables
# Value of these preference variables depend on existing logging variables, do not modify!
if (!$InModule)
{
	# NOTE: Not using these parameters inside modules because they will be passed to module functions
	# by top level advanced function in call stack which will pick up all Write-* streams in module functions
	# NOTE: For functions outside module for same reason we need to declare PSDefaultParameterValues
	# as private which will prevent propagating default parameters to functions in child scopes,
	# In short advanced functions in child scopes and modules will receive these parameters by parent
	# function, this is needed to avoid duplicate log entries.
	# TODO: Could this override anything?
	$private:PSDefaultParameterValues = @{}

	if ($ErrorLogging)
	{
		$private:PSDefaultParameterValues["*:ErrorVariable"] = "+ErrorBuffer"
	}

	if ($WarningLogging)
	{
		$private:PSDefaultParameterValues["*:WarningVariable"] = "+WarningBuffer"
	}

	if ($InformationLogging)
	{
		$private:PSDefaultParameterValues["*:InformationVariable"] = "+InfoBuffer"
	}
}
#endregion

#region Read only variables, these can be modified as follows:
# 1. By project code at any time
# 2. Only once by user before running any project scripts
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
	New-Variable -Name ModulesCheck -Scope Global -Option ReadOnly -Value $Develop

	# Set to false to avoid checking if required system services are started
	New-Variable -Name ServicesCheck -Scope Global -Option ReadOnly -Value $true
}
#endregion

#region Read only variables 2, these can be modified as follows:
# 1. Never by project code
# 2. Only once by user before running any project scripts
# 3. Any amount of time by user if "develop" mode is ON
# In all other cases changing variable values requires PowerShell restart
if ($Develop -or !(Get-Variable -Name CheckReadOnlyVariables2 -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up read only variables - user only"

	# Check if removable variables already initialized, do not modify!
	Set-Variable -Name CheckReadOnlyVariables2 -Scope Global -Option ReadOnly -Force -Value $null

	# Windows 10, Windows Server 2019 and above
	Set-Variable -Name Platform -Scope Global -Option ReadOnly -Force -Value "10.0+"

	# Default network interface card to use if not locally specified
	# TODO: We can learn this value programatically but, problem is the same as with specifying local IP
	Set-Variable -Name DefaultInterface -Scope Global -Option ReadOnly -Force -Value "Wired, Wireless"

	# Default network profile to use if not locally specified.
	# NOTE: Do not modify except to to debug rules or unless absolutely needed!
	Set-Variable -Name DefaultProfile -Scope Global -Option ReadOnly -Force -Value "Private, Public"

	# To force loading rules regardless of presence of a program set to true
	# The purpose of this is to test loading rules that would otherwise be skipped
	Set-Variable -Name ForceLoad -Scope Global -Option ReadOnly -Force -Value $false

	if ($PSVersionTable.PSEdition -eq "Core")
	{
		# Set to false to use IPv6 instead of IPv4 to test connection to target policy store
		# NOTE: Requests for Comments (RFCs) 1001 and 1002 define NetBIOS operation over IPv4.
		# NetBT is not defined for IPv6.
		Set-Variable -Name ConnectionIPv4 -Scope Global -Option ReadOnly -Force -Value $true
	}

	# User account name for which to search executables in user profile and non standard paths by default
	# Also used for other defaults where standard user account is expected, ex. development as standard user
	# NOTE: If there are multiple users and to affect them all set this value to non existent user
	# TODO: needs testing info messages for this value
	# TODO: We are only assuming about accounts here as a workaround due to often need to modify variable
	# TODO: This should be used for LocalUser rule parameter too
	try
	{
		# A workaround which will fail if there are no standard users
		Set-Variable -Name DefaultUser -Scope Global -Option ReadOnly -Force -Value (
			Split-Path -Path (Get-LocalGroupMember -Group Users | Where-Object {
					$_.ObjectClass -EQ "User" -and
					($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
				} | Select-Object -ExpandProperty Name -Last 1) -Leaf)
	}
	catch
	{
		Set-Variable -Name DefaultUser -Scope Global -Option ReadOnly -Force -Value "UnknownUser"
		Write-Warning -Message "No users exists in 'Users' group"
	}

	# Administrative user account name which will perform unit testing
	Set-Variable -Name TestAdmin -Scope Global -Option ReadOnly -Force -Value (
		Split-Path -Path (Get-LocalGroupMember -Group Administrators | Where-Object {
				$_.ObjectClass -EQ "User" -and
				($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
			} | Select-Object -ExpandProperty Name -Last 1) -Leaf)

	# Standard user account name which will perform unit testing
	Set-Variable -Name TestUser -Scope Global -Option ReadOnly -Force -Value $DefaultUser

	# Remote test computer which will perform unit testing
	Set-Variable -Name TestDomain -Scope Global -Option ReadOnly -Force -Value "VM-PRO11"
}
#endregion

#region Constant variables, these can be modified as follows:
# 1. Never by project code
# 2. Only once by user before running any project scripts
# In all other cases changing variable values requires PowerShell restart
if (!(Get-Variable -Name CheckProjectConstants -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$SettingsScript] Setting up constant variables"

	# Check if constants already initialized, used for module reloading, do not modify!
	New-Variable -Name CheckProjectConstants -Scope Global -Option Constant -Value $null

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
	New-Variable -Name ProjectVersion -Scope Global -Option Constant -Value ([version]::new(0, 11, 0))

	# Required minimum operating system version (v1809)
	# TODO: v1809 needs to be replaced with minimum v1903, downgraded here because of Server 2019
	# https://docs.microsoft.com/en-us/windows/release-information
	# https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info
	New-Variable -Name RequireWindowsVersion -Scope Global -Option Constant -Value ([version]::new(10, 0, 17763))

	# Project logs folder
	New-Variable -Name LogsFolder -Scope Global -Option Constant -Value "$ProjectRoot\Logs"

	# These drives will help to have shorter prompt and to be able to jump to them with less typing
	# TODO: Should we use these drives instead of "ProjectRoot" variable?
	# HACK: In some cases there is problem using those drives soon after being created, also running
	# scripts while prompt at drive will cause issues setting location
	# for more info see: https://github.com/dsccommunity/SqlServerDsc/issues/118
	New-PSDrive -Name root -Root $ProjectRoot -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip4 -Root "$ProjectRoot\Rules\IPv4" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name ip6 -Root "$ProjectRoot\Rules\IPv6" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name mod -Root "$ProjectRoot\Modules" -Scope Global -PSProvider FileSystem | Out-Null
	New-PSDrive -Name test -Root "$ProjectRoot\Test" -Scope Global -PSProvider FileSystem | Out-Null

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
		New-Variable -Name RequirePSVersion -Scope Global -Option Constant -Value ([version]::new(7, 2, 1))
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
		New-Variable -Name RequireAnalyzerVersion -Scope Global -Option Constant -Value ([version]::new(1, 20, 0))

		# Recommended minimum posh-git version for git in PowerShell
		# NOTE: pre-release minimum 1.0.0-beta4 will be installed
		New-Variable -Name RequirePoshGitVersion -Scope Global -Option Constant -Value ([version]::new(1, 0, 0))

		# Recommended minimum Pester version for code testing
		# NOTE: PScriptAnalyzer 1.19.1 requires pester v5
		# TODO: we need pester v4 for tests, but why does analyzer require pester?
		New-Variable -Name RequirePesterVersion -Scope Global -Option Constant -Value ([version]::new(5, 3, 1))

		# Required minimum PackageManagement version prior to installing other modules, do not decrement!
		New-Variable -Name RequirePackageManagementVersion -Scope Global -Option Constant -Value ([version]::new(1, 4, 7))

		# Required minimum PowerShellGet version prior to installing other modules, do not decrement!
		New-Variable -Name RequirePowerShellGetVersion -Scope Global -Option Constant -Value ([version]::new(2, 2, 5))

		# Recommended minimum platyPS version used to generate online help files for modules, do not decrement!
		New-Variable -Name RequirePlatyPSVersion -Scope Global -Option Constant -Value ([version]::new(0, 14, 2))

		# Recommended minimum PSReadline version for command line editing experience of PowerShell
		# Needs the 1.6.0 or a higher version of PowerShellGet to install the latest prerelease version of PSReadLine
		New-Variable -Name RequirePSReadlineVersion -Scope Global -Option Constant -Value ([version]::new(2, 1, 0))
	}

	if ($Develop -or ($ProjectCheck -and $ModulesCheck))
	{
		# Recommended minimum Git version needed for contributing and required by posh-git
		# https://github.com/dahlbyk/posh-git#prerequisites
		New-Variable -Name RequireGitVersion -Scope Global -Option Constant -Value ([version]::new(2, 34, 1))
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
		New-Variable -Name RequireVSCodeVersion -Scope Global -Option Constant -Value ([version]::new(1, 63, 2))

		# Firewall logs folder
		# NOTE: Set this value to $LogsFolder\Firewall to enable reading logs in VSCode with syntax highlighting
		# In that case for changes to take effect run Scripts\Complete-Firewall.ps1 and reboot system
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value $LogsFolder\Firewall
	}
	else
	{
		# Firewall logs folder
		# NOTE: System default is %SystemRoot%\System32\LogFiles\Firewall
		New-Variable -Name FirewallLogsFolder -Scope Global -Option Constant -Value "%SystemRoot%\System32\LogFiles\Firewall"
	}

	# Add project module directory to session module path
	# TODO: We can avoid using Import-Module in this script if this is executed earlier
	New-Variable -Name PathEntry -Scope Private -Value (
		[System.Environment]::GetEnvironmentVariable("PSModulePath").TrimEnd(";") -replace (";;", ";"))

	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Modules"
	[System.Environment]::SetEnvironmentVariable("PSModulePath", $PathEntry)

	# Add project script directory to session script path
	$PathEntry = [System.Environment]::GetEnvironmentVariable("Path").TrimEnd(";") -replace (";;", ";")
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts"
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\Experiment"
	$PathEntry += "$([System.IO.Path]::PathSeparator)$ProjectRoot\Scripts\Utility"
	[System.Environment]::SetEnvironmentVariable("Path", $PathEntry)

	Remove-Variable -Name PathEntry -Scope Private

	# Load format data into session
	Get-ChildItem -Path "$ProjectRoot\Scripts" -Filter *.ps1xml -Recurse | ForEach-Object {
		Update-FormatData -AppendPath $_.FullName
	}

	# Default output location for unit tests that produce file system output
	New-Variable -Name DefaultTestDrive -Scope Global -Option Constant -Value $ProjectRoot\Test\TestDrive
}
#endregion

#region Protected variables, these can be modified as follows:
# 1. By project code at any time
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
		problems with preferences or just to confirm preferences are set as expected.

		.PARAMETER All
		If specified, shows all variables from this script including Path and PSModulePath values

		.EXAMPLE
		PS> Show-Preference ModuleName

		.NOTES
		None.
		#>
		function Show-Preference
		{
			param (
				[Parameter()]
				[switch] $All
			)

			# Get base name of script that called this function
			$Caller = (Split-Path -Path $MyInvocation.ScriptName -Leaf) -replace "\.\w{2,3}1$"

			if ($Caller -eq "ProjectSettings")
			{
				# Get base name of script that dot sourced ProjectSettings.ps1
				$Caller = (Split-Path -Path (Get-PSCallStack)[2].Command -Leaf) -replace "\.\w{2,3}1$"
			}

			Set-Variable -Name IsValidParent -Scope Local -Value "Scope test"
			Write-Debug -Message "[Show-Preference] InformationPreference before Get-CallerPreference: $InformationPreference" -Debug

			& Get-CallerPreference.ps1 -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState # -Verbose -Debug
			Write-Debug -Message "[Show-Preference] InformationPreference after Get-CallerPreference: $InformationPreference" -Debug

			$Variables = Get-ChildItem -Path Variable:\*Preference

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
				Write-Host "[$Caller] $($Variable.Name) = $($Variable.Value)" -ForegroundColor Cyan
			}

			if ($All)
			{
				$DriveEntry = Get-PSDrive -PSProvider FileSystem -Name root, mod, ip4, ip6, test |
				Select-Object -Property Name, Root

				foreach ($Entry in $DriveEntry)
				{
					Write-Host "[$Caller] $($Entry.Name):\ = $($Entry.Root)" -ForegroundColor Cyan
				}

				foreach ($Entry in @($env:PSModulePath.Split(";")))
				{
					Write-Host "[$Caller] ModulePath = $Entry" -ForegroundColor Cyan
				}

				foreach ($Entry in @($env:Path.Split(";")))
				{
					Write-Host "[$Caller] Path = $Entry" -ForegroundColor Cyan
				}
			}
		}
	} | Import-Module -Scope Global

	if (!$InModule)
	{
		# NOTE: Scripts which dot source this one are same scope thus Show-Preference pulls both
		Write-Debug -Message "[$SettingsScript] InformationPreference: $InformationPreference" -Debug
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

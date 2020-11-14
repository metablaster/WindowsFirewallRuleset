###########################################################################################
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# TODO: Update Copyright and start writing code

# Initialization
using namespace System.Management.Automation.
using namespace System.Management.Automation.Runspaces
Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
. $PSScriptRoot\..\..\Modules\ModulePreferences.ps1

#
# Script imports
# TODO: which imports should be private?
#

$PrivateScripts = @(
)

foreach ($Script in $PrivateScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Private\$Script.ps1"
	. ("{0}\Private\{1}.ps1" -f $PSScriptRoot, $Script)
}

$PublicScripts = @(
	"Add-WindowsPSModulePath"
	"Add-WinFunction"
	"Compare-WinModule"
	"Copy-WinModule"
	"Get-WinModule"
	"Import-WinModule"
	"Initialize-WinSession"
	"Invoke-WinCommand"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

#
# Module variables
#

###########################################################################################
# A list of modules native to PowerShell Core that should never be imported
Set-Variable -Name NeverImportList -Scope Script -Value @(
	"PSReadLine",
	"PackageManagement",
	"PowerShellGet",
	"Microsoft.PowerShell.Archive",
	"Microsoft.PowerShell.Host",
	"WindowsCompatibility"
)

###########################################################################################
# The following is a list of modules native to PowerShell Core that don't have all of
# the functionality of Windows PowerShell 5.1 versions. These modules can be imported but
# will not overwrite any existing PowerShell Core commands
Set-Variable -Name NeverClobberList -Scope Script -Value @(
	"Microsoft.PowerShell.Management",
	"Microsoft.PowerShell.Utility",
	"Microsoft.PowerShell.Security",
	"Microsoft.PowerShell.Diagnostics"
)

###########################################################################################
# A list of compatible modules that exist in Windows PowerShell that aren't available
# to PowerShell Core by default. These modules, along with CIM modules can be installed
# in the PowerShell Core module repository using the Copy-WinModule command.
Set-Variable -Name CompatibleModules -Scope Script -Value @(
	"AppBackgroundTask",
	"AppLocker",
	"Appx",
	"AssignedAccess",
	"BitLocker",
	"BranchCache",
	"CimCmdlets",
	"ConfigCI",
	"Defender",
	"DeliveryOptimization",
	"DFSN",
	"DFSR",
	"DirectAccessClientComponents",
	"Dism",
	"EventTracingManagement",
	"GroupPolicy",
	"Hyper-V",
	"International",
	"IscsiTarget",
	"Kds",
	"MMAgent",
	"MsDtc",
	"NetAdapter",
	"NetConnection",
	"NetSecurity",
	"NetTCPIP",
	"NetworkConnectivityStatus",
	"NetworkControllerDiagnostics",
	"NetworkLoadBalancingClusters",
	"NetworkSwitchManager",
	"NetworkTransition",
	"PKI",
	"PnpDevice",
	"PrintManagement",
	"ProcessMitigations",
	"Provisioning",
	"PSScheduledJob",
	"ScheduledTasks",
	"SecureBoot",
	"SmbShare",
	"Storage",
	"TrustedPlatformModule",
	"VpnClient",
	"Wdac",
	"WindowsDeveloperLicense",
	"WindowsErrorReporting",
	"WindowsSearch",
	"WindowsUpdate"
)

# Module-scope variable to hold the active compatibility session name
Set-Variable -Name SessionName -Scope Script -Value $null

# The computer name to use if one isn't provided.
$SessionComputerName = 'localhost'

# Specifies the default configuration to connect to when creating the compatibility session
$SessionConfigurationName = 'Microsoft.PowerShell'

Set-Alias -Name Add-WinPSModulePath -Value Add-WindowsPSModulePath

# Location Changed handler that keeps the compatibility session PWD in sync with the parent PWD
# This only applies on localhost.
$locationChangedHandler = {
	[PSSession] $session = Initialize-WinSession -ComputerName $SessionComputerName -ConfigurationName $SessionConfigurationName -PassThru
	if ($session.ComputerName -eq "localhost")
	{
		$newPath = $_.newPath
		Invoke-Command -Session $session { Set-Location $using:newPath }
	}
}

$ExecutionContext.InvokeCommand.LocationChangedAction = $locationChangedHandler

# Remove the location changed handler if the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	if ($ExecutionContext.InvokeCommand.LocationChangedAction -eq $locationChangedHandler)
	{
		$ExecutionContext.InvokeCommand.LocationChangedAction = $null
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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

# NOTE: Following modifications by metablaster November 2020:
# - Move functions into separate scripts
# - Code formatting according to the rest of project design
# - Added module boilerplate code
# - Renamed module from "WindowsCompatibility" to "Ruleset.Compatibility"

# Initialization
using namespace System.Management.Automation.
using namespace System.Management.Automation.Runspaces
Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule
. $PSScriptRoot\..\..\Modules\ModulePreferences.ps1

#
# Script imports
#

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
	"Ruleset.Compatibility"
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

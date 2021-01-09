
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
# - Fixed pester tests

#region Initialization
using namespace System.Management.Automation
using namespace System.Management.Automation.Runspaces

param (
	[Parameter()]
	[switch] $ListPreference
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule -ListPreference:$ListPreference

if ($ListPreference)
{
	# NOTE: Preferences defined in caller scope are not inherited, only those defined in
	# Config\ProjectSettings.ps1 are pulled into module scope
	Write-Debug -Message "[$ThisModule] InformationPreference in module: $InformationPreference" -Debug
	Show-Preference # -All
	Remove-Module -Name Dynamic.Preference
}
#endregion

# TODO: -NoClobber, this module may already exist on target computer
# TODO: Take time to load + hide blinking progress bar

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
	try
	{
		. "$PSScriptRoot\Public\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Public\$Script.ps1' $($_.Exception.Message)"
	}
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# A list of modules native to PowerShell Core that should never be imported
New-Variable -Name NeverImportList -Scope Script -Value @(
	"PSReadLine",
	"PackageManagement",
	"PowerShellGet",
	"Microsoft.PowerShell.Archive",
	"Microsoft.PowerShell.Host",
	"Ruleset.Compatibility"
)

# The following is a list of modules native to PowerShell Core that don't have all of
# the functionality of Windows PowerShell 5.1 versions. These modules can be imported but
# will not overwrite any existing PowerShell Core commands
New-Variable -Name NeverClobberList -Scope Script -Value @(
	"Microsoft.PowerShell.Management",
	"Microsoft.PowerShell.Utility",
	"Microsoft.PowerShell.Security",
	"Microsoft.PowerShell.Diagnostics"
)

# A list of compatible modules that exist in Windows PowerShell that aren't available
# to PowerShell Core by default. These modules, along with CIM modules can be installed
# in the PowerShell Core module repository using the Copy-WinModule command.
New-Variable -Name CompatibleModules -Scope Script -Value @(
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
New-Variable -Name SessionName -Scope Script -Value $null

# The computer name to use if one isn't provided.
$SessionComputerName = "localhost"

# Specifies the default configuration to connect to when creating the compatibility session
$SessionConfigurationName = "Microsoft.PowerShell"

New-Alias -Name Add-WinPSModulePath -Value Add-WindowsPSModulePath

# Location Changed handler that keeps the compatibility session PWD in sync with the parent PWD
# This only applies on localhost.
$LocationChangedHandler = {
	[PSSession] $Session = Initialize-WinSession -Domain $SessionComputerName `
		-ConfigurationName $SessionConfigurationName -PassThru

	if ($Session.ComputerName -eq "localhost")
	{
		$NewPath = $_.NewPath
		Invoke-Command -Session $Session { Set-Location $using:NewPath }
	}
}

$ExecutionContext.InvokeCommand.LocationChangedAction = $LocationChangedHandler

#
# Module cleanup
#

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	Write-Debug -Message "[$ThisModule] Cleanup module"

	# Remove the location changed handler if the module is removed.
	if ($ExecutionContext.InvokeCommand.LocationChangedAction -eq $LocationChangedHandler)
	{
		$ExecutionContext.InvokeCommand.LocationChangedAction = $null
	}
}

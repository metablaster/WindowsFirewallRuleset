
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.13.0

.GUID 181dea4a-4658-425e-904e-5f22f886af89

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Set advanced threat protection settings

.DESCRIPTION
Use Set-ATP.ps1 to configure Microsoft Defender Antivirus.

.PARAMETER Domain
Computer name onto which do deploy ATP configuration

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Set-ATP

.EXAMPLE
PS> Set-ATP -Domain Server01

.INPUTS
None. You cannot pipe objects to Set-ATP.ps1

.OUTPUTS
None. Set-ATP.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

# Replace localhost and dot with NETBIOS computer name
if (($Domain -eq "localhost") -or ($Domain -eq "."))
{
	$Domain = [System.Environment]::MachineName
}

# User prompt
$Accept = "Accpet deploying ASR rules to target computer"
$Deny = "Abort operation, no ASR rules will be deployed"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if ($PSCmdlet.ShouldProcess("Microsoft Defender Antivirus", "Deploy recommended settings"))
{
	# Block at first sight (MAPS)
	Set-MpPreference -SubmitSamplesConsent 3 -MAPSReporting Basic -DisableBlockAtFirstSeen $false `
		-DisableIOAVProtection $false -DisableRealtimeMonitoring $false -CimSession $CimServer

	# Cloud protection
	# https://docs.microsoft.com/en-us/graph/api/resources/intune-deviceconfig-defendercloudblockleveltype
	Set-MpPreference -CloudExtendedTimeout 50 -CloudBlockLevel high -EnableFileHashComputation $true -CimSession $CimServer

	# Scan
	Set-MpPreference -ScanAvgCPULoadFactor 60 -ScanScheduleDay Sunday -ScanScheduleTime 720 `
		-CheckForSignaturesBeforeRunningScan $true -ScanParameters FullScan `
		-DisableCatchupFullScan $false `
		-DisableCatchupQuickScan $false `
		-DisableRestorePoint $false `
		-DisableScriptScanning $false `
		-DisableArchiveScanning $false `
		-DisableEmailScanning $true `
		-DisableRemovableDriveScanning $true `
		-DisableScanningMappedNetworkDrivesForFullScan $true `
		-DisableScanningNetworkFiles $true `
		-CimSession $CimServer

	# Other
	Set-MpPreference -DisableBehaviorMonitoring $false -CimSession $CimServer
}

Update-Log

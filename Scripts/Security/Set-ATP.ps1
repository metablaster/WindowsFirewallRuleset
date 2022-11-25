
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

.VERSION 0.14.0

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

.LINK
https://docs.microsoft.com/en-us/graph/api/resources/intune-deviceconfig-defendercloudblockleveltype
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

# User prompt
$Accept = "Accpet deploying ASR rules to target computer"
$Deny = "Abort operation, no ASR rules will be deployed"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if ($PSCmdlet.ShouldProcess("Microsoft Defender Antivirus", "Configure Advanced Thread Protection"))
{
	# ADVANCED THREAT PROTECTION

	$PolicyPath = "$env:WinDir\System32\GroupPolicy\Machine\Registry.pol"
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\MAPS

	#
	# Block at first sight (MAPS)
	#

	Write-Information -MessageData "[$ThisScript] Join Microsoft MAPS"
	# Join Microsoft MAPS
	# item: decimal: 0 => Disabled
	# item: decimal: 1 => Basic MAPS
	# item: decimal: 2 => Advanced MAPS
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"
	$ValueName = "SpynetReporting"
	$Value = 2
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord

	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Send file samples when further analysis is required"
	# Send file samples when further analysis is required (Send safe samples)
	# item: decimal: 0 => Always prompt
	# item: decimal: 1 => Send safe samples
	# item: decimal: 2 => Never send
	# item: decimal: 3 => Send all samples
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"
	$ValueName = "SubmitSamplesConsent"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName "SubmitSamplesConsent" -Data 1 -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Configure the 'Block at First Sight' feature"
	# Configure the "Block at First Sight" feature (Enabled)
	# NOTE: Depends on:
	# "Join Microsoft MAPS"
	# "Send file samples when further analysis is required (option 1 or 3)"
	# Scan all downloaded files and attachments
	# "Real time protection - do not enable 'turn off real time protection"
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"
	$ValueName = "DisableBlockAtFirstSeen"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Scan all downloaded files and attachments"
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Real-time Protection
	# Scan all downloaded files and attachments (Enabled)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableIOAVProtection"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Turn of realtime protection"
	# Turn off real-time protection (Disabled)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableRealtimeMonitoring"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Cloud protection
	#

	Write-Information -MessageData "[$ThisScript] Enable file hash computation feature"
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\mpengine
	# Enable file hash computation feature (Optional)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"
	$ValueName = "EnableFileHashComputation"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Configure extended cloud check"
	# Configure extended cloud check (50 max)
	# This feature allows Microsoft Defender Antivirus to block a suspicious file for up to X seconds, and scan it in the cloud to make sure it´s safe.
	# NOTE: This feature depends on three other MAPS settings:
	# 1. "Configure the ´Block at First Sight´ feature
	# 2. "Join Microsoft MAPS";
	# 3. "Send file samples when further analysis is required" all need to be enabled.
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"
	$ValueName = "MpBafsExtendedTimeout"
	$Value = 50
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Select cloud protection level"
	# Select cloud protection level (High blocking level)
	# NOTE: This feature requires the "Join Microsoft MAPS"
	# item: decimal: 0 => Default blocking level
	# item: decimal: 1 => Moderate blocking level
	# item: decimal: 2 => High blocking level
	# item: decimal: 4 => High+ blocking level
	# item: decimal: 6 => Zero tolerance blocking level
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"
	$ValueName = "MpCloudBlockLevel"
	$Value = 2
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind


	#
	# Attack Surface Reduction
	#

	# Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard
	# Configure Attack Surface Reduction rules
	# Set-ASR

	#
	# Network protection
	#

	Write-Information -MessageData "[$ThisScript] Prevent users and apps from accessing dangerous websites"
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Network Protection
	# Prevent users and apps from accessing dangerous websites (Block)
	# item: decimal: 0 => Disable (Default)
	# item: decimal: 1 => Block
	# item: decimal: 2 => Audit Mode
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection"
	$ValueName = "EnableNetworkProtection"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Scan
	#

	Write-Information -MessageData "[$ThisScript] Specify the maximum percentage of CPU utilization during a scan"
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Scan
	# Specify the maximum percentage of CPU utilization during a scan (50%, Optional)
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "AvgCPULoadFactor"
	$Value = 50
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "[$ThisScript] Check for the latest virus and spyware security intelligence before running a scheduled scan"
	# Check for the latest virus and spyware security intelligence before running a scheduled scan (Optional)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "CheckForSignaturesBeforeRunningScan"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	# Update changes done to registry
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"

	if ($false)
	{
		# TODO: Not implemented
		Set-MpPreference -ScanScheduleDay Sunday -ScanScheduleTime 720 `
			-ScanParameters FullScan `
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
}

Update-Log

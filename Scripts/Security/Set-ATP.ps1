
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
In addition to Windows Defender ATP settings a several other settings are enabled for
maximum antivirus security.

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
TODO: There are some exotic options for Set-MpPreference which we don't use
TODO: Switches are required to optionally set non ATP settings

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference

.LINK
https://learn.microsoft.com/en-us/windows/security/zero-trust-windows-device-health

.LINK
https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint

.LINK
https://gpsearch.azurewebsites.net
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project

# User prompt
$Accept = "Configure Windows Defender and Advanced Threat Protection"
$Deny = "Abort operation, ATP and Windows defender will not be modified"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if ($PSCmdlet.ShouldProcess("Microsoft Defender Antivirus", "Configure Advanced Thread Protection and settings"))
{
	# GPO\Computer configuration
	$PolicyPath = "$env:WinDir\System32\GroupPolicy\Machine\Registry.pol"

	#
	# MAPS
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\MAPS
	#

	Write-Information -MessageData "INFO: Join Microsoft MAPS"
	# Join Microsoft MAPS (Advanced MAPS)
	# item: decimal: 0 => Disabled
	# item: decimal: 1 => Basic MAPS
	# item: decimal: 2 => Advanced MAPS
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"
	$ValueName = "SpynetReporting"
	$Value = 2
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Send file samples when further analysis is required"
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

	Write-Information -MessageData "INFO: Configure the 'Block at First Sight' feature"
	# Configure the "Block at First Sight" feature (Enabled)
	# NOTE: This feature requires four other settings to be enabled:
	# 1. "Join Microsoft MAPS"
	# 2. "Send file samples when further analysis is required (option 1 or 3)"
	# 3. "Scan all downloaded files and attachments"
	# 4. "Real time protection - do not enable 'turn off real time protection'"
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"
	$ValueName = "DisableBlockAtFirstSeen"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Real-time protection
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Real-time Protection
	#

	Write-Information -MessageData "INFO: Scan all downloaded files and attachments"
	# Scan all downloaded files and attachments (Enabled)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableIOAVProtection"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Turn off realtime protection"
	# Turn off real-time protection (Disabled)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableRealtimeMonitoring"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Turn on behavioral monitoring"
	# Turn on behavioral monitoring (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableBehaviorMonitoring"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Monitor file and program activity on your computer"
	# Monitor file and program activity on your computer (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableOnAccessProtection"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Turn on process scanning whenever real-time protection is enabled"
	# Turn on process scanning whenever real-time protection is enabled (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
	$ValueName = "DisableScanOnRealtimeEnable"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# mpengine
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\mpengine
	#

	Write-Information -MessageData "INFO: Enable file hash computation feature"
	# Enable file hash computation feature (Optional)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"
	$ValueName = "EnableFileHashComputation"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Configure extended cloud check"
	# Configure extended cloud check (50 max)
	# This feature allows Microsoft Defender Antivirus to block a suspicious file for up to X seconds, and scan it in the cloud to make sure it's safe.
	# NOTE: This feature depends on three other MAPS settings:
	# 1. "Configure the 'Block at First Sight' feature
	# 2. "Join Microsoft MAPS"
	# 3. "Send file samples when further analysis is required"
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"
	$ValueName = "MpBafsExtendedTimeout"
	$Value = 50
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Select cloud protection level"
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

	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Attack Surface Reduction
	# Configure Attack Surface Reduction rules
	# Set-ASR

	#
	# Microsoft Defender Exploit Guard
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Network Protection
	#

	Write-Information -MessageData "INFO: Prevent users and apps from accessing dangerous websites"
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
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Scan
	#

	Write-Information -MessageData "INFO: Check for the latest virus and spyware security intelligence before running a scheduled scan"
	# Check for the latest virus and spyware security intelligence before running a scheduled scan (Optional)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "CheckForSignaturesBeforeRunningScan"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Specify the maximum percentage of CPU utilization during a scan"
	# Specify the maximum percentage of CPU utilization during a scan (50%, Optional)
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "AvgCPULoadFactor"
	$Value = 50
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Turn on heuristics"
	# Turn on heuristics (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisableHeuristics"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Turn on e-mail scanning"
	# Turn on e-mail scanning (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisableEmailScanning"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Scan packed executables"
	# Scan packed executables (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisablePackedExeScanning"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Scan removable drives"
	# Scan removable drives (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisableRemovableDriveScanning"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Scan network files"
	# Scan network files (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisableScanningNetworkFiles"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Scan archive files"
	# Scan archive files (Optional)
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "DisableArchiveScanning"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Specify the maximum depth to scan archive files"
	# Specify the maximum depth to scan archive files (Optional)
	# The default directory depth level is 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"
	$ValueName = "ArchiveMaxDepth"
	$Value = 5
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Security Intelligence Updates
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Microsoft Defender Antivirus\Security Intelligence Updates
	#

	Write-Information -MessageData "INFO: Check for the latest virus and spyware security intelligence on startup"
	# Check for the latest virus and spyware security intelligence on startup (Optional)
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Signature Updates"
	$ValueName = "UpdateOnStartUp"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	# Update changes done to registry
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Disconnect-Computer -Domain $PolicyStore
Update-Log

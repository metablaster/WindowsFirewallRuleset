
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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

.VERSION 0.16.1

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

.PARAMETER SkipDefault
If specified does not explicitly set GPO settings which are already set for enhanced security by default.
If GPO is already misconfigured or settings not trusted then do not use this switch to ensure integrity

.PARAMETER IncludeOptional
If specified, optional security related GPO settings are configured which are otherwise not essential for ATP
If an optional setting is the default and you use SkipDefault switch, then the optional setting won't be modified

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
ATP (Advanced Thread Protection) is how it was called before, it seems now this is called
"cloud protection" or "next generation protection", it's based on MAPS
TODO: There are some exotic options for Set-MpPreference which we don't use
TODO: A script is needed to reset ATP modification to system defaults
TODO: More options can be configured
TODO: Need to exclude settings which don't apply to target computer
NOTE: Comments with (optional) indicate a setting is not ATP setting

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference

.LINK
https://learn.microsoft.com/en-us/windows/security/zero-trust-windows-device-health

.LINK
https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint

.LINK
https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/next-generation-protection

.LINK
https://gpsearch.azurewebsites.net

.LINK
https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter()]
	[switch] $SkipDefault,

	[Parameter()]
	[switch] $IncludeOptional,

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
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Spynet"

	Write-Information -MessageData "INFO: Join Microsoft MAPS"
	# Join Microsoft MAPS (Advanced MAPS)
	# decimal: 0 => Disabled
	# decimal: 1 => Basic MAPS
	# decimal: 2 => Advanced MAPS
	# Default: Not Configured, configurable in Windows Security app
	$ValueName = "SpynetReporting"
	$Value = 2
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Send file samples when further analysis is required"
	# Send file samples when further analysis is required (Send safe samples)
	# decimal: 0 => Always prompt
	# decimal: 1 => Send safe samples
	# decimal: 2 => Never send
	# decimal: 3 => Send all samples
	# Default: Not Configured, configurable in Windows Security app
	$ValueName = "SubmitSamplesConsent"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Configure the 'Block at First Sight' feature"
	# Configure the "Block at First Sight" feature (Enabled)
	# NOTE: This feature requires four other settings to be enabled:
	# 1. "Join Microsoft MAPS"
	# 2. "Send file samples when further analysis is required (option 1 or 3)"
	# 3. "Scan all downloaded files and attachments"
	# 4. "Real time protection - do not enable 'turn off real time protection'"
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	# Default: Not Configured
	$ValueName = "DisableBlockAtFirstSeen"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Real-time protection
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Real-time Protection
	#
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Real-Time Protection"

	Write-Information -MessageData "INFO: Scan all downloaded files and attachments"
	# Scan all downloaded files and attachments (Enabled)
	# NOTE: "Enabled" is same as "Not Configured" but "Block at First Sight" specifies
	# it must be enabled therefore not handled by SkipDefault switch
	# Enabled Value: decimal: 0
	# Disabled Value: decimal: 1
	# Default: Not Configured, same as Enabled
	$ValueName = "DisableIOAVProtection"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	if (!$SkipDefault)
	{
		Write-Information -MessageData "INFO: Turn off realtime protection"
		# Turn off real-time protection (Disabled)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# Default: Not Configured, same as Disabled
		$ValueName = "DisableRealtimeMonitoring"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
	}

	if ($IncludeOptional)
	{
		if (!$SkipDefault)
		{
			Write-Information -MessageData "INFO: Turn on behavioral monitoring"
			# Turn on behavioral monitoring (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableBehaviorMonitoring"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			Write-Information -MessageData "INFO: Monitor file and program activity on your computer"
			# Monitor file and program activity on your computer (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableOnAccessProtection"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			Write-Information -MessageData "INFO: Turn on process scanning whenever real-time protection is enabled"
			# Turn on process scanning whenever real-time protection is enabled (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableScanOnRealtimeEnable"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			# TODO: DisableScriptScanning will also appear in Scan subdirectory in registry, why?
			# Test on fresh system to confirm is by design or bug
			Write-Information -MessageData "INFO: Turn on script scanning"
			# Turn on script scanning (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableScriptScanning"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
		}
	}

	#
	# mpengine
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\mpengine
	#
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\MpEngine"

	if ($IncludeOptional)
	{
		Write-Information -MessageData "INFO: Enable file hash computation feature"
		# Enable file hash computation feature (Optional)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# Default: Not Configured, same as Disabled
		$ValueName = "EnableFileHashComputation"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
	}

	Write-Information -MessageData "INFO: Configure extended cloud check"
	# Configure extended cloud check (50 max)
	# This feature allows Microsoft Defender Antivirus to block a suspicious file for up to X seconds, and scan it in the cloud to make sure it's safe.
	# NOTE: This feature depends on three other MAPS settings:
	# 1. "Configure the 'Block at First Sight' feature"
	# 2. "Join Microsoft MAPS"
	# 3. "Send file samples when further analysis is required"
	# Default: Not Configured
	$ValueName = "MpBafsExtendedTimeout"
	$Value = 50
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	Write-Information -MessageData "INFO: Select cloud protection level"
	# Select cloud protection level (High blocking level)
	# NOTE: This feature requires the "Join Microsoft MAPS"
	# decimal: 0 => Default blocking level
	# decimal: 1 => Moderate blocking level
	# decimal: 2 => High blocking level
	# decimal: 4 => High+ blocking level
	# decimal: 6 => Zero tolerance blocking level
	# Default: Not Configured
	$ValueName = "MpCloudBlockLevel"
	$Value = 2
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Attack Surface Reduction
	# Configure Attack Surface Reduction rules
	# Handled by Deploy-ASR script

	#
	# Microsoft Defender Exploit Guard
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Network Protection
	#
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection"

	Write-Information -MessageData "INFO: Prevent users and apps from accessing dangerous websites"
	# Prevent users and apps from accessing dangerous websites (Block)
	# decimal: 0 => Disable (Default)
	# decimal: 1 => Block
	# decimal: 2 => Audit Mode
	# Default: Not Configured, same as Disabled
	$ValueName = "EnableNetworkProtection"
	$Value = 1
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# Scan
	# GPO: Computer configuration\Administrative templates\Windows Components\Microsoft Defender Antivirus\Scan
	#
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Scan"

	if ($IncludeOptional)
	{
		Write-Information -MessageData "INFO: Check for the latest virus and spyware security intelligence before running a scheduled scan"
		# Check for the latest virus and spyware security intelligence before running a scheduled scan (Optional)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# Default: Not Configured, same as Disabled
		$ValueName = "CheckForSignaturesBeforeRunningScan"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Specify the maximum percentage of CPU utilization during a scan"
		# Specify the maximum percentage of CPU utilization during a scan (50%, Optional)
		# Default: Not Configured, same as Disabled
		$ValueName = "AvgCPULoadFactor"
		$Value = 50
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: CPU Throttling type"
		# CPU Throttling type (Optional)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# If you disable this setting, CPU throttling will apply to scheduled and custom scans
		# Default: Not Configured, same as Enabled
		$ValueName = "ThrottleForScheduledScanOnly"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Turn on e-mail scanning"
		# Turn on e-mail scanning (Optional)
		# Enabled Value: decimal: 0
		# Disabled Value: decimal: 1
		# Default: Not Configured, same as Disabled
		$ValueName = "DisableEmailScanning"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Scan removable drives"
		# Scan removable drives (Optional)
		# Enabled Value: decimal: 0
		# Disabled Value: decimal: 1
		# Default: Not Configured, same as Disabled
		$ValueName = "DisableRemovableDriveScanning"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Scan network files"
		# Scan network files (Optional)
		# Enabled Value: decimal: 0
		# Disabled Value: decimal: 1
		# Default: Not Configured, same as Disabled
		$ValueName = "DisableScanningNetworkFiles"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Specify the maximum depth to scan archive files"
		# Specify the maximum depth to scan archive files (Optional)
		# The default directory depth level is 0
		# Default: Not Configured, same as Disabled
		$ValueName = "ArchiveMaxDepth"
		$Value = 10
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		if (!$SkipDefault)
		{
			Write-Information -MessageData "INFO: Turn on heuristics"
			# Turn on heuristics (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableHeuristics"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			Write-Information -MessageData "INFO: Scan packed executables"
			# Scan packed executables (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisablePackedExeScanning"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			Write-Information -MessageData "INFO: Scan archive files"
			# Scan archive files (Optional)
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableArchiveScanning"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
		}

		#
		# Scan status configured here can be viewed in event viewer in the following location:
		# Event Viewer -> Application and Services Logs -> Microsoft -> Windows -> Windows Defender -> Operational
		#
		# The event 1151 will tell if and how a scan was initiated and it's completion status, decipher output from the link below:
		# https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide#event-id-1151
		#
		# Example:
		# Last quick scan source: Last quick scan source (0 = scan didn't run, 1 = user initiated, 2 = system initiated)
		# Last full scan source: Last full scan source (0 = scan didn't run, 1 = user initiated, 2 = system initiated)
		#
		# It must be 2 (system initiated), indicating these settings work, example output:
		# Last full scan start time: 2023-11-28T09:13:21Z
		# Last full scan end time: 2023-11-28T16:34:43Z
		# Last full scan source: 2
		#

		#
		# Quick scan settings
		#

		# Quick scan and signature updates interval (every x hours)
		$DefaultInterval = 24 # Every 24h

		# Time when full scan starts, also used to calculate when to update AV prior full scan
		# and also use to calculate daily quick scan start time
		# NOTE: According to current settings full scan will run once a week if computer is not in
		# use at 10 AM, to make full scan once a month change this value to when computer is always turned off
		$ScheduledTime = 600 # 10AM

		# It doesn't make sense to have both quick scan settings enabled
		if ($true)
		{

			Write-Information -MessageData "INFO: Specify the time for a daily quick scan"
			# Specify the time for a daily quick scan (Optional)
			# decimal: Minutes past the midnight (default = 120, 2AM)
			# Default: Not Configured, same as Disabled
			$ValueName = "ScheduleQuickScanTime"
			# NOTE: Because Scheduled scan is set to start at 10 AM, then assuming it will take some 10h,
			# quick scan should not start during full scan but at least 10h later
			$Value = $ScheduledTime + 600 # 10h after full scan was started or 8PM
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
		}
		else
		{
			# TODO: What happens if interval is triggered during a full scan, could it interfere somehow with full scan?
			# Example, stopping it or even worse restarting the full scan?
			# NOTE: According to event viewer a quick scan will run as soon as scheduled full scan was finished
			Write-Information -MessageData "INFO: Specify the interval to run quick scans per day"
			# Specify the interval to run quick scans per day (Optional)
			# decimal: 0 (default) [the number of hours between quick scans, 0 = no quick scan interval]
			# Default: Not Configured, same as Disabled
			$ValueName = "QuickScanInterval"
			$Value = $DefaultInterval
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
		}

		#
		# Scheduled scan settings (used to automate full scans at least once a month)
		# TODO: Figure out how to stop scheduled scan
		#

		Write-Information -MessageData "INFO: Specify the scan type to use for a scheduled scan"
		# Specify the scan type to use for a scheduled scan (Optional)
		# decimal: 1 = Quick Scan (default)
		# decimal: 2 = Full Scan
		# Default: Not Configured, same as Disabled
		$ValueName = "ScanParameters"
		$Value = 2
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Specify the day of the week to run a scheduled scan"
		# Specify the day of the week to run a scheduled scan (Optional)
		# decimal: 8 => Never (default)
		# decimal: 0 => Every Day
		# decimal: 1 => Sunday
		# decimal: 2 => Monday
		# decimal: 3 => Tuesday
		# decimal: 4 => Wednesday
		# decimal: 5 => Thursday
		# decimal: 6 => Friday
		# decimal: 7 => Saturday
		# Default: Not Configured, same as Disabled
		$ValueName = "ScheduleDay"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Specify the time of day to run a scheduled scan"
		# Specify the time of day to run a scheduled scan (Optional)
		# decimal: Minutes past the midnight (default = 120, 2AM)
		# Default: Not Configured, same as Disabled
		$ValueName = "ScheduleTime"
		$Value = $ScheduledTime
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		# NOTE: This is set to enabled (1) to make full scan run once per month assuming computer is always in use at scheduled time
		Write-Information -MessageData "INFO: Start the scheduled scan only when computer is on but not in use"
		# Start the scheduled scan only when computer is on but not in use (Optional)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# Default: Not Configured, same as Enabled
		$ValueName = "ScanOnlyIfIdle"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Define the number of days after which a catch-up scan is forced"
		# Define the number of consecutive scheduled scans that can be missed after which a catch-up scan will be forced (Optional)
		# decimal: 2 (default)
		# Default: Not Configured, same as Disabled
		$ValueName = "MissedScheduledScanCountBeforeCatchup"
		$Value = 4 # 1 month maximum
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
	} # if ($IncludeOptional)

	#
	# Security Intelligence Updates
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Microsoft Defender Antivirus\Security Intelligence Updates
	#
	$RegistryPath = "Software\Policies\Microsoft\Windows Defender\Signature Updates"

	if ($IncludeOptional)
	{
		Write-Information -MessageData "INFO: Check for the latest virus and spyware security intelligence on startup"
		# Check for the latest virus and spyware security intelligence on startup (Optional)
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		# Default: Not Configured, same as Disabled
		$ValueName = "UpdateOnStartUp"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Define the number of days before spyware security intelligence is considered out of date"
		# Define the number of days before spyware security intelligence is considered out of date (Optional)
		# decimal: 7 (default)
		# Default: Not Configured, same as Disabled
		$ValueName = "ASSignatureDue"
		$Value = 2
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Define the number of days before virus security intelligence is considered out of date"
		# Define the number of days before virus security intelligence is considered out of date (Optional)
		# decimal: 7 (default)
		# Default: Not Configured, same as Disabled
		$ValueName = "AVSignatureDue"
		$Value = 2
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		if (!$SkipDefault)
		{
			# HACK: What is "automatic" scan? if it's scheduled scan then it's a problem if scheduled scan is full scan and is already running?
			Write-Information -MessageData "INFO: Turn on scan after security intelligence update"
			# Turn on scan after security intelligence update (Optional)
			# This policy setting allows you to configure the automatic scan which starts after a security intelligence update has occurred.
			# Enabled Value: decimal: 0
			# Disabled Value: decimal: 1
			# Default: Not Configured, same as Enabled
			$ValueName = "DisableScanOnUpdate"
			$Value = 0
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

			Write-Information -MessageData "INFO: Allow real-time security intelligence updates based on reports to Microsoft MAPS"
			# Allow real-time security intelligence updates based on reports to Microsoft MAPS (Optional)
			# Enabled Value: decimal: 1
			# Disabled Value: decimal: 0
			# Default: Not Configured, same as Enabled
			$ValueName = "RealtimeSignatureDelivery"
			$Value = 1
			$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
			Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
		}

		# NOTE: Not under $SkipDefault block because the default might be changed here
		Write-Information -MessageData "INFO: Specify the day of the week to check for security intelligence updates"
		# Specify the day of the week to check for security intelligence updates (Optional)
		# decimal: 8 => Never
		# decimal: 0 => Every Day (Default)
		# decimal: 1 => Sunday
		# decimal: 2 => Monday
		# decimal: 3 => Tuesday
		# decimal: 4 => Wednesday
		# decimal: 5 => Thursday
		# decimal: 6 => Friday
		# decimal: 7 => Saturday
		# Default: Not Configured, same as Disabled
		$ValueName = "ScheduleDay"
		$Value = 0
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		Write-Information -MessageData "INFO: Specify the time to check for security intelligence updates"
		# Specify the time to check for security intelligence updates (Optional)
		# decimal: Minutes past the midnight (default = 15 minutes before the scheduled scan time)
		# Default: Not Configured, same as Disabled
		$ValueName = "ScheduleTime"
		$Value = $ScheduledTime - 15
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		# HACK: Could new intelligence update trigger another full scan if full scan is already running?
		Write-Information -MessageData "INFO: Specify the interval to check for security intelligence updates"
		# Specify the interval to check for security intelligence updates (Optional)
		# The default value could be 24 based on "Specify the day of the week to check for security intelligence updates"
		# decimal: The number of hours between update checks (1-24)
		# Default: Not Configured, same as Disabled
		$ValueName = "SignatureUpdateInterval"
		$Value = $DefaultInterval
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

		# NOTE: Not under $SkipDefault block because the default might be changed here
		Write-Information -MessageData "INFO: Define the number of days after which a catch-up security intelligence update is required"
		# Define the number of days after which a catch-up security intelligence update is required (Optional)
		# decimal: 1 (default)
		# Default: Not Configured, same as Disabled
		$ValueName = "SignatureUpdateCatchupInterval"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
	}

	# Update changes done to registry
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Disconnect-Computer -Domain $PolicyStore
Update-Log

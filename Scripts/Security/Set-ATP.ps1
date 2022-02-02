
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

.VERSION 0.12.0

.GUID 181dea4a-4658-425e-904e-5f22f886af89

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Set advanced threat protection settings

.DESCRIPTION
Use Set-ATP.ps1 to configure Microsoft Defender Antivirus.

.EXAMPLE
PS> .\Set-ATP.ps1

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
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param ()

if ($PSCmdlet.ShouldProcess("GPO", "Configure Microsoft Defender Antivirus"))
{
	# Block at first sight (MAPS)
	Set-MpPreference -SubmitSamplesConsent 3 -MAPSReporting Basic -DisableBlockAtFirstSeen $false `
		-DisableIOAVProtection $false -DisableRealtimeMonitoring $false

	# Cloud protection
	# https://docs.microsoft.com/en-us/graph/api/resources/intune-deviceconfig-defendercloudblockleveltype
	Set-MpPreference -CloudExtendedTimeout 50 -CloudBlockLevel high -EnableFileHashComputation $true

	# Scan
	Set-MpPreference -ScanAvgCPULoadFactor 60 -ScanScheduleDay Sunday -ScanScheduleTime 900 `
		-CheckForSignaturesBeforeRunningScan $true -ScanParameters QuickScan `
		-DisableBehaviorMonitoring $false `
		-DisableScriptScanning $false `
		-DisableArchiveScanning $false `
		-DisableCatchupFullScan $false `
		-DisableCatchupQuickScan $false `
		-DisableEmailScanning $false `
		-DisableRemovableDriveScanning $true `
		-DisableRestorePoint $true `
		-DisableScanningMappedNetworkDrivesForFullScan $true `
		-DisableScanningNetworkFiles $true
}

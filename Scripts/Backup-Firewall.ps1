
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

<#PSScriptInfo

.VERSION 0.10.1

.GUID bdaf45b1-a6cf-48b8-a87d-cde4f30eb574

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Export all firewall rules and settings

.DESCRIPTION
Backup-Firewall.ps1 script exports all GPO firewall rules and settings to "Exports" directory

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Backup-Firewall.ps1

.INPUTS
None. You cannot pipe objects to Backup-Firewall.ps1

.OUTPUTS
None. Backup-Firewall.ps1 does not generate any output

.NOTES
TODO: Exporting settings not implemented
TODO: OutputType attribute

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
Initialize-Project -Strict

# User prompt
$Accept = "Accpet exporting firewall rules and settings to file"
$Deny = "Abort operation, no firewall rules or settings will be exported"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

# NOTE: export speed is 10 rules per minute
# 450 rules in 46 minutes on 3,6 Ghz quad core CPU with 16GB single channel RAM @2400 Mhz
# NOTE: to speed up a little add following to defender exclusions:
# C:\Windows\System32\wbem\WmiPrvSE.exe
# TODO: function to export firewall settings needed
# TODO: need to speed up rule export by at least 700%
$StopWatch = [System.Diagnostics.Stopwatch]::new()

$StopWatch.Start()
# Export all outbound rules from GPO
Export-FirewallRule -Outbound -Folder "$ProjectRoot\Exports" -FileName "OutboundGPO" -PolicyStore $PolicyStore
$StopWatch.Stop()

$OutboundHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
$OutboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to export outbound rules was: $OutboundHours hours and $OutboundMinutes minutes"

$StopWatch.Reset()
$StopWatch.Start()
# Export all inbound rules from GPO
Export-FirewallRule -Inbound -Folder "$ProjectRoot\Exports" -FileName "InboundGPO" -PolicyStore $PolicyStore
$StopWatch.Stop()

$InboundHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
$InboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to export inbound rules was: $InboundHours hours and  $InboundMinutes minutes"

$TotalMinutes = $OutboundMinutes + $InboundMinutes
$TotalMinutes += $OutboundHours * 60
$TotalMinutes += $InboundHours * 60
Write-Information -Tags "User" -MessageData "INFO: Total time needed to export entry firewall was: $TotalMinutes minutes"

Update-Log

<# STATS
Outbound export took over 1h and the result was 1 minute
Time needed to export inbound rules was: 33 minutes
Total time needed to export entry firewall was: 34 minutes (1h 34m)
#>

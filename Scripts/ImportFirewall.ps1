
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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

#
# Import all previously exported firewall rules
#
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $Context $ThisScript @Logs
if (!(Approve-Execute @Logs)) { exit }

# NOTE: import speed is 26 rules per minute, slowed down by "Test-TargetComputer" for store app rules
# 450 rules in 17 minutes on 3,6 Ghz quad core CPU with 16GB single channel RAM @2400 Mhz
# NOTE: to speed up a little add following to defender exclusions:
# C:\Windows\System32\wbem\WmiPrvSE.exe
# TODO: function to import firewall settings needed
# TODO: need to speed up rule import by at least 300%
$StopWatch = [System.Diagnostics.Stopwatch]::new()

$StopWatch.Start()
# Import all outbound rules to GPO
Import-FirewallRules -Folder "$ProjectRoot\Exports" -FileName "OutboundGPO" -PolicyStore $PolicyStore @Logs
$StopWatch.Stop()

$OutboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to import outbound rules was: $OutboundMinutes minutes"

$StopWatch.Reset()
$StopWatch.Start()
# Import all inbound rules from GPO
Import-FirewallRules -Folder "$ProjectRoot\Exports" -FileName "InboundGPO" -PolicyStore $PolicyStore @Logs
$StopWatch.Stop()

$InboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to import inbound rules was: $InboundMinutes minutes"

# Update Local Group Policy for changes to take effect
gpupdate.exe

$TotalMinutes = $OutboundMinutes + $InboundMinutes
Write-Information -Tags "User" -MessageData "INFO: Total time needed to import entry firewall was: $TotalMinutes minutes"
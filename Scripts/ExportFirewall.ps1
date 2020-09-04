
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
# Export all firewall rules
#
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Setup local variables
$Accept = "Accpet exporting firewall rules and settings to file"
$Deny = "Skip operation, no firewall rules or settings will be exported"

# User prompt
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# NOTE: export speed is 10 rules per minute
# 450 rules in 46 minutes on 3,6 Ghz quad core CPU with 16GB single channel RAM @2400 Mhz
# NOTE: to speed up a little add following to defender exclusions:
# C:\Windows\System32\wbem\WmiPrvSE.exe
# TODO: function to export firewall settings needed
# TODO: need to speed up rule export by at least 700%
$StopWatch = [System.Diagnostics.Stopwatch]::new()

$StopWatch.Start()
# Export all outbound rules from GPO
Export-FirewallRules -Outbound -Folder "$ProjectRoot\Exports" -FileName "OutboundGPO" -PolicyStore $PolicyStore @Logs
$StopWatch.Stop()

$OutboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to export outbound rules was: $OutboundMinutes minutes"

$StopWatch.Reset()
$StopWatch.Start()
# Export all inbound rules from GPO
Export-FirewallRules -Inbound -Folder "$ProjectRoot\Exports" -FileName "InboundGPO" -PolicyStore $PolicyStore @Logs
$StopWatch.Stop()

$InboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
Write-Information -Tags "User" -MessageData "INFO: Time needed to export inbound rules was: $InboundMinutes minutes"

$TotalMinutes = $OutboundMinutes + $InboundMinutes
Write-Information -Tags "User" -MessageData "INFO: Total time needed to export entry firewall was: $TotalMinutes minutes"

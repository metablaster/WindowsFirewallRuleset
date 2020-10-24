
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

<#
.SYNOPSIS
Import all previously exported firewall rules
.DESCRIPTION
ImportFirewall script imports all firewall rules that were previously
exported with ExportFirewall.ps1 script
.EXAMPLE
PS> ImportFirewall.ps1
.INPUTS
None.
.OUTPUTS
None.
.NOTES
None.
#>

#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Setup local variables
$Accept = "Accpet importing firewall rules and settings from file"
$Deny = "Abort operation, no firewall rules or settings will be imported"

# User prompt
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# NOTE: import speed is 26 rules per minute, slowed down by "Test-TargetComputer" for store app rules
# 450 rules in 17 minutes on 3,6 Ghz quad core CPU with 16GB single channel RAM @2400 Mhz
# NOTE: to speed up a little add following to defender exclusions:
# C:\Windows\System32\wbem\WmiPrvSE.exe
# TODO: function to import firewall settings needed
# TODO: need to speed up rule import by at least 300%
$StopWatch = [System.Diagnostics.Stopwatch]::new()

$FilePath = "$ProjectRoot\Exports\OutboundGPO.csv"
# TODO: file existence checks such as this one, there should be utility function for this
if (!(Test-Path -Path $FilePath -PathType Leaf))
{
	Write-Error -Category ObjectNotFound -TargetObject $FilePath `
		-Message "Cannot find path '$FilePath' because it does not exist"
}
else
{
	$StopWatch.Start()
	# Import all outbound rules to GPO
	Import-FirewallRules -Folder "$ProjectRoot\Exports" -FileName "OutboundGPO.csv" -PolicyStore $PolicyStore @Logs
	$StopWatch.Stop()

	$OutboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
	Write-Information -Tags "User" -MessageData "INFO: Time needed to import outbound rules was: $OutboundMinutes minutes"
}

$StopWatch.Reset()

$FilePath = "$ProjectRoot\Exports\InboundGPO.csv"
if (!(Test-Path -Path $FilePath -PathType Leaf))
{
	Write-Error -Category ObjectNotFound -TargetObject $FilePath `
		-Message "Cannot find path '$FilePath' because it does not exist"
}
else
{
	$StopWatch.Start()
	# Import all inbound rules from GPO
	Import-FirewallRules -Folder "$ProjectRoot\Exports" -FileName "InboundGPO" -PolicyStore $PolicyStore @Logs
	$StopWatch.Stop()

	$InboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
	Write-Information -Tags "User" -MessageData "INFO: Time needed to import inbound rules was: $InboundMinutes minutes"
}

if ((Get-Variable -Name OutboundMinutes -EA Ignore) -or (Get-Variable -Name InboundMinutes -EA Ignore))
{
	# Update Local Group Policy for changes to take effect
	gpupdate.exe

	$TotalMinutes = 0

	if ($OutboundMinutes)
	{
		$TotalMinutes += $OutboundMinutes
	}

	if ($InboundMinutes)
	{
		$TotalMinutes += $InboundMinutes
	}

	Write-Information -Tags "User" -MessageData "INFO: Total time needed to import entry firewall was: $TotalMinutes minutes"
}


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

.VERSION 0.9.1

.GUID 705cd3b9-ff1f-452d-bd44-09ed8e26a70d

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Restore previously saved firewall rules and configuration

.DESCRIPTION
Restore-Firewall script imports all firewall rules and configuration that were previously exported
with Backup-Firewall.ps1

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Restore-Firewall.ps1

.INPUTS
None. You cannot pipe objects to Restore-Firewall.ps1

.OUTPUTS
None. Restore-Firewall.ps1 does not generate any output

.NOTES
TODO: OutputType attribute

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
Initialize-Project -Strict

# User prompt
$Accept = "Accpet importing firewall rules and settings from file"
$Deny = "Abort operation, no firewall rules or settings will be imported"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

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
	Import-FirewallRule -Folder "$ProjectRoot\Exports" -FileName "OutboundGPO.csv" -PolicyStore $PolicyStore
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
	Import-FirewallRule -Folder "$ProjectRoot\Exports" -FileName "InboundGPO" -PolicyStore $PolicyStore
	$StopWatch.Stop()

	$InboundMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
	Write-Information -Tags "User" -MessageData "INFO: Time needed to import inbound rules was: $InboundMinutes minutes"
}

if ((Get-Variable -Name OutboundMinutes -EA Ignore) -or (Get-Variable -Name InboundMinutes -EA Ignore))
{
	# Update Local Group Policy for changes to take effect
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"

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

Update-Log

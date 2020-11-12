
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
Capture network traffic

.DESCRIPTION
Start capturing network traffic into an *.etl file for analysis.
The file can be analyzed with "Windows performance analyzer", available in Windows SDK

.PARAMETER Protocol
1 ICMPv4
2 IGMP
6 TCP
16 UDP
58 ICMPv6
https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers

.PARAMETER Level
0x5 Verbose
0x4 Informational
0x3 Warning
0x2 Error
0x1 Critical
0x0 LogAlways

.PARAMETER Name
Session name, also implies name of a file

.PARAMETER WFP
If specified captures Windows Firewall Platform (WFP) network events

.EXAMPLE
PS> .\StartTrace.ps1 Protocol -6 -Level 4

Captures TCP traffic up to informational level

.INPUTS
None. You cannot pipe objects to StartTrace.ps1

.OUTPUTS
None. StartTrace.ps1 does not generate any output

.NOTES
None.
#>

#region Script header
[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Protocol")]
param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Protocol")]
	[ValidateRange(1, 255)]
	[byte[]] $Protocol,

	[Parameter()]
	[ValidateRange(0, 5)]
	[byte] $Level = 0x4,

	[Parameter()]
	[string] $Name = "TrafficDump",

	[Parameter(ParameterSetName = "Protocol")]
	[ValidateSet("Physical", "Switch", "BothPhysicalAndSwitch")]
	[string] $CaptureType = "BothPhysicalAndSwitch",

	[Parameter()]
	[ValidatePattern("(([0-9]{1,3}\.){3}[0-9]{1,3})|(([a-f0-9:]+:)+[a-f0-9]+)")]
	[string[]] $IPAddresses,

	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "WFP")]
	[ValidateSet("IPv4Inbound", "IPv4Outbound", "IPv6Inbound", "IPv6Outbound", "All")]
	[string[]] $LayerSet,

	[Parameter(ParameterSetName = "WFP")]
	[uint16[]] $TCPPorts,

	[Parameter(ParameterSetName = "WFP")]
	[uint16[]] $UDPPorts
)

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
$Accept = "Start capturing network traffic into a file for analysis"
$Deny = "Abort operation, no capture is started"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

if (!(Test-Path -Path $LogsFolder\Audit -PathType Container))
{
	Write-Information -Tags "User" -MessageData "INFO: Creating output folder"
	New-Item -Path $LogsFolder\Audit -ItemType Container | Out-Null
}

Write-Information -Tags "User" -MessageData "INFO: Creating new session '$Name'"

# File size in megabytes, buffer (memory) size in kilobytes
New-NetEventSession -Name $Name -CaptureMode SaveToFile -LocalFilePath $LogsFolder\Audit\$Name.etl `
	-MaxFileSize 10 -TraceBufferSize 1024 @Logs

[hashtable] $Params = @{SessionName = $Name; Level = $Level }

if ($null -ne $LayerSet)
{
	Write-Information -Tags "User" -MessageData "INFO: Adding WFP capture provider"

	if ($LayerSet -eq "All")
	{
		$Params.Add("CaptureLayerSet", @(
				"IPv4Inbound"
				"IPv4Outbound"
				"IPv6Inbound"
				"IPv6Outbound"
			))
	}
	else
	{
		$Params.Add("CaptureLayerSet", $LayerSet)
	}

	if ($IPAddresses)
	{
		$Params.Add("IPAddresses", $IPAddresses)
	}

	if ($TCPPorts)
	{
		$Params.Add("TCPPorts", $TCPPorts)
	}

	if ($UDPPorts)
	{
		$Params.Add("UDPPorts", $UDPPorts)
	}

	Add-NetEventWFPCaptureProvider @Params @Logs
}
else
{
	Write-Information -Tags "User" -MessageData "INFO: Adding packet capture provider"

	Add-NetEventProvider -Name "Microsoft-Windows-TCPIP" @Params @Logs

	$Params.Add("CaptureType", $CaptureType)

	if ($IPAddresses)
	{
		$Params.Add("IPAddresses", $IPAddresses)
	}

	# -TruncationLength default = 128
	Add-NetEventPacketCaptureProvider -CaptureType BothPhysicalAndSwitch -IpProtocols $Protocol `
		-TruncationLength 128 @Params @Logs
}

Write-Information -Tags "User" -MessageData "INFO: Starting session '$Name'"

Start-NetEventSession -Name $Name @Logs

Update-Log

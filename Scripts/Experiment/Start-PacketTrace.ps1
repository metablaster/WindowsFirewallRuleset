
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

.VERSION 0.11.0

.GUID 1d12c983-4d53-4952-9cc6-281467032fc2

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Capture network traffic

.DESCRIPTION
Start capturing network traffic into an *.etl file for analysis.
The file can be analyzed with "Windows performance analyzer", available in Windows SDK

.PARAMETER Protocol
Specifies an array of one or more IP protocols, such as TCP or UDP, on which to filter.
The packet capture provider logs network traffic that matches this filter.

1 ICMPv4
2 IGMP
6 TCP
16 UDP
58 ICMPv6
https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers

.PARAMETER Level
Specifies the level of Event Tracing for Windows (ETW) events for the provider.
Use the level of detail for the event to filter the events that are logged.

0x5 Verbose
0x4 Informational
0x3 Warning
0x2 Error
0x1 Critical
0x0 LogAlways

.PARAMETER Name
Session name, also implies name of a file

.PARAMETER CaptureType
Specifies whether the packet capture is enabled for physical network adapters, virtual switches, or both.

.PARAMETER IPAddresses
Specifies an array of IP addresses.
The provider logs network traffic that matches the addresses that this cmdlet specifies

.PARAMETER LayerSet
If specified, captures Windows Firewall Platform (WFP) network events

.PARAMETER TCPPorts
Specifies an array of TCP ports.
The provider filters for and logs network traffic that matches the ports that this parameter specifies.

.PARAMETER UDPPorts
Specifies an array of UDP ports.
The provider filters for and logs network traffic that matches the ports that this parameter specifies.

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Start-PacketTrace.ps1 6 -Level 3

Captures TCP traffic up to Warning level

.EXAMPLE
PS> .\Start-PacketTrace.ps1 1, 58

Captures ICMP traffic for both IPv4 and IPv6

.EXAMPLE
PS> .\Start-PacketTrace.ps1 -LayerSet "IPv4Outbound" -TCPPorts 443

Captures Outbound IPv4 traffic to remote port 443, at WFP level

.INPUTS
None. You cannot pipe objects to Start-PacketTrace.ps1

.OUTPUTS
None. Start-PacketTrace.ps1 does not generate any output

.NOTES
Unlike a Packet Capture provider, the WFP capture provider captures network traffic above the IP layer.
TODO: WFP capture doesn't work because:
"A general error occurred that is not covered by a more specific error code"
TODO: More parameters could be customized, see links for more info
TODO: OutputType attribute

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/neteventpacketcapture/new-neteventsession?view=win10-ps

.LINK
https://docs.microsoft.com/en-us/powershell/module/neteventpacketcapture/add-neteventpacketcaptureprovider?view=win10-ps

.LINK
https://docs.microsoft.com/en-us/powershell/module/neteventpacketcapture/add-neteventwfpcaptureprovider?view=win10-ps

.LINK
https://docs.microsoft.com/en-us/powershell/module/neteventpacketcapture/add-neteventprovider?view=win10-ps
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Protocol")]
param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Protocol")]
	[ValidateRange(0, 255)]
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
	[uint16[]] $UDPPorts,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

# User prompt
$Accept = "Start capturing network traffic into a file for analysis"
$Deny = "Abort operation, no capture is started"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if (!(Test-Path -Path $LogsFolder\Audit -PathType Container))
{
	Write-Information -Tags $ThisScript -MessageData "INFO: Creating output folder"
	New-Item -Path $LogsFolder\Audit -ItemType Container | Out-Null
}

Write-Information -Tags $ThisScript -MessageData "INFO: Creating new session '$Name'"

# File size in megabytes, buffer (memory) size in kilobytes
New-NetEventSession -Name $Name -CaptureMode SaveToFile -LocalFilePath $LogsFolder\Audit\$Name.etl `
	-MaxFileSize 10 -TraceBufferSize 1024

[hashtable] $Params = @{SessionName = $Name; Level = $Level }

if ($null -ne $LayerSet)
{
	Write-Information -Tags $ThisScript -MessageData "INFO: Adding WFP capture provider"

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

	Add-NetEventWFPCaptureProvider @Params
}
else
{
	Write-Information -Tags $ThisScript -MessageData "INFO: Adding packet capture provider"

	Add-NetEventProvider -Name "Microsoft-Windows-TCPIP" @Params

	$Params.Add("CaptureType", $CaptureType)

	if ($IPAddresses)
	{
		$Params.Add("IPAddresses", $IPAddresses)
	}

	# -TruncationLength default = 128
	Add-NetEventPacketCaptureProvider -IpProtocols $Protocol -TruncationLength 128 @Params
}

Write-Information -Tags $ThisScript -MessageData "INFO: Starting session '$Name'"

Start-NetEventSession -Name $Name

Update-Log

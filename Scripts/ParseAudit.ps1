
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
Get firewall auditing logs

.DESCRIPTION
Gets firewall auditing logs from event viewer and saves result to log file

.PARAMETER Direction
Get entries only for specified direction

.PARAMETER Protocol
Get entries only for specified protocol
https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers

.PARAMETER Last
Get this amount of newest entries

.PARAMETER Hours
Get entries within last hours specified

.PARAMETER EventID
Get entries for this ID only
The default is "The Windows Filtering Platform has blocked a packet"

Event ID 5146: The Windows Filtering Platform has blocked a packet
Event ID 5147: A more restrictive Windows Filtering Platform filter has blocked a packet
Event ID 5148: The Windows Filtering Platform has detected a DoS attack and entered a defensive mode; packets associated with this attack will be discarded.
Event ID 5149: The DoS attack has subsided and normal processing is being resumed.
Event ID 5150: The Windows Filtering Platform has blocked a packet.
Event ID 5151: A more restrictive Windows Filtering Platform filter has blocked a packet.
Event ID 5152: The Windows Filtering Platform blocked a packet
Event ID 5153: A more restrictive Windows Filtering Platform filter has blocked a packet
Event ID 5154: The Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections
Event ID 5155: The Windows Filtering Platform has blocked an application or service from listening on a port for incoming connections
Event ID 5156: The Windows Filtering Platform has allowed a connection
Event ID 5157: The Windows Filtering Platform has blocked a connection
Event ID 5158: The Windows Filtering Platform has permitted a bind to a local port
Event ID 5159: The Windows Filtering Platform has blocked a bind to a local port

.EXAMPLE
PS> .\ParseAudit.ps1 -Last 48
Log last 48 packet drop entries for all directions, all protocols within 24 hours

.EXAMPLE
PS> .\ParseAudit.ps1 -Hours 48 -Direction Inbound -Protocol 6
Log last 50 packet drop entries for inbound direction, UDP within 24 hours

.EXAMPLE
PS> .\ParseAudit.ps1 -Last 14 -Protocol ICMP -Hours 2
Log last 14 packet drop entries for all directions, ICMP within last 2 hours

.EXAMPLE
PS> .\ParseAudit.ps1 -Hours 48 -Direction Outbound -Protocol TCP -EventID 5159
Log last 50 blocking bind to local port entries for outbound direction, TCP protocol within 48 hours

.INPUTS
None. You cannot pipe objects to ParseAudit.ps1

.OUTPUTS
None. ParseAudit.ps1 does not generate any output

.NOTES

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/powershell/scripting/samples/Creating-Get-WinEvent-queries-with-FilterHashtable?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/windows/win32/wes/windows-event-log-reference

.LINK
https://docs.microsoft.com/en-us/archive/blogs/ashleymcglone/forensics-automating-active-directory-account-lockout-search-with-powershell-an-example-of-deep-xml-filtering-of-event-logs-across-multiple-servers-in-parallel

.LINK
https://docs.microsoft.com/en-us/windows/win32/wes/consuming-events
#>

[CmdletBinding(PositionalBinding = $false)]
param (
	[Parameter()]
	[ValidateSet("Inbound", "Outbound", "Any")]
	[string] $Direction = "Any",

	[Parameter()]
	[ValidatePattern("^TCP|UDP|ICMP|IGMP|ICMPv6|IPv6|Any|\b([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\b$")]
	[string] $Protocol = "Any",

	[Parameter()]
	[uint32] $Last = 50,

	[Parameter()]
	[uint32] $Hours = 24,

	[Parameter()]
	[ValidateRange(5146, 5159)]
	[uint32] $EventID = 5152
)

#region Initialization
#Requires -Version 5.1
#requires -PSEdition Desktop
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
$Accept = "Parse firewall auditing entries from event viewer and write to log file"
$Deny = "Abort operation"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# Setup local variables
$Date = (Get-Date).AddHours(-$Hours)
$AuditFailure = [System.Diagnostics.Eventing.Reader.StandardEventKeywords]::AuditFailure
$Level = [System.Diagnostics.Eventing.Reader.StandardEventLevel]::LogAlways

[hashtable] $FilterHash = @{
	LogName = "Security"
	ProviderName = "Microsoft-Windows-Security-Auditing"
	Keywords = $AuditFailure.value__
	ID = $EventID
	Level = $Level.Value__
	StartTime = $Date
}

[System.Diagnostics.Eventing.Reader.EventLogRecord[]] $Events = Get-WinEvent -MaxEvents $Last -FilterHashtable $FilterHash

[string] $FileLabel = "Event"
if ($Protocol -ne "Any")
{
	$FileLabel += "_$Protocol"
}
if ($Direction -ne "Any")
{
	$FileLabel += "_$Direction"
}

[string] $EventDescription = switch ($EventID)
{
	5146 { "The Windows Filtering Platform has blocked a packet" }
	5147 { "A more restrictive Windows Filtering Platform filter has blocked a packet" }
	5148 { "The Windows Filtering Platform has detected a DoS attack and entered a defensive mode; packets associated with this attack will be discarded" }
	5149 { "The DoS attack has subsided and normal processing is being resumed." }
	5150 { "The Windows Filtering Platform has blocked a packet." }
	5151 { "A more restrictive Windows Filtering Platform filter has blocked a packet." }
	5152 { "The Windows Filtering Platform blocked a packet" }
	5153 { "A more restrictive Windows Filtering Platform filter has blocked a packet" }
	5154 { "The Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections" }
	5155 { "The Windows Filtering Platform has blocked an application or service from listening on a port for incoming connections" }
	5156 { "The Windows Filtering Platform has allowed a connection" }
	5157 { "The Windows Filtering Platform has blocked a connection" }
	5158 { "The Windows Filtering Platform has permitted a bind to a local port" }
	5159 { "The Windows Filtering Platform has blocked a bind to a local port" }
}

# Log file header to use for this script
Set-Variable -Name LogHeader -Scope Global -Value $EventDescription

$ProtocolNumber = switch ($Protocol)
{
	"Any" { $null; break }
	"ICMP" { 1; break }
	"IGMP" { 2; break }
	"UDP" { 6; break }
	"TCP" { 17; break }
	"IPv6" { 41; break }
	"ICMPv6" { 58; break }
	default { [int32] $Protocol }
}

$DevicePath = & Get-DevicePath.ps1

foreach ($Event in $Events)
{
	# Convert the event to XML
	[xml] $EventXML = $Event.ToXml()

	# https://docs.microsoft.com/en-us/previous-versions/dotnet/netframework-4.0/ms256086(v=vs.100)
	$xmlns = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $EventXML.NameTable
	$xmlns.AddNamespace("el", "http://schemas.microsoft.com/win/2004/08/events/event")
	$EventProtocol = $EventXML.SelectSingleNode("/el:Event/el:EventData/el:Data[@Name = 'Protocol']/text()", $xmlns).Value

	if (($null -ne $ProtocolNumber) -and ($EventProtocol -ne $ProtocolNumber))
	{
		continue
	}

	# Message field
	[hashtable] $Message = @{}

	# Iterate through each one of the XML message properties
	for ($Index = 0; $Index -lt $EventXML.Event.EventData.Data.Count; ++$Index)
	{
		$Name = $EventXML.Event.EventData.Data[$Index].Name
		$Value = $EventXML.Event.EventData.Data[$Index].'#text'

		$Value = switch ($Name)
		{
			"Protocol"
			{
				switch ($Value)
				{
					1 { "ICMP"; break }
					2 { "IGMP"; break }
					6 { "UDP"; break }
					17 { "TCP"; break }
					41 { "IPv6"; break }
					58 { "ICMPv6"; break }
					default { $Value }
				}
				break
			}
			"Direction"
			{
				switch ($Value)
				{
					"%%14592" { "Inbound"; break }
					"%%14593" {	"Outbound"; break }
					default { $Value }
				}
				break
			}
			"LayerName"
			{
				switch ($Value)
				{
					# TODO: Verify other entries
					"%%14610" { "Receive/Accept"; break }
					"%%14611" { "Connect"; break }
					default { $Value }
				}
				break
			}
			"Application"
			{
				$DriveLetter = $DevicePath | Where-Object {
					$Value -like "$($_.DevicePath)*"
				} | Select-Object -ExpandProperty DriveLetter

				$Value -replace "^\\device\\harddiskvolume\d+\\", "$DriveLetter\"
				break
			}
			default { $Value }
		}

		$Message[$Name] = $Value
	}

	Write-LogFile -Path $LogsFolder\Audit -Tags "Audit" -Label $FileLabel -Hash $Message
}

# Restore header to default
Set-Variable -Name LogHeader -Scope Global -Value $DefaultLogHeader

Update-Log

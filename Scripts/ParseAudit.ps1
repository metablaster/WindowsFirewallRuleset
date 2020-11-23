
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
Gets firewall auditing logs from event viewer and saves result to file

.PARAMETER Last
Get this amount of newest entries

.EXAMPLE
PS> .\ParseAudit.ps1 -Last 50

.INPUTS
None. You cannot pipe objects to ParseAudit.ps1

.OUTPUTS
None. ParseAudit.ps1 does not generate any output

.NOTES
TODO: This script is not finished

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
	[uint32] $Last,

	[Parameter()]
	[uint32] $Hours = 24

	# [Parameter()]
	# [ValidateSet("TCP", "UDP")]
	# [string] $Protocol
)

#region Initialization
#Requires -Version 5.1
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
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Abort operation, template deny help message"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# Setup local variables
$Date = (Get-Date).AddHours(-$Hours)
$AuditFailure = [System.Diagnostics.Eventing.Reader.StandardEventKeywords]::AuditFailure
$Level = [System.Diagnostics.Eventing.Reader.StandardEventLevel]::LogAlways

[System.Diagnostics.Eventing.Reader.EventLogRecord[]] $Events = Get-WinEvent -MaxEvents $Last -FilterHashtable @{
	LogName = 'Security'
	ProviderName = 'Microsoft-Windows-Security-Auditing'
	Keywords = $AuditFailure.value__
	ID = 5152 # The Windows Filtering Platform has blocked a packet
	Level = $Level.Value__
	StartTime = $Date
	# Protocol = 6
}

$File = Initialize-Log $LogsFolder\Audit -Label System

foreach ($Event in $Events)
{
	# Message field
	[hashtable] $Data = @{}

	# Convert the event to XML
	[xml] $EventXML = $Event.ToXml()

	# NOTE: To select individual element
	# https://docs.microsoft.com/en-us/previous-versions/dotnet/netframework-4.0/ms256086(v=vs.100)
	# $xmlns = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $EventXML.NameTable
	# $xmlns.AddNamespace("el", "http://schemas.microsoft.com/win/2004/08/events/event")
	# $EventXML.SelectSingleNode("/el:Event/el:EventData/el:Data[@Name = 'Direction']/text()", $xmlns).Value

	# Iterate through each one of the XML message properties
	for ($i = 0; $i -lt $EventXML.Event.EventData.Data.Count; ++$i)
	{
		$Name = $EventXML.Event.EventData.Data[$i].Name
		$Value = $EventXML.Event.EventData.Data[$i].'#text'

		if ($Name -eq "Protocol")
		{
			$Value = switch ($Value)
			{
				6 { "UDP"; break }
				17 { "TCP"; break }
				default { $Value }
			}
		}
		if ($Name -eq "Direction")
		{
			if ($Value -eq "%%14593")
			{
				$Value = "Outbound"
			}
			elseif ($Value -eq "%%14592")
			{
				$Value = "Inbound"
			}
			else
			{
				throw "Unexpected"
			}
		}

		$Data.Add($Name, $Value)
	}

	$Data | Out-File -Append -FilePath $File -Encoding $DefaultEncoding
}

# $Events | Select-Object -Property Application, Direction, SourceAddress, SourcePort, Protocol, DestAddress, DestPort

Update-Log

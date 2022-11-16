
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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

.VERSION 0.14.0

.GUID fc9b92ef-9756-4721-8cf4-28f9a04e6c49

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Stop capturing network traffic

.DESCRIPTION
Stop capturing network traffic previously started with Start-PacketTrace.ps1

.PARAMETER Name
Session name which to stop

.PARAMETER WFP
TODO: document parameter

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Stop-PacketTrace

.EXAMPLE
PS> Stop-PacketTrace -Name Traffic -WFP

.INPUTS
None. You cannot pipe objects to Stop-PacketTrace.ps1

.OUTPUTS
None. Stop-PacketTrace.ps1 does not generate any output

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
	[string] $Name = "TrafficDump",

	[Parameter()]
	[switch] $WFP,

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

if (Get-NetEventSession -Name $Name -EA Ignore)
{
	try
	{
		Write-Information -Tags $ThisScript -MessageData "INFO: Stopping session '$Name'"
		Stop-NetEventSession -Name $Name -EA Stop
	}
	catch
	{
		Write-Warning -Message "[$ThisScript] Session '$Name' could not be stopped"
	}

	try
	{
		if ($WFP)
		{
			Write-Information -Tags $ThisScript -MessageData "INFO: Removing WFP capture provider"

			if (Get-NetEventWFPCaptureProvider -SessionName $Name -EA Stop)
			{
				Remove-NetEventWFPCaptureProvider -SessionName $Name
			}
		}
		else
		{
			Write-Information -Tags $ThisScript -MessageData "INFO: Removing packet capture provider"

			if (Get-NetEventPacketCaptureProvider -SessionName $Name -EA Stop)
			{
				Remove-NetEventPacketCaptureProvider -SessionName $Name
			}
		}
	}
	catch
	{
		Write-Warning -Message "[$ThisScript] Capture provider for session '$Name' could not be removed"
	}

	Write-Information -Tags $ThisScript -MessageData "INFO: Removing session '$Name'"
	Remove-NetEventSession -Name $Name
}
else
{
	Write-Warning -Message "[$ThisScript] No session named '$Name' found"
}

Update-Log

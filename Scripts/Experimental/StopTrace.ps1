
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
Stop capturing network traffic

.DESCRIPTION
Stop capturing network traffic previously started with StartTrace.ps1

.PARAMETER Name
Session name which to stop

.EXAMPLE
PS> .\StopTrace.ps1

.INPUTS
None. You cannot pipe objects to StopTrace.ps1

.OUTPUTS
None. StopTrace.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[string] $Name = "TrafficDump",

	[Parameter()]
	[switch] $WFP
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
$Accept = "Start capturing network traffic into a file for analysis"
$Deny = "Abort operation, no capture is started"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

if (Get-NetEventSession -Name $Name -EA Ignore)
{
	try
	{
		Write-Information -Tags "User" -MessageData "INFO: Stopping session '$Name'"
		Stop-NetEventSession -Name $Name -EA Stop
	}
	catch
	{
		Write-Warning -Message "Session '$Name' could not be stopped"
	}

	try
	{
		if ($WFP)
		{
			Write-Information -Tags "User" -MessageData "INFO: Removing WFP capture provider"

			if (Get-NetEventWFPCaptureProvider -SessionName $Name -EA Stop)
			{
				Remove-NetEventWFPCaptureProvider -SessionName $Name
			}
		}
		else
		{
			Write-Information -Tags "User" -MessageData "INFO: Removing packet capture provider"

			if (Get-NetEventPacketCaptureProvider -SessionName $Name -EA Stop)
			{
				Remove-NetEventPacketCaptureProvider -SessionName $Name
			}
		}
	}
	catch
	{
		Write-Warning -Message "Capture provider for session '$Name' could not be removed"
	}

	Write-Information -Tags "User" -MessageData "INFO: Removing session '$Name'"
	Remove-NetEventSession -Name $Name
}
else
{
	Write-Warning -Message "No session named '$Name' found"
}

Update-Log

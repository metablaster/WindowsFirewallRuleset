
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
PS session options

.DESCRIPTION
PS session options are used for new PS sessions, ex. for New-PSSession

.PARAMETER Default
If specified default options are used instead of modified ones

.EXAMPLE
PS> SessionSettings

.INPUTS
None. You cannot pipe objects to SessionSettings.ps1

.OUTPUTS
None. SessionSettings.ps1 does not generate any output

.NOTES
None.

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-pstransportoption
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Settings used by other scripts")]
[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Default
)

# Utility or settings scripts don't do anything on their own
if ($MyInvocation.InvocationName -ne '.')
{
	Write-Error -Category NotEnabled -TargetObject $MyInvocation.InvocationName `
		-Message "This is settings script and must be dot sourced where needed" -EA Stop
}

if (!$Default)
{
	# [WSManConfigurationOption]
	[hashtable] $TransportConfigParams = @{
		# Limits the idle time-out set for each session to the specified value.
		# Corresponds to the MaxIdleTimeoutMs property of a session configuration.
		# The default value is [Int]::MaxValue (~25 days).
		# NOTE: The [Int]::MaxValue argument is greater than the maximum allowed range of 2147483
		MaxIdleTimeoutSec = 2147483

		# Determines how long each session stays open if the remote computer does not receive any communication from the local computer.
		# This includes the heartbeat signal. When the interval expires, the session closes.
		# Corresponds to the IdleTimeoutMs property of a session configuration.
		# Enter a value in seconds, the default value is 7200 (2 hours)
		IdleTimeoutSec = 7200

		# Limits the time-out for each host process to the specified value.
		# The default value, 0, means that there is no time-out value for the process.
		ProcessIdleTimeoutSec = 0

		# Limits the number of sessions that use the session configuration.
		# Corresponds to the MaxShells property of a session configuration.
		# The default value is 25
		MaxSessions = 5

		# Limits the number of users who can run commands at the same time in each session to the specified value.
		# The default value is 5.
		MaxConcurrentUsers = 5

		# Limits the number of sessions that use the session configuration and run with the
		# credentials of a given user to the specified value.
		# Corresponds to the MaxShellsPerUser property of a session configuration.
		# The default value is 25
		MaxSessionsPerUser = 5

		# Limits the number of commands that can run at the same time in each session to the specified value.
		# Corresponds to the MaxConcurrentCommandsPerShell property of a session configuration.
		# The default value is 1000.
		MaxConcurrentCommandsPerSession = 1000

		# Limits the number of processes running in each session to the specified value.
		# Corresponds to the MaxProcessesPerShell property of a session configuration.
		# The default value is 15.
		MaxProcessesPerSession = 15

		# Limits the memory used (in megabytes) by each session to the specified value.
		# Corresponds to the MaxMemoryPerShellMB property of a session configuration.
		# The default value is 1024 megabytes (1 GB).
		MaxMemoryPerSessionMB = 3072

		# Determines how command output is managed in disconnected sessions when the output buffer becomes full
		# "Block", When the output buffer is full, execution is suspended until the buffer is clear
		# "Drop", When the output buffer is full, execution continues. As new output is generated, the oldest output is discarded.
		# "None" No output buffering mode is specified.
		# The default value is Block
		OutputBufferingMode = "Block"
	}

	# [Microsoft.WSMan.Management.WSManConfigContainerElement]
	[hashtable] $SessionConfigParams = @{
		# Determines whether a 32-bit or 64-bit version of the PowerShell process is started in sessions
		# x86 or amd64,
		# The default value is determined by the processor architecture of the computer that hosts the session configuration.
		ProcessorArchitecture = "amd64"

		# Maximum amount of data that can be sent to this computer in any single remote command.
		# The default is 50 MB
		MaximumReceivedDataSizePerCommandMB = 50

		# Maximum amount of data that can be sent to this computer in any single object.
		# The default is 10 MB
		MaximumReceivedObjectSizeMB = 10

		# Disabled, this configuration cannot be used for remote or local access to the computer.
		# Local, allows users of the local computer to create a loopback session on the same computer.
		# Remote, allows local and remote users to create sessions and run commands on this computer.
		# The default value is Remote.
		AccessMode = "Remote"

		# The apartment state of the threading module to be used:
		# MTA: The Thread will create and enter a multithreaded apartment.
		# STA: The Thread will create and enter a single-threaded apartment.
		# Unknown: The ApartmentState property has not been set.
		# https://docs.microsoft.com/en-us/dotnet/api/system.threading.apartmentstate
		ThreadApartmentState = "Unknown"

		# Specifies how threads are created and used when a command runs in the session.
		# The acceptable values for this parameter are: Default, ReuseThread, UseCurrentThread and UseNewThread
		# The default value is UseCurrentThread.
		# https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.psthreadoptions
		ThreadOptions = "UseCurrentThread"

		# The specified script runs in the new session that uses the session configuration.
		# If the script generates an error, even a non-terminating error, the session is not created.
		# TODO: The following path is created by "MountUserDrive" option in Firewall.pssc (another option is: ScriptsToProcess in *.pssc)
		# StartupScript = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\DriveRoots\$env:USERDOMAIN_$env:USERNAME\ProjectSettings.ps1"

		# Advanced options for a session configuration
		# Without parameters, New-PSTransportOption generates a transport option object that has null values for all of the options.
		# A null value does not affect the session configuration.
		# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-pstransportoption
		# TransportOption = New-PSTransportOption @TransportConfigParams

		# Specifies credentials for commands in the session.
		# By default, commands run with the permissions of the current user.
		# RunAsCredential = Get-Credential

		# Use only one process to host all sessions that are started by the same user and use the same session configuration.
		# By default, each session is hosted in its own process.
		UseSharedProcess = $false

		# Specifies a Security Descriptor Definition Language (SDDL) string for the configuration.
		# This string determines the permissions that are required to use the new session configuration.
		# If you omit this parameter, the root SDDL for the WinRM service is used for this configuration.
		# To view or change the root SDDL, use Get-Item wsman:\localhost\service\rootSDDL
		# SecurityDescriptorSddl = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"
	}
}
else
{
	[hashtable] $TransportConfigParams = @{
		MaxIdleTimeoutSec = 2147483
		IdleTimeoutSec = 7200
		ProcessIdleTimeoutSec = 0
		MaxSessions = 25
		MaxConcurrentUsers = 5
		MaxSessionsPerUser = 25
		MaxConcurrentCommandsPerSession = 1000
		MaxProcessesPerSession = 15
		MaxMemoryPerSessionMB = 150
		OutputBufferingMode = "Block"
	}

	[hashtable] $SessionConfigParams = @{
		# ProcessorArchitecture = "amd64"
		MaximumReceivedDataSizePerCommandMB = 50
		MaximumReceivedObjectSizeMB = 10
		AccessMode = "Remote"
		ThreadApartmentState = "Unknown"
		ThreadOptions = "UseCurrentThread"
		TransportOption = New-PSTransportOption @TransportConfig
		# RunAsCredential = Get-Credential
		UseSharedProcess = $false
		SecurityDescriptorSddl = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"
	}
}

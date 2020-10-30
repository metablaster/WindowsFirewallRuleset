
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
Restart network
.DESCRIPTION
Apply computer group policy settings
Reset all physical adapters to their default values
Grant requested user and firewall service permissions to read/write logs into this repository
This is useful to troubleshoot problems or to generate network traffic that occurs only during
first time connection or system boot such as DHCP or IGMP
.EXAMPLE
PS> .\RestartNetwork.ps1
.NOTES
None.
.LINK
https://devblogs.microsoft.com/scripting/enabling-and-disabling-network-adapters-with-powershell
#>

[CmdletBinding()]
param (
	# TODO: DefaultUser will be always null until this is part of module
	[Parameter()]
	[string] $Principal = $DefaultUser
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
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
$Accept = "Restart all connected network adapters"
$Deny = "Abort operation"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# Update changes done to GPO firewall
gpupdate.exe /target:computer

<#
.SYNOPSIS
Get adapter aliases of specified state

.DESCRIPTION
Get-AdapterAlias gets physical interface aliases of adapters that are in specified state

.PARAMETER Adapter
An optional list of required adapters that must meet given state.
If successful aliases are returned back, otherwise warning message is show.

.PARAMETER Status
Specify state of network adapters for which to get interface aliases:
Disabled - Network adapter is disabled
Enabled - Network adapter is enabled but disconnected
Operational - Network adapter is connected to network

.EXAMPLE
Get-AdapterAlias Disabled

.EXAMPLE
Get-AdapterAlias Operational -Adapter @("Ethernet", "Realtek WI-FI")

.NOTES
None.
#>
function Get-AdapterAlias
{
	[OutputType([string[]])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("Disabled", "Enabled", "Operational")]
		[string] $Status,

		[Parameter()]
		[string[]] $Adapter
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[CimInstance[]] $AllAdapters = @()
	if ($Adapter)
	{
		$AllAdapters = Get-NetAdapter -Name $Adapter
	}
	else
	{
		$AllAdapters = Get-NetAdapter -Name * -Physical
	}

	[CimInstance[]] $Selection = switch ($Status)
	{
		"Disabled"
		{
			$AllAdapters | Where-Object -Property Status -EQ -Value "Disabled"
		}
		"Enabled"
		{
			$AllAdapters | Where-Object -Property Status -EQ -Value "Up"
		}
		"Operational"
		{
			$AllAdapters | Where-Object -Property ifOperStatus -EQ -Value "Up"
		}
	}

	if (!$Selection)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] None of the adapters is '$Status'"
		return
	}

	[string[]] $AdapterAlias = @()
	foreach ($Item in $Selection)
	{
		$ifOperStatus = $Item.ifOperStatus
		$IfAlias = $Item.InterfaceAlias
		$AdapterAlias += $IfAlias

		Write-Information -Tags "User" -MessageData "INFO: Adapter '$IfAlias' is '$Status' and '$ifOperStatus'"
	}

	if ($Adapter -and ($Selection.Length -lt $Adapter.Length))
	{
		Write-Warning -Message "Not all of the requested adapters are in '$Status' state"
		return
	}

	Write-Output -InputObject $AdapterAlias
}

<#
.SYNOPSIS
Wait until adapters are put into requested state

.DESCRIPTION
Wait in incrementail time intervals until specified network adapters are put into requested state

.PARAMETER Status
Wait until adapter is put into specified state

.PARAMETER Adapter
A list of interface aliases which should be put into requested state

.PARAMETER Seconds
Maximum amount of time interval to wait, expressed in seconds

.EXAMPLE
Wait-Adapter Enabled -Adapter "Ethernet"

.EXAMPLE
Wait-Adapter Disabled -Adapter "Ethernet" -Seconds 20

.NOTES
None.
#>
function Wait-Adapter
{
	[OutputType([string])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("Disabled", "Enabled", "Operational")]
		[string] $Status,

		[Parameter(Mandatory = $true)]
		[string[]] $Adapter,

		[Parameter()]
		[uint32] $Seconds = 15
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	for ($Time = 3; $Time -le $Seconds; $Time += 2)
	{
		# If all adapters reach desired state
		if (Get-AdapterAlias $Status -Adapter $Adapter) { break }

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring adapters for '$Status' state"
		Start-Sleep -Seconds $Time
	}
}

[string[]] $AdapterAlias = Get-AdapterAlias Disabled

if ($AdapterAlias)
{
	Write-Information -Tags "User" -MessageData "INFO: Attempt to bring up disabled adapters"

	Enable-NetAdapter -InterfaceAlias $AdapterAlias
	Wait-Adapter Enabled -Adapter $AdapterAlias
}

$AdapterAlias = Get-AdapterAlias Enabled

if ($AdapterAlias)
{
	Write-Information -Tags "User" -MessageData "INFO: Reseting adapter properties"

	# Reset the advanced properties of a network adapter to their factory default values
	Start-Job -Name "ResetProperties" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Reset-NetAdapterAdvancedProperty -InterfaceAlias $AdapterAlias -DisplayName "*" -NoRestart
	}

	Receive-Job -Name "ResetProperties" -Wait -AutoRemoveJob

	# Reset IP, mask and gateway address
	Start-Job -Name "ResetIP" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Remove-NetIPAddress -InterfaceAlias $AdapterAlias -IncludeAllCompartments -Confirm:$false
	}

	Receive-Job -Name "ResetIP" -Wait -AutoRemoveJob

	# Reset primary and secondary DNS
	Start-Job -Name "ResetDNS" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Set-DnsClientServerAddress -InterfaceAlias $AdapterAlias -ResetServerAddress
	}

	Receive-Job -Name "ResetDNS" -Wait -AutoRemoveJob

	Start-Job -Name "ResetInterface6" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)

		# NOTE:By default, RouterDiscovery is ControlledByDHCP for IPv4 and Enabled for IPv6
		# EcnMarking Allow an application or higher layer protocol, such as TCP, to decide how to apply ECN marking
		# NOTE: In order for an application to fully control ECN capability value in the Network TCP setting must also be set to Enabled
		Set-NetIPInterface -InterfaceAlias $AdapterAlias -RouterDiscovery Enabled -AutomaticMetric Enabled `
			-NeighborDiscoverySupported Yes -AddressFamily IPv6 -EcnMarking AppDecide -Dhcp Enabled -AsJob
	}

	Receive-Job -Name "ResetInterface6" -Wait -AutoRemoveJob

	Start-Job -Name "ResetInterface4" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)

		Set-NetIPInterface -InterfaceAlias $AdapterAlias -RouterDiscovery ControlledByDHCP -AutomaticMetric Enabled `
			-NeighborDiscoverySupported Yes -AddressFamily IPv4 -EcnMarking AppDecide -Dhcp Enabled -AsJob
	}

	Receive-Job -Name "ResetInterface4" -Wait -AutoRemoveJob

	# Sets the interface-specific DNS client configurations on the computer
	Start-Job -Name "ResetAdvancedDNS" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Set-DnsClient -InterfaceAlias $AdapterAlias -RegisterThisConnectionsAddress $true -ResetConnectionSpecificSuffix `
			-UseSuffixWhenRegistering $false
	}

	Receive-Job -Name "ResetAdvancedDNS" -Wait -AutoRemoveJob

	# NOTE: Error code 72:
	# An error occurred while accessing the registry for the requested information.
	# Invalid domain name (Action requires elevation)
	# https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/settcpipnetbios-method-in-class-win32-networkadapterconfiguration
	Start-Job -Name "NETBIOS" -ScriptBlock {
		# NETBIOS Option:
		# 0 - Use NetBIOS setting from the DHCP server
		# 1 - Enable NetBIOS over TCP/IP
		# 2 - Disable NetBIOS over TCP/IP

		$Description = Get-NetAdapter -Physical | Where-Object Status -EQ "Up" |
		Select-Object -ExpandProperty InterfaceDescription

		$Adapter = Get-CimInstance -Namespace "root\cimv2" -QueryDialect "WQL" `
			-Query "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Description LIKE '$Description'"

		Invoke-CimMethod -InputObject $Adapter -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = 0 }
	}

	# Clears the contents of the DNS client cache
	Start-Job -Name "ClearDNSCache" -ScriptBlock {
		Clear-DnsClientCache
	}

	Receive-Job -Name "ClearDNSCache" -Wait -AutoRemoveJob

	# Reset adapters for changes to take effect
	Write-Information -Tags "User" -MessageData "INFO: Disabling adapters"

	# NOTE: Need to wait until registry is updated for IP removal
	Disable-NetAdapter -InterfaceAlias $AdapterAlias -Confirm:$false
	Wait-Adapter Disabled -Adapter $AdapterAlias

	Write-Information -Tags "User" -MessageData "INFO: Enabling adapters"

	# NOTE: Need to wait for firewall service to become active and to
	# set up file system permissions for logs
	Enable-NetAdapter -InterfaceAlias $AdapterAlias
	Wait-Adapter Operational -Adapter $AdapterAlias

	# Registers all of the IP addresses on the computer onto the configured DNS server
	Start-Job -Name "RegisterDNSClient" -ScriptBlock {
		Register-DnsClient
	}

	Receive-Job -Name "RegisterDNSClient" -Wait -AutoRemoveJob
}

# Grant access to firewall logs
if (![string]::IsNullOrEmpty($Principal))
{
	& "$ProjectRoot\Scripts\GrantLogs.ps1" -Principal $Principal -SkipPrompt
}

Update-Log

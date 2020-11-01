
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
Restart and optionally reset network

.DESCRIPTION
Restart or reset all physical network adapters to their default values
Reset few esoteric default options
Set network profile to private
Apply computer group policy settings
Grant requested user and firewall service permissions to read/write logs into this repository.
This is useful to troubleshoot problems or to generate network traffic that occurs only during
first time connection or system boot such as DHCP or IGMP

.PARAMETER KeepDNS
Skip clearing DNS server IP addresses
This parameter is ignored if "KeepIP" is specified

.PARAMETER KeepIP
Skip clearing IP, mask and default gateway

.PARAMETER Reset
Reset all network properties in addition to restarting network

.EXAMPLE
PS> .\RestartNetwork.ps1

.EXAMPLE
PS> .\RestartNetwork.ps1 -KeepIP

.EXAMPLE
PS> .\RestartNetwork.ps1 MyUsername -KeepDNS -Reset

.NOTES
TODO: IP protocol parameter

.LINK
https://devblogs.microsoft.com/scripting/enabling-and-disabling-network-adapters-with-powershell
#>

[CmdletBinding()]
param (
	[Parameter()]
	[string] $Principal,

	[Parameter()]
	[switch] $KeepDNS,

	[Parameter()]
	[switch] $KeepIP,

	[Parameter()]
	[switch] $Reset
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
$Accept = "Restart all connected network adapters and reassign IP"
$Deny = "Abort operation, no change to network configuration is done"
if ($Reset)
{
	$Accept = "Reset all connected network adapters and network settings"
}

Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

<#
.SYNOPSIS
Get adapter aliases of specified state

.DESCRIPTION
Select-AdapterAlias gets physical interface aliases of adapters that are in specified state

.PARAMETER Interface
An optional list of required adapters that must meet given state.
If successful aliases are returned back, otherwise warning message is show.

.PARAMETER Status
Specify minimum state of network adapters for which to get interface aliases:
Disabled - Network adapter is disabled
Enabled - Network adapter is enabled but disconnected
Operational - Network adapter is able to connect to network
Connected - Network adapter has internet access

.EXAMPLE
Select-AdapterAlias Disabled

.EXAMPLE
Select-AdapterAlias Operational -Adapter @("Ethernet", "Realtek WI-FI")

.NOTES
None.
#>
function Select-AdapterAlias
{
	[OutputType([string[]])]
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("State")]
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("Removed", "Disabled", "Enabled", "Operational", "Connected")]
		[string] $Status,

		[Alias("Interface")]
		[Parameter()]
		[string[]] $Adapter
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[CimInstance[]] $TargetAdapter = @()
	if ($Adapter)
	{
		$TargetAdapter = Get-NetAdapter -Name $Adapter
	}
	else
	{
		$TargetAdapter = Get-NetAdapter -Physical -Name *
	}

	[string[]] $AcceptStatus = @()
	[string[]] $AdapterAlias = @()

	foreach ($Item in $TargetAdapter)
	{
		$ifAlias = $Item.InterfaceAlias
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing '$ifAlias' adapter with '$($Item.Status)' status"

		# NOTE: Adapter "Status" values:
		# Not Present - adapter is not present
		# Disabled - adapter is disabled and disconnected
		# Disconnected - adapter is enabled but disconnected from network
		# Up - adapter is enabled and able to connect to internet
		:inside1 switch -Wildcard ($Item.Status)
		{
			"Not Present"
			{
				$ifStatus =	"Removed"
				$AcceptStatus = @("Removed")
				break inside1
			}
			"Disabled"
			{
				$ifStatus =	$Item.Status
				$AcceptStatus = @("Disabled")
				break inside1
			}
			"Disconnected"
			{
				$ifStatus =	"Enabled"
				$AcceptStatus = @("Enabled")
				break inside1
			}
			"Up"
			{
				$ifStatus = "Operational"
				$AcceptStatus = @("Enabled", "Operational")

				$NetworkProfile = Get-NetConnectionProfile -IPv4Connectivity Internet -InterfaceAlias $ifAlias -ErrorAction Ignore

				if ($NetworkProfile)
				{
					:inside2 switch -Wildcard ($NetworkProfile.Name)
					{
						# NOTE: Known profiles when there is not internet access
						# Identifying...
						# Unidentified network
						"Identifying*" { }
						"Unidentified*" { break	inside2 }
						default
						{
							$ifStatus = "Connected"
							$AcceptStatus = @("Enabled", "Operational", "Connected")
						}
					}
				}

				break inside1
			}
			default
			{
				$ifStatus =	"Unknown"
			}
		}

		if ([array]::Find($AcceptStatus, [System.Predicate[string]] { $Status -eq $args[0] }))
		{
			$AdapterAlias += $ifAlias
		}

		Write-Information -Tags "User" -MessageData "INFO: '$ifAlias' adapter status is '$ifStatus'"
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
		[ValidateSet("Removed", "Disabled", "Enabled", "Operational", "Connected")]
		[string] $Status,

		[Parameter(Mandatory = $true)]
		[string[]] $Adapter,

		[Parameter()]
		[uint32] $Seconds = 10
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	for ($Time = 2; $Time -le ($Seconds - $Time + 2); $Time += 2)
	{
		[string[]] $Result = Select-AdapterAlias $Status -Adapter $Adapter

		# If all adapters reach desired state
		if ($Result -and ($Result.Count -eq $Adapter.Count))
		{
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Waiting adapters for '$Status' state"
		Start-Sleep -Seconds $Time
	}

	Write-Warning -Message "Not all of the requested adapters are in '$Status' state"
}

[string[]] $AdapterAlias = Select-AdapterAlias Disabled

if ($AdapterAlias)
{
	Write-Information -Tags "User" -MessageData "INFO: Attempt to bring up disabled adapters"

	Enable-NetAdapter -InterfaceAlias $AdapterAlias
	Wait-Adapter Enabled -Adapter $AdapterAlias
}

$AdapterAlias = Select-AdapterAlias Enabled

# NOTE: The order of tasks is important because:
# 1. keep network interface up as longer possible to capture precise network stop and start time
# 2. Some properties can be modified only in specific adapter state
# 3. Reset properties as much as possible before disabling network adapter
# TODO: Reset adapter items (optionally reinstall them, which requires reboot?)
# TODO: set power options
# TODO: Reset APIPA alternate IP fields
# TODO: Reset WINS and LMHOSTS options
# TODO: Restart network services
# TODO: Test network
if ($AdapterAlias)
{
	if ($KeepIP -or $KeepDNS)
	{
		Write-Information -Tags "User" -MessageData "INFO: Saving IP configuration"

		# TODO: Get-NetRoute for gateway
		$IPInfo = Get-NetIPConfiguration -All |
		Select-Object -Property IPv4Address, IPv4DefaultGateway, DNSServer
	}

	if ($KeepIP)
	{
		$PrefixLength = Get-NetIPAddress -InterfaceAlias $AdapterAlias -AddressFamily ipv4 |
		Select-Object -Property PrefixLength, InterfaceAlias
	}

	if ($Reset)
	{
		Write-Information -Tags "User" -MessageData "INFO: Reseting adapter properties"

		# Reset the advanced properties of a network adapter to their factory default values
		Start-Job -Name "AdvancedProperties" -ArgumentList $AdapterAlias -ScriptBlock {
			param ($AdapterAlias)
			Reset-NetAdapterAdvancedProperty -InterfaceAlias $AdapterAlias -DisplayName "*" -NoRestart
		}

		Receive-Job -Name "AdvancedProperties" -Wait -AutoRemoveJob

		# Sets the interface-specific DNS client configurations on the computer
		Start-Job -Name "AdvancedDNS" -ArgumentList $AdapterAlias -ScriptBlock {
			param ($AdapterAlias)
			Set-DnsClient -InterfaceAlias $AdapterAlias -RegisterThisConnectionsAddress $true -ResetConnectionSpecificSuffix `
				-UseSuffixWhenRegistering $false
		}

		Receive-Job -Name "AdvancedDNS" -Wait -AutoRemoveJob

		# Set NETBIOS adapter option
		Start-Job -Name "NETBIOS" -ScriptBlock {
			# NETBIOS Option:
			# 0 - Use NetBIOS setting from the DHCP server
			# 1 - Enable NetBIOS over TCP/IP
			# 2 - Disable NetBIOS over TCP/IP

			$Description = Get-NetAdapter -Physical | Where-Object Status -EQ "Up" |
			Select-Object -ExpandProperty InterfaceDescription

			$Adapter = Get-CimInstance -Namespace "root\cimv2" -QueryDialect "WQL" `
				-Query "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Description LIKE '$Description'"

			# NOTE: Error code 72: An error occurred while accessing the registry for the requested information.
			# Invalid domain name (Action requires elevation)
			# Error code 84: IP not enabled on adapter.
			# https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/settcpipnetbios-method-in-class-win32-networkadapterconfiguration
			Invoke-CimMethod -InputObject $Adapter -MethodName SetTcpipNetbios -Arguments @{
				TcpipNetbiosOptions = 0
			} | Out-Null
		}

		Receive-Job -Name "NETBIOS" -Wait -AutoRemoveJob

		# TCP auto-tuning can improve throughput on high throughput, high latency networks
		Start-Job -Name "AutoTuningLevel" -ScriptBlock {
			# Normal. Sets the TCP receive window to grow to accommodate almost all scenarios
			Set-NetTCPSetting -AutoTuningLevelLocal Normal
		}

		Receive-Job -Name "AutoTuningLevel" -Wait -AutoRemoveJob
	} # Reset

	# Clear routing table for interface, removes the "default gateway entry"
	# NOTE: Set-NetIPInterface won't do it's job completely without this step
	# NOTE: Routes are available only when adapter is enabled (and connected?)
	# TODO: Remove-NetRoute: Element not found
	Start-Job -Name "RoutingTable" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Remove-NetRoute -InterfaceAlias $AdapterAlias -AddressFamily IPv4 -Confirm:$false
	}

	Receive-Job -Name "RoutingTable" -Wait -AutoRemoveJob

	# Set IPv6 interface to "Obtain an IP address automatically"
	Start-Job -Name "InterfaceIPv6" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)

		# NOTE:By default, RouterDiscovery is ControlledByDHCP for IPv4 and Enabled for IPv6
		# EcnMarking Allow an application or higher layer protocol, such as TCP, to decide how to apply ECN marking
		# NOTE: In order for an application to fully control ECN capability value in the Network TCP setting must also be set to Enabled
		Set-NetIPInterface -InterfaceAlias $AdapterAlias -RouterDiscovery Enabled -AutomaticMetric Enabled `
			-NeighborDiscoverySupported Yes -AddressFamily IPv6 -EcnMarking AppDecide -Dhcp Enabled
	}

	Receive-Job -Name "InterfaceIPv6" -Wait -AutoRemoveJob

	# Set IPv4 interface to "Obtain an IP address automatically"
	Start-Job -Name "InterfaceIPv4" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)

		Set-NetIPInterface -InterfaceAlias $AdapterAlias -RouterDiscovery ControlledByDHCP -AutomaticMetric Enabled `
			-NeighborDiscoverySupported Yes -AddressFamily IPv4 -EcnMarking AppDecide -Dhcp Enabled
	}

	Receive-Job -Name "InterfaceIPv4" -Wait -AutoRemoveJob

	# Set interface to "Obtain DNS server address automatically", removes primary and secondary DNS
	Start-Job -Name "DNSServers" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Set-DnsClientServerAddress -InterfaceAlias $AdapterAlias -ResetServerAddress
	}

	Receive-Job -Name "DNSServers" -Wait -AutoRemoveJob

	# Reset IP, mask and gateway address
	# NOTE: Adapter must be enabled
	# TODO: not clear where to put this nor what it does since adapter entries are clear at this point
	Start-Job -Name "IPAddress" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Remove-NetIPAddress -InterfaceAlias $AdapterAlias -IncludeAllCompartments -Confirm:$false
	}

	Receive-Job -Name "IPAddress" -Wait -AutoRemoveJob

	# Reset adapters for changes to take effect
	# Following
	Write-Information -Tags "User" -MessageData "INFO: Disabling network adapters"

	# NOTE: Need to wait until registry is updated for IP removal
	Disable-NetAdapter -InterfaceAlias $AdapterAlias -Confirm:$false
	Wait-Adapter Disabled -Adapter $AdapterAlias

	$NetworkTime = Get-Date -DisplayHint Time | Select-Object -ExpandProperty DateTime
	Write-Information -Tags "User" -MessageData "INFO: Network stop time is $NetworkTime"

	Write-Information -Tags "User" -MessageData "INFO: Waiting 10 seconds to silence network"
	Start-Sleep -Seconds 10

	# Clears the contents of the DNS client cache
	Start-Job -Name "ClearDNSCache" -ScriptBlock {
		Clear-DnsClientCache
	}

	Receive-Job -Name "ClearDNSCache" -Wait -AutoRemoveJob

	# Make changes done to GPO firewall effective
	gpupdate.exe /target:computer

	Write-Information -Tags "User" -MessageData "INFO: Enabling network adapters"

	# NOTE: Need to wait for firewall service to become active and to be able to
	# set up file system permissions for logs in final step
	# TODO: Adapter 'Up' state isn't the same as "Connected"
	Enable-NetAdapter -InterfaceAlias $AdapterAlias
	Wait-Adapter Operational -Adapter $AdapterAlias

	$NetworkTime = Get-Date -DisplayHint Time | Select-Object -ExpandProperty DateTime
	Write-Information -Tags "User" -MessageData "INFO: Network start time is $NetworkTime"

	# Restore adapter static IP configuration
	if ($KeepIP)
	{
		Write-Information -Tags "User" -MessageData "INFO: Restoring old IP configuration"

		# Restore previous IP configuration
		foreach ($Adapter in (Get-NetAdapter -Physical -Name $AdapterAlias))
		{
			$ifAlias = $Adapter.InterfaceAlias

			$Prefix = $PrefixLength | Where-Object -Property InterfaceAlias -EQ $ifAlias |
			Select-Object -ExpandProperty PrefixLength

			$Address = $IPInfo.IPv4Address | Where-Object -Property InterfaceAlias -EQ $ifAlias |
			Select-Object -ExpandProperty IPAddress

			$DefaultGateway = $IPInfo.IPv4DefaultGateway | Where-Object {
				$_ | Select-Object -ExpandProperty InterfaceAlias -EQ $ifAlias
			} | Select-Object -ExpandProperty NextHop

			New-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -IPAddress $Address `
				-PrefixLength $Prefix -DefaultGateway $DefaultGateway
		}
	}

	# Restore adapter DNS servers
	if ($KeepIP -or $KeepDNS)
	{
		Write-Information -Tags "User" -MessageData "INFO: Restoring old DNS server addresses"

		# Restore previous NDS servers
		foreach ($Adapter in (Get-NetAdapter -Physical -Name $AdapterAlias))
		{
			# https://docs.microsoft.com/en-us/dotnet/api/system.net.sockets.addressfamily?view=netcore-3.1
			# AddressFamily 2 IPv4
			# AddressFamily 23 IPv6
			$DNSAddress4 = $IPInfo.DNSServer | Where-Object -Property interfacealias -EQ Ethernet |
			Where-Object -Property AddressFamily -EQ 2 | Select-Object -ExpandProperty ServerAddresses

			# NOTE: Adapter must be enabled
			Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DNSAddress4 # -Validate
		}
	}

	Wait-Adapter Connected -Adapter $AdapterAlias

	# TODO: Set to old profile
	# TODO: Unable to set NetworkCategory on a network marked 'Identifying...', Please wait for network identification to complete.
	Start-Job -Name "NetworkProfile" -ArgumentList $AdapterAlias -ScriptBlock {
		param ($AdapterAlias)
		Set-NetConnectionProfile -InterfaceAlias $AdapterAlias -NetworkCategory Private
	}

	Receive-Job -Name "NetworkProfile" -Wait -AutoRemoveJob

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

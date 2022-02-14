
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame
Copyright (C) 2021-2022 metablaster zebal@protonmail.ch

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

.VERSION 0.13.0

.GUID 0014338b-58f3-4d41-8a0b-dcaafef55c75

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.ComputerInfo
#>

<#
.SYNOPSIS
Display current TCP/IP connections for local or remote system

.DESCRIPTION
Get-NetworkStat.ps1 displays current TCP/IP connections for local or remote system.
Includes the process ID (PID) and optionally process name for each connection.
If the port is not yet established, the port number is shown as an asterisk (*).

.PARAMETER ProcessName
Gets connections by the name of the process.
Wildcard characters are supported.
The default value is "*"

.PARAMETER IPAddress
Gets connections by the IP address of the connection, local or remote.
Wildcard characters are supported.
The default value is "*"

.PARAMETER Port
The port number of the local or remote computer.
Wildcard characters are supported.
The default value is "*"

.PARAMETER Domain
Run this script against specified computer.
The default value is local computer.
\\$Domain\C$\netstat.txt is created on that system and the results are returned here

.PARAMETER Protocol
The name of the protocol (TCP or UDP).
The default value is "*" (Any)

.PARAMETER State
Indicates the state of a TCP connection.
The possible states are as follows:

Closed       - The TCP connection is closed.
Close_Wait   - The local endpoint of the TCP connection is waiting for a connection termination request from the local user.
Closing      - The local endpoint of the TCP connection is waiting for an acknowledgement of the connection termination request sent previously.
Delete_Tcb   - The transmission control buffer (TCB) for the TCP connection is being deleted.
Established  - The TCP handshake is complete. The connection has been established and data can be sent.
Fin_Wait_1   - The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint or for an acknowledgement of the connection termination request sent previously.
Fin_Wait_2   - The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint.
Last_Ack     - The local endpoint of the TCP connection is waiting for the final acknowledgement of the connection termination request sent previously.
Listen       - The local endpoint of the TCP connection is listening for a connection request from any remote endpoint.
Syn_Received - The local endpoint of the TCP connection has sent and received a connection request and is waiting for an acknowledgment.
Syn_Sent     - The local endpoint of the TCP connection has sent the remote endpoint a segment header with the synchronize (SYN) control bit set and is waiting for a matching connection request.
Time_Wait    - The local endpoint of the TCP connection is waiting for enough time to pass to ensure that the remote endpoint received the acknowledgement of its connection termination request.
Unknown      - The TCP connection state is unknown.

Values are based on the TcpState Enumeration:
http://msdn.microsoft.com/en-us/library/system.net.networkinformation.tcpstate%28VS.85%29.aspx

Cookie Monster - modified these to match netstat output per here:
http://support.microsoft.com/kb/137984

.PARAMETER IncludeHostName
If specified, will attempt to resolve local and remote addresses

.PARAMETER IncludeProcessName
If specified, includes process names involved in connection

.PARAMETER TempLocation
Temporary file to store results on remote system.
Must be relative to remote system (not a file share).
The default value is "C:\netstat.txt"

.PARAMETER AddressFamily
If specified, displays result where both the localaddress and the remoteaddress is of address family.

.EXAMPLE
PS> Get-NetworkStat | Format-Table

.EXAMPLE
PS> Get-NetworkStat iexplore -Domain Server01 -ShowHostName | Format-Table

.EXAMPLE
PS> Get-NetworkStat -ProcessName md* -Protocol TCP

.EXAMPLE
PS> Get-NetworkStat -IPAddress 192* -State LISTENING

.EXAMPLE
PS> Get-NetworkStat -State LISTENING -Protocol TCP

.EXAMPLE
PS> Get-NetworkStat -Domain Computer1, Computer2

.EXAMPLE
PS> 'Computer1', 'Computer2' | Get-NetworkStat

.INPUTS
[string[]]

.OUTPUTS
[PSCustomObject]

.NOTES
Author: Shay Levy, code butchered by Cookie Monster
Shay's Blog: http://PowerShay.com
Cookie Monster's Blog: http://ramblingcookiemonster.github.io/

Modifications by metablaster:
January 2021:
Added #Requires statement, missing Parameter and SupportsWildcards attributes
Replaced Invoke-WmiMethod with Invoke-CimMethod
Updated formatting, casing and naming according to the rest of project
Converted to script by removing function
Updated comment based help
Fixed getting process list from remote computer with Invoke-Command instead of Get-Process
Changed default for AddressFamily from * to Any

February 2022:
Addresses are resolved to host name by using Resolve-Host function from repository
Invoke-Command and Invoke-CimMethod use -Credential and -CimSession to establish connection
Bugfix where filtering by local and remote address would produce errors
Verbose messages modified to be more precise in description
Bugfix where Invoke-Command to get processes would return wrong process ID, needed to wait for process

TODO: Need to handle multiple computers

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://github.com/RamblingCookieMonster/PowerShell

.LINK
http://gallery.technet.microsoft.com/scriptcenter/Get-NetworkStatistics-66057d71
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false)]
[OutputType([System.Management.Automation.PSCustomObject])]
param (
	[Parameter(Position = 0)]
	[SupportsWildcards()]
	[string] $ProcessName = "*",

	[Parameter(Position = 1)]
	[SupportsWildcards()]
	[string] $IPAddress = "*",

	[Parameter(Position = 2)]
	[SupportsWildcards()]
	[ValidatePattern("[\*\d\?\[\]]")]
	[string] $Port = "*",

	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[ValidateSet("*", "TCP", "UDP")]
	[string] $Protocol = "*",

	[Parameter()]
	[ValidateSet("*", "Closed", "Close_Wait", "Closing", "Delete_Tcb", "DeleteTcb", "Established", "Fin_Wait_1",
		"Fin_Wait_2", "Last_Ack", "Listening", "Syn_Received", "Syn_Sent", "Time_Wait", "Unknown")]
	[string] $State = "*",

	[Parameter()]
	[switch] $IncludeHostName,

	[Parameter()]
	[switch] $IncludeProcessName,

	[Parameter()]
	[string] $TempLocation = "C:\netstat.txt",

	[Parameter()]
	[ValidateSet("IPv4", "IPv6", "Any")]
	[string] $AddressFamily = "Any"
)

begin
{
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
	Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Initialize-Project -Strict

	# Define properties
	$Properties = "Domain", "Protocol", "LocalAddress", "LocalPort", "RemoteAddress", "RemotePort", "State", "ProcessName", "PID"

	# Store hostnames in array for quick lookup
	$DnsCache = @{}

	$MachineName = Format-ComputerName $Domain
}
process
{
	# Handle remote systems
	if ($MachineName -eq [System.Environment]::MachineName)
	{
		# Collect processes
		if ($IncludeProcessName)
		{
			Write-Information -Tags $ThisScript -MessageData "INFO: Getting list of processes on '$Domain'..."
			$Processes = Get-Process | Select-Object Name, Id
		}

		# Gather results on local PC
		$NetstatData = netstat -ano | Select-String -Pattern "\s+(TCP|UDP)"
	}
	else
	{
		# Collect processes
		if ($IncludeProcessName)
		{
			try
			{
				Write-Information -Tags $ThisScript -MessageData "INFO: Getting list of processes on '$Domain'..."
				$Processes = Invoke-Command -ComputerName $Domain -Credential $RemotingCredential -ErrorAction Stop -ScriptBlock {
					Get-Process
				} |	Select-Object -Property Name, Id
			}
			catch
			{
				Write-Warning -Message "[$ThisScript] Unable to run Get-Process on computer '$Domain', excluding IncludeProcessName"
				$IncludeProcessName = $false
			}
		}

		# Define netstat command
		[string] $cmd = "cmd /c c:\windows\system32\netstat.exe -ano >> $TempLocation"

		# Define remote file path - computername, drive, folder path
		$RemoteTempFile = "\\{0}\{1}`${2}" -f $MachineName, (Split-Path $TempLocation -Qualifier).TrimEnd(":"), (Split-Path $TempLocation -NoQualifier)

		try
		{
			# Delete previous results
			Invoke-CimMethod -ClassName Win32_Process -MethodName Create -CimSession $CimServer -ErrorAction Stop `
				-Arguments @{ CommandLine = "cmd /c del $TempLocation" } | Out-Null
		}
		catch
		{
			Write-Warning -Message "[$ThisScript] Could not invoke create Win32_Process on '$Domain' to delete '$TempLocation'"
		}

		try
		{
			Invoke-CimMethod -ClassName Win32_Process -MethodName Create `
				-Arguments @{ CommandLine = $cmd } -CimSession $CimServer -ErrorAction Stop | Out-Null

			Invoke-Command -ComputerName $Domain -Credential $RemotingCredential -ScriptBlock {
				Get-Process -Name netstat -ErrorAction SilentlyContinue | Wait-Process
			}
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return
		}

		# Gather results
		if (Test-Path -Path $RemoteTempFile)
		{
			try
			{
				$NetstatData = Get-Content -Path $RemoteTempFile -ErrorAction Stop | Select-String -Pattern "\s+(TCP|UDP)"
			}
			catch
			{
				Write-Error -Category ReadError -TargetObject $RemoteTempFile `
					-Message "Could not get contents from $RemoteTempFile for results"
				return
			}

			Remove-Item -Path $RemoteTempFile -Force
		}
		else
		{
			Write-Error -Category ReadError -TargetObject $RemoteTempFile `
				-Message "'$TempLocation' on '$Domain' converted to '$RemoteTempFile', this path is not accessible from your system."
			return
		}
	}

	# Initialize counter for progress
	$Count = 0
	$TotalCount = $NetstatData.Count

	# Loop through each line of results
	foreach ($NetstatEntry in $NetstatData)
	{
		$Item = $NetstatEntry.Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

		if ($Item[1] -notmatch "^\[::")
		{
			# Parse the netstat line for local address and port
			$LocalCapture = [regex]::Match($Item[1], "\d|\w.+(?=]:\d+$)|(\d+|\.)+")

			if ($LocalCapture.Success)
			{
				$ItemAddress = $LocalCapture.Value -as [IPAddress]
				$LocalAddress = $ItemAddress.IPAddressToString

				if ($ItemAddress.AddressFamily -eq "InterNetworkV6")
				{
					$LocalPort = $Item[1].Split("]:")[1]
				}
				else
				{
					$LocalPort = $Item[1].Split(":")[1]
				}
			}

			# Parse the netstat line for remote address and port
			$RemoteCapture = [regex]::Match($Item[2], "\d|\w.+(?=]:\d+$)|(\d+|\.)+")

			if ($RemoteCapture.Success)
			{
				$ItemAddress = $RemoteCapture.Value -as [IPAddress]
				$RemoteAddress = $ItemAddress.IPAddressToString

				if ($ItemAddress.AddressFamily -eq "InterNetworkV6")
				{
					$RemotePort = $Item[2].Split("]:")[1]
				}
				else
				{
					$RemotePort = $Item[2].Split(":")[1]
				}
			}
			elseif ($Item[2] -eq "*:*")
			{
				$RemotePort = "*"
				$RemoteAddress = "*"
			}

			# Filter IPv4/IPv6 if specified
			if ($AddressFamily -ne "Any")
			{
				if (($AddressFamily -eq "IPv4") -and ($LocalAddress -match ":"))
				{
					# Skip IPv6 address entries
					Write-Verbose -Message "[$ThisScript] Filtered by AddressFamily $LocalAddress"
					continue
				}
				elseif (($AddressFamily -eq "IPv6") -and ($LocalAddress -notmatch ":"))
				{
					# Skip IPv4 address entries
					Write-Verbose -Message "[$ThisScript] Filtered by AddressFamily $LocalAddress"
					continue
				}
			}

			# Parse the netstat line for other properties
			# TODO: Better approach is needed to access last element
			$ProcessID = $Item[-1]
			$ItemProtocol = $Item[0]
			$Status = if ($Item[0] -eq "TCP") { $Item[3] } else { $null }

			# Filter the object
			if (($LocalPort -notlike $Port) -and ($RemotePort -notlike $Port))
			{
				Write-Verbose -Message "[$ThisScript] Filtered by Port, local $LocalPort remote $RemotePort"
				continue
			}

			if (($RemoteAddress -notlike $IPAddress) -and ($LocalAddress -notlike $IPAddress))
			{
				Write-Verbose -Message "[$ThisScript] Filtered by Address, local $LocalAddress remote $RemoteAddress"
				continue
			}

			if ($Status -notlike $State)
			{
				Write-Verbose -Message "[$ThisScript] Filtered by State '$Status'"
				continue
			}

			if ($ItemProtocol -notlike $Protocol)
			{
				Write-Verbose -Message "[$ThisScript] Filtered by Protocol $ItemProtocol"
				continue
			}

			# Display progress bar prior to getting process name or host name
			Write-Progress -Activity "Resolving host and process names" `
				-Status "Resolving process ID $ProcessID with remote address $RemoteAddress and local address $LocalAddress"`
				-PercentComplete (( $Count / $TotalCount ) * 100)

			# If we are running IncludeProcessName, get the matching name
			if ($IncludeProcessName)
			{
				# Handle case where process spun up in the time between running get-process and running netstat
				$ItemProcessName = $Processes | Where-Object {
					$_.Id -eq $ProcessID
				} | Select-Object -ExpandProperty Name

				if (!$ItemProcessName)
				{
					$ItemProcessName = "Unknown"
				}
			}
			else
			{
				$ItemProcessName = "NA"
			}

			if ($ItemProcessName -notlike $ProcessName)
			{
				Write-Verbose -Message "[$ThisScript] Filtered by ProcessName $ItemProcessName"
				continue
			}

			# If the IncludeHostName switch is specified, try to map IP to hostname
			if ($IncludeHostName)
			{
				$TempAddress = $null
				Write-Debug -Message "[$ThisScript] Resolving remote address $RemoteAddress"

				if (($RemoteAddress -eq "127.0.0.1") -or ($RemoteAddress -eq "0.0.0.0"))
				{
					$RemoteAddress = $MachineName
				}
				elseif ($RemoteAddress -match "\w")
				{
					# Check with dns cache first
					if ($DnsCache.ContainsKey($RemoteAddress))
					{
						$RemoteAddress = $DnsCache[$RemoteAddress]
						Write-Verbose -Message "[$ThisScript] Using cached remote address '$RemoteAddress'"
					}
					else
					{
						# If address isn't in the cache, resolve it and add it
						$TempAddress = $RemoteAddress
						$HostInfo = Resolve-Host -IPAddress $RemoteAddress

						if ($HostInfo)
						{
							$RemoteAddress = $HostInfo.IPAddress
							$DnsCache.Add($TempAddress, $RemoteAddress)
							Write-Verbose -Message "[$ThisScript] Using non cached remote address '$RemoteAddress`t$TempAddress"
						}
					}
				}

				$TempAddress = $null
				Write-Debug -Message "[$ThisScript] Resolving local address $LocalAddress"

				if (($LocalAddress -eq "127.0.0.1") -or ($LocalAddress -eq "0.0.0.0"))
				{
					$LocalAddress = $MachineName
				}
				elseif ($LocalAddress -match "\w")
				{
					# Check with dns cache first
					if ($DnsCache.ContainsKey($LocalAddress))
					{
						$LocalAddress = $DnsCache[$LocalAddress]
						Write-Verbose -Message "[$ThisScript] Using cached local address '$LocalAddress'"
					}
					else
					{
						# If address isn't in the cache, resolve it and add it
						$TempAddress = $LocalAddress
						$HostInfo = Resolve-Host -IPAddress $LocalAddress

						if ($HostInfo)
						{
							$LocalAddress = $HostInfo.IPAddress
							$DnsCache.Add($TempAddress, $LocalAddress)
							Write-Verbose -Message "[$ThisScript] Using non cached local address '$LocalAddress'`t'$TempAddress'"
						}
					}
				}
			}

			# Write the object
			[PSCustomObject]@{
				Domain = $MachineName
				PID = $ProcessID
				ProcessName = $ItemProcessName
				Protocol = $ItemProtocol
				LocalAddress = $LocalAddress
				LocalPort = $LocalPort
				RemoteAddress = $RemoteAddress
				RemotePort = $RemotePort
				State = $Status
			} | Select-Object -Property $Properties

			# Increment the progress counter
			++$Count
		}
	}

	Update-Log
}

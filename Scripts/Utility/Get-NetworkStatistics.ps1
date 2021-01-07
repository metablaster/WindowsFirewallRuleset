
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame

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

.VERSION 0.9.1

.GUID 0014338b-58f3-4d41-8a0b-dcaafef55c75

.AUTHOR Warren Frame
#>

<#
.SYNOPSIS
Display current TCP/IP connections for local or remote system

.DESCRIPTION
Display current TCP/IP connections for local or remote system.
Includes the process ID (PID) and process name for each connection.
If the port is not yet established, the port number is shown as an asterisk (*).

.PARAMETER ProcessName
Gets connections by the name of the process.
Wildcard characters are supported.
The default value is "*"

.PARAMETER Address
Gets connections by the IP address of the connection, local or remote.
Wildcard characters are supported.
The default value is "*"

.PARAMETER Port
The port number of the local computer or remote computer.
Wildcard characters are supported.
The default value is "*"

.PARAMETER Domain
If defined, run this command on a remote system via CIM.
\\Domain\C$\netstat.txt is created on that system and the results returned here

.PARAMETER Protocol
The name of the protocol (TCP or UDP).
The default value is "*" (all)

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

.PARAMETER ShowHostNames
If specified, will attempt to resolve local and remote addresses

.PARAMETER ShowProcessNames
If specified, includes process names involved in connection

.PARAMETER TempFile
Temporary file to store results on remote system.
Must be relative to remote system (not a file share).
Default is "C:\netstat.txt"

.PARAMETER AddressFamily
Filter by IP Address family: IPv4, IPv6 or Any (both).

If specified, we display any result where both the localaddress and the remoteaddress is in the address family.

.EXAMPLE
PS> Get-NetworkStatistics | Format-Table

.EXAMPLE
PS> Get-NetworkStatistics iexplore -Domain k-it-thin-02 -ShowHostNames | Format-Table

.EXAMPLE
PS> Get-NetworkStatistics -ProcessName md* -Protocol TCP

.EXAMPLE
PS> Get-NetworkStatistics -Address 192* -State LISTENING

.EXAMPLE
PS> Get-NetworkStatistics -State LISTENING -Protocol TCP

.EXAMPLE
PS> Get-NetworkStatistics -Domain Computer1, Computer2

.EXAMPLE
PS> 'Computer1', 'Computer2' | Get-NetworkStatistics

.INPUTS
[string]

.OUTPUTS
[System.Management.Automation.PSCustomObject]

.NOTES
Author: Shay Levy, code butchered by Cookie Monster
Shay's Blog: http://PowerShay.com
Cookie Monster's Blog: http://ramblingcookiemonster.github.io/

Modifications by metablaster January 2021:
Added #Requires statement, missing Parameter and SupportsWildcards attributes
Replaced Invoke-WmiMethod with Invoke-CimMethod
Updated formatting, casing and naming according to the rest of project
Converted to script by removing function
Updated comment based help
Fixed getting process list from remote computer with Invoke-Command instead of Get-Process
Changed default for AddressFamily from * to Any

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
	[string] $Address = "*",

	[Parameter(Position = 2)]
	[SupportsWildcards()]
	[ValidatePattern("[\*\d\?\[\]]")]
	[string] $Port = "*",

	[Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
	[Alias("ComputerName", "CN")]
	[string[]] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[ValidateSet("*", "TCP", "UDP")]
	[string] $Protocol = "*",

	[Parameter()]
	[ValidateSet("*", "Closed", "Close_Wait", "Closing", "Delete_Tcb", "DeleteTcb", "Established", "Fin_Wait_1",
		"Fin_Wait_2", "Last_Ack", "Listening", "Syn_Received", "Syn_Sent", "Time_Wait", "Unknown")]
	[string] $State = "*",

	[Parameter()]
	[switch] $ShowHostNames,

	[Parameter()]
	[switch] $ShowProcessNames,

	[Parameter()]
	[string] $TempFile = "C:\netstat.txt",

	[Parameter()]
	[ValidateSet("Any", "IPv4", "IPv6")]
	[string] $AddressFamily = "Any"
)

begin
{
	# Define properties
	$Properties = "ComputerName", "Protocol", "LocalAddress", "LocalPort", "RemoteAddress", "RemotePort", "State", "ProcessName", "PID"

	# Store hostnames in array for quick lookup
	$DnsCache = @{}
}

process
{
	foreach ($Computer in $Domain)
	{
		# Handle remote systems
		if ($Computer -eq [System.Environment]::MachineName)
		{
			# Collect processes
			if ($ShowProcessNames)
			{
				$Processes = Get-Process -ErrorAction Stop | Select-Object Name, Id
			}

			# Gather results on local PC
			$Results = netstat -ano | Select-String -Pattern "\s+(TCP|UDP)"
		}
		else
		{
			# Collect processes
			if ($ShowProcessNames)
			{
				try
				{
					$Processes = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-Process } -ErrorAction Stop | Select-Object Name, Id
				}
				catch
				{
					Write-Warning "Unable to run Get-Process on computer $Computer, defaulting to no ShowProcessNames"
					$ShowProcessNames = $false
				}
			}

			# Define command
			[string] $cmd = "cmd /c c:\windows\system32\netstat.exe -ano >> $TempFile"

			# Define remote file path - computername, drive, folder path
			$RemoteTempFile = "\\{0}\{1}`${2}" -f "$Computer", (Split-Path $TempFile -Qualifier).TrimEnd(":"), (Split-Path $TempFile -NoQualifier)

			# Delete previous results
			try
			{
				Invoke-CimMethod -ClassName Win32_process -MethodName Create -ComputerName $Computer `
					-Arguments @{ CommandLine = "cmd /c del $TempFile" } -ErrorAction Stop | Out-Null
			}
			catch
			{
				Write-Warning "Could not invoke create win32_process on $Computer to delete $TempFile"
			}

			# Run command
			try
			{
				$ProcessID = (Invoke-CimMethod -ClassName Win32_process -MethodName Create `
						-Arguments @{ CommandLine = $cmd } -ComputerName $Computer -ErrorAction Stop).ProcessId
			}
			catch
			{
				# If we didn't run netstat, continue with next computer
				Write-Error -ErrorRecord $_
				continue
			}

			# Wait for process to complete
			while (
				# This while should return true until the process completes
				$(
					try
					{
						Get-Process -Id $ProcessID -ComputerName $Computer -ErrorAction Stop
					}
					catch
					{
						$false
					}
				)
			)
			{
				Start-Sleep -Seconds 2
			}

			# Gather results
			if (Test-Path $RemoteTempFile)
			{
				try
				{
					$Results = Get-Content $RemoteTempFile | Select-String -Pattern "\s+(TCP|UDP)"
				}
				catch
				{
					Write-Error -Category ReadError -TargetObject $RemoteTempFile `
						-Message "Could not get content from $RemoteTempFile for results"
					continue
				}

				Remove-Item $RemoteTempFile -Force
			}
			else
			{
				Write-Error -Category ReadError -TargetObject $RemoteTempFile `
					-Message "'$TempFile' on $Computer converted to '$RemoteTempFile', this path is not accessible from your system."
				continue
			}
		}

		# Initialize counter for progress
		$TotalCount = $Results.Count
		$Count = 0

		# Loop through each line of results
		foreach ($Result in $Results)
		{
			$Item = $Result.Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

			if ($Item[1] -notmatch "^\[::")
			{
				# Parse the netstat line for local address and port
				$la = $Item[1] -as [IPAddress]
				if ($la.AddressFamily -eq 'InterNetworkV6')
				{
					$LocalAddress = $la.IPAddressToString
					$LocalPort = $Item[1].Split("\]:")[-1]
				}
				else
				{
					$LocalAddress = $Item[1].Split(":")[0]
					$LocalPort = $Item[1].Split(":")[-1]
				}

				# Parse the netstat line for remote address and port
				$ra = $Item[2] -as [IPAddress]
				if ($ra.AddressFamily -eq 'InterNetworkV6')
				{
					$RemoteAddress = $ra.IPAddressToString
					$RemotePort = $Item[2].Split("\]:")[-1]
				}
				else
				{
					$RemoteAddress = $Item[2].Split(":")[0]
					$RemotePort = $Item[2].Split(":")[-1]
				}

				# Filter IPv4/IPv6 if specified
				if ($AddressFamily -ne "Any")
				{
					if (($AddressFamily -eq "IPv4") -and ($LocalAddress -match ":") -and ($RemoteAddress -match ":|\*" ))
					{
						# Both are IPv6, or ipv6 and listening, skip
						Write-Verbose "Filtered by AddressFamily:`n$Result"
						continue
					}
					elseif (($AddressFamily -eq "IPv6") -and ($LocalAddress -notmatch ":") -and (($RemoteAddress -notmatch ":") -or ($RemoteAddress -match "*" )))
					{
						# Both are IPv4, or ipv4 and listening, skip
						Write-Verbose "Filtered by AddressFamily:`n$Result"
						continue
					}
				}

				# Parse the netstat line for other properties
				$ProcessID = $Item[-1]
				$Proto = $Item[0]
				$Status = if ($Item[0] -eq "tcp") { $Item[3] } else { $null }

				# Filter the object
				if (($RemotePort -notlike $Port) -and ($LocalPort -notlike $Port))
				{
					Write-Verbose "remote $RemotePort local $localport port $Port"
					Write-Verbose "Filtered by Port:`n$Result"
					continue
				}

				if (($RemoteAddress -notlike $Address) -and ($LocalAddress -notlike $Address))
				{
					Write-Verbose "Filtered by Address:`n$Result"
					continue
				}

				if ($Status -notlike $State)
				{
					Write-Verbose "Filtered by State:`n$Result"
					continue
				}

				if ($Proto -notlike $Protocol)
				{
					Write-Verbose "Filtered by Protocol:`n$Result"
					continue
				}

				# Display progress bar prior to getting process name or host name
				Write-Progress -Activity "Resolving host and process names" `
					-Status "Resolving process ID $ProcessID with remote address $RemoteAddress and local address $LocalAddress"`
					-PercentComplete (( $Count / $TotalCount ) * 100)

				# If we are running ShowProcessNames, get the matching name
				if ($ShowProcessNames -or ($PSBoundParameters.ContainsKey -eq "ProcessName"))
				{
					# Handle case where process spun up in the time between running get-process and running netstat
					if ($ProcName = $Processes | Where-Object { $_.id -eq $ProcessID } | Select-Object -ExpandProperty name ) { }
					else { $ProcName = "Unknown" }
				}
				else { $ProcName = "NA" }

				if ($ProcName -notlike $ProcessName)
				{
					Write-Verbose "Filtered by ProcessName:`n$Result"
					continue
				}

				# If the ShowHostnames switch is specified, try to map IP to hostname
				if ($ShowHostNames)
				{
					$TempAddress = $null
					try
					{
						if (($RemoteAddress -eq "127.0.0.1") -or ($RemoteAddress -eq "0.0.0.0"))
						{
							$RemoteAddress = $Computer
						}
						elseif ($RemoteAddress -match "\w")
						{
							# Check with dns cache first
							if ($DnsCache.ContainsKey($RemoteAddress))
							{
								$RemoteAddress = $DnsCache[$RemoteAddress]
								Write-Verbose "Using cached REMOTE '$RemoteAddress'"
							}
							else
							{
								# If address isn't in the cache, resolve it and add it
								$TempAddress = $RemoteAddress
								$RemoteAddress = [System.Net.DNS]::GetHostByAddress($RemoteAddress).HostName
								$DnsCache.Add($TempAddress, $RemoteAddress)
								Write-Verbose "Using non cached REMOTE '$RemoteAddress`t$TempAddress"
							}
						}
					}
					catch
					{
						Write-Error -ErrorRecord $_
					}

					try
					{
						if (($LocalAddress -eq "127.0.0.1") -or ($LocalAddress -eq "0.0.0.0"))
						{
							$LocalAddress = $Computer
						}
						elseif ($LocalAddress -match "\w")
						{
							# Check with dns cache first
							if ($DnsCache.ContainsKey($LocalAddress))
							{
								$LocalAddress = $DnsCache[$LocalAddress]
								Write-Verbose "Using cached LOCAL '$LocalAddress'"
							}
							else
							{
								# If address isn't in the cache, resolve it and add it
								$TempAddress = $LocalAddress
								$LocalAddress = [System.Net.DNS]::GetHostByAddress("$LocalAddress").hostname
								$DnsCache.Add($LocalAddress, $TempAddress)
								Write-Verbose "Using non cached LOCAL '$LocalAddress'`t'$TempAddress'"
							}
						}
					}
					catch
					{
						Write-Error -ErrorRecord $_
					}
				}

				# Write the object
				New-Object -TypeName PSCustomObject -Property @{
					ComputerName = $Computer
					PID = $ProcessID
					ProcessName = $ProcName
					Protocol = $Proto
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
	}
}

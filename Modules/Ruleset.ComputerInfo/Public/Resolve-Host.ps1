
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Resolve host or IP

.DESCRIPTION
Resolve host to IP or an IP to host.
For local host select virtual, hidden or connected adapters.

.PARAMETER Domain
Target host name which to resolve to an IP address.

.PARAMETER IPAddress
Target IP which to resolve to host name.

.PARAMETER FlushDNS
Flush DNS resolver cache before resolving IP or host name

.PARAMETER AddressFamily
Obtain IP address specified IP version

.PARAMETER Physical
Resolve local host name to an IP of a physical adapter

.PARAMETER Virtual
Resolve local host name to an IP of a virtual adapter

.PARAMETER Hidden
If specified, only hidden interfaces are included

.PARAMETER Connected
If specified, only interfaces connected to network are returned

.EXAMPLE
PS> Resolve-Host -AddressFamily IPv4 -IPAddress "40.112.72.205"

.EXAMPLE
PS> Resolve-Host -FlushDNS -Domain "microsoft.com"

.EXAMPLE
PS> Resolve-Host -LocalHost -AddressFamily IPv4 -Connected

.INPUTS
[IPAddress]
[string]

.OUTPUTS
[PSCustomObject]

.NOTES
TODO: Single IP is selected for result, maybe we should return all IP addresses
#>
function Resolve-Host
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Physical", SupportsShouldProcess = $true,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Resolve-Host.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(ParameterSetName = "Host", Mandatory = $true, HelpMessage = "Enter target domain name",
			ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain,

		[Parameter(ParameterSetName = "IP", Mandatory = $true, HelpMessage = "Enter target IP address",
			ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[IPAddress[]] $IPAddress,

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "IP")]
		[Switch] $FlushDNS,

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "Physical")]
		[Parameter(ParameterSetName = "Virtual")]
		[Alias("IPVersion")]
		[ValidateSet("IPv4", "IPv6", "Any")]
		[string] $AddressFamily = "Any",

		[Parameter(ParameterSetName = "Physical")]
		[switch] $Physical,

		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Virtual,

		[Parameter(ParameterSetName = "Physical")]
		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Hidden,

		[Parameter(ParameterSetName = "Physical")]
		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Connected
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		if ($FlushDNS)
		{
			# TODO: Should this be called only once for pipelines?
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Flushing DNS resolver cache"
			Clear-DnsClientCache
		}

		if ($IPAddress)
		{
			foreach ($IP in $IPAddress)
			{
				$Domain = $null
				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving IP: $IP"
					# https://docs.microsoft.com/en-us/dotnet/api/system.net.dns?view=net-5.0
					[System.Net.IPHostEntry] $HostEntry = [System.Net.Dns]::GetHostByAddress($IP)

					# TODO: Domain name may end up inside { }
					$Domain = $HostEntry.HostName
				}
				catch [System.Net.Sockets.SocketException]
				{
					Write-Warning -Message "Socket exception resolving address: $IP"
				}

				[PSCustomObject] @{
					Domain = $Domain
					IPAddress = $IP
				}
			}
		}
		elseif ($Physical -or $Virtual)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting local host $AddressFamily address for domain: $([System.Environment]::MachineName)"

			if ($Virtual)
			{
				$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily `
					-Connected:$Connected -Hidden:$Hidden -Virtual:$Virtual
			}
			else # Physical
			{
				$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily `
					-Connected:$Connected -Hidden:$Hidden -Physical
			}

			if ($ConfiguredInterfaces)
			{
				if ($AddressFamily -eq "Any")
				{
					# Microsoft.Management.Infrastructure.CimInstance#root/StandardCimv2/MSFT_NetIPAddress
					$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ("IPv4Address")

					if (!$NetIPAddress)
					{
						$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ("IPv6Address")
					}
				}
				else
				{
					$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ($AddressFamily + "Address")
				}

				[IPAddress] $IPAddress = $NetIPAddress | Select-Object -ExpandProperty IPAddress -Last 1

				[PSCustomObject] @{
					Domain = [System.Environment]::MachineName
					IPAddress = $IPAddress
				}
			}

			# NOTE: else error should be generated and shown by Select-IPInterface
		}
		else
		{
			foreach ($HostName in $Domain)
			{
				[IPAddress] $IPAddress = $null

				# For localhost with multiple interfaces fine tune selection
				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting remote host $AddressFamily address for domain: $HostName"

					[System.Net.IPHostEntry] $HostEntry = [System.Net.Dns]::GetHostByName($HostName)
					$IPAddress = $HostEntry.AddressList.IPAddressToString | Select-Object -Last 1
				}
				catch [System.Net.Sockets.SocketException]
				{
					Write-Warning -Message "Socket exception resolving host: $HostName"
				}
				catch
				{
					Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
				}

				if (!$IPAddress)
				{
					# [Microsoft.DnsClient.Commands.DnsRecord]
					$DNSRecord = Resolve-DnsName -Name $HostName -NetbiosFallback -Server 8.8.8.8
					if ($AddressFamily -eq "IPv4")
					{
						$IPAddress = $DNSRecord.IPAddress -match "([0-9]{1,3}\.){3}[0-9]{1,3}" |
						Select-Object -ExpandProperty IPAddress -Last 1
					}
					elseif ($AddressFamily -eq "IPv4")
					{
						$IPAddress = $DNSRecord.IPAddress -match "([a-f0-9:]+:)+[a-f0-9]+" |
						Select-Object -ExpandProperty IPAddress -Last 1
					}
					else
					{
						$IPAddress = $DNSRecord.IPAddress | Select-Object -ExpandProperty IPAddress -Last 1
					}
				}

				if (!$IPAddress)
				{
					$Ping = New-Object System.Net.NetworkInformation.Ping
					$IPAddress = ($Ping.Send($HostName).Address).IPAddressToString
				}

				[PSCustomObject] @{
					Domain = $HostName
					IPAddress = $IPAddress
				}
			}
		}
	}
}

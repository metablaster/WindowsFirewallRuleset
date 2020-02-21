
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

# Includes
Import-Module -Name $PSScriptRoot\..\Indented.Net.IP

# TODO: what happens in Get-AdapterConfig and other functions that call it if there are multiple configured adapters?

<#
.SYNOPSIS
get localhost name
.EXAMPLE
Get-ComputerName
.INPUTS
None. You cannot pipe objects to Get-ComputerName
.OUTPUTS
System.String computer name in form of COMPUTERNAME
.NOTES
TODO: implement queriying computers on network by specifying IP address
#>
function Get-ComputerName
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Learning computer name"
	return [Environment]::MachineName
}

<#
.SYNOPSIS
Method to get connected adapters
.DESCRIPTION
Return list of all adapters and their configuration connected to network
.PARAMETER AddressFamily
IP version for which to obtain adapters, IPv4 or IPv6
.EXAMPLE
Get-ConnectedAdapters "IPv4"
.EXAMPLE
Get-ConnectedAdapters "IPv6"
.INPUTS
None. You cannot pipe objects to Get-ConnectedAdapters
.OUTPUTS
NetIPConfiguration
.NOTES
TODO: implement queriying computers on network by specifying IP address or COMPUTERNAME
#>
function Get-ConnectedAdapters
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet("IPv4", "IPv6")]
		[string] $AddressFamily
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($AddressFamily.ToString() -eq "IPv4")
	{
		$ConnectedAdapters = Get-NetIPConfiguration | Where-Object -Property IPv4DefaultGateway
	}
	else
	{
		$ConnectedAdapters = Get-NetIPConfiguration | Where-Object -Property IPv6DefaultGateway
	}

	if ($ConnectedAdapters.Count -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $ConnectedAdapters `
		-Message "None of the adapters is connected to $AddressFamily network"
	}
	elseif ($ConnectedAdapters.Count -gt 1)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Multiple adapters are connected to $AddressFamily network"
	}

	return $ConnectedAdapters
}

<#
.SYNOPSIS
Method to get IP address of local machine
.DESCRIPTION
Returns list of IP addresses for all adapters connected to network
.PARAMETER AddressFamily
IP version for which to obtain address, IPv4 or IPv6
.EXAMPLE
Get-IPAddress "IPv4"
.EXAMPLE
Get-IPAddress "IPv6"
.INPUTS
None. You cannot pipe objects to Get-IPAddress
.OUTPUTS
System.String IP Address
.NOTES
TODO: implement queriying computers on network by specifying COMPUTERNAME
#>
function Get-IPAddress
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet("IPv4", "IPv6")]
		[string] $AddressFamily
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting IP's of connected adapters for $AddressFamily network"
	$ConnectedAdapters = Get-ConnectedAdapters $AddressFamily | Select-Object -ExpandProperty ($AddressFamily + "Address")
	$IPAddress = $ConnectedAdapters | Select-Object -ExpandProperty IPAddress

	if ($IPAddress.Count -gt 1)
	{
		# TODO: bind result to custom function
		Write-Information -Tags "User" -MessageData "[$($MyInvocation.InvocationName)] Returning multiple IP addresses: $IPAddress" `
		-Tags Result 6>&1 | Select-Object * | Tee-Object -FilePath "$RepoDir\Logs\Info.log" | Select-Object -ExpandProperty MessageData
	}
	elseif ($IPAddress.Count -eq 0)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Returning empty string"
	}

	return $IPAddress
}

<#
.SYNOPSIS
Method to get broadcast address
.EXAMPLE
Get-Broadcast
.INPUTS
None. You cannot pipe objects to Get-Broadcast
.OUTPUTS
System.String Broadcast address
.NOTES
TODO: there can be multiple valid adapters
#>
function Get-Broadcast
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	# Broadcast address makes sense only for IPv4
	$ConnectedAdapters = Get-ConnectedAdapters "IPv4" | Select-Object -ExpandProperty IPv4Address

	if ($ConnectedAdapters.Count -gt 0)
	{
		if ($ConnectedAdapters.Count -gt 1)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] got multiple adapters, using first one"
			$ConnectedAdapters = $ConnectedAdapters | Select-Object -First 1
		}

		$IPAddress = $ConnectedAdapters | Select-Object -ExpandProperty IPAddress
		$SubnetMask = ConvertTo-Mask ($ConnectedAdapters | Select-Object -ExpandProperty PrefixLength)

		$Broadcast = Get-NetworkSummary $IPAddress $SubnetMask |
		Select-Object -ExpandProperty BroadcastAddress |
		Select-Object -ExpandProperty IPAddressToString

		Write-Information -Tags "User" -MessageData "Network broadcast address is: $Broadcast"
		return $Broadcast
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] returns null"
}

#
# Function exports
#

Export-ModuleMember -Function Get-ComputerName
Export-ModuleMember -Function Get-IPAddress
Export-ModuleMember -Function Get-ConnectedAdapters
Export-ModuleMember -Function Get-Broadcast

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	$ThisModule = $MyInvocation.MyCommand.Name -replace ".{5}$"

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

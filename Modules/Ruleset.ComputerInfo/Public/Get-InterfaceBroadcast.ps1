
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Get interface broadcast address

.DESCRIPTION
Get broadcast addresses for either physical or virtual network interfaces.
Returned broadcast addresses are IPv4 and only for adapters connected to network.

.PARAMETER Domain
Computer name which to query

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER Physical
If specified, include only physical adapters

.PARAMETER Virtual
If specified, include only virtual adapters.
By default only physical adapters are reported

.PARAMETER Visible
If specified, only visible interfaces are included

.PARAMETER Hidden
If specified, only hidden interfaces are included

.EXAMPLE
PS> Get-InterfaceBroadcast -Physical

.EXAMPLE
PS> Get-InterfaceBroadcast -Virtual -Hidden

.INPUTS
None. You cannot pipe objects to Get-InterfaceBroadcast

.OUTPUTS
[string] Broadcast addresses

.NOTES
None.
#>
function Get-InterfaceBroadcast
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceBroadcast.md")]
	[OutputType([string])]
	param (
		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "Domain")]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Session")]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter()]
		[switch] $Physical,

		[Parameter()]
		[switch] $Virtual,

		[Parameter()]
		[switch] $Visible,

		[Parameter()]
		[switch] $Hidden
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}

	if ($PSCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session
	}
	else
	{
		$Domain = Format-ComputerName $Domain

		# Avoiding NETBIOS ComputerName for localhost means no need for WinRM to listen on HTTP
		if ($Domain -ne [System.Environment]::MachineName)
		{
			$SessionParams.ComputerName = $Domain
			if ($Credential)
			{
				$SessionParams.Credential = $Credential
			}
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting broadcast addresses of connected adapters"

	$Params = @{
		# Broadcast address makes sense only for IPv4
		AddressFamily = "IPv4"
		Connected = $true
		Physical = $true
		Virtual = $true
		Visible = $true
		Hidden = $true
		ErrorAction = "Stop"
	}

	if ($Physical -and !$Virtual)
	{
		$Params.Virtual = $false
	}
	elseif ($Virtual -and !$Physical)
	{
		$Params.Physical = $false
	}

	if ($Visible -and !$Hidden)
	{
		$Params.Hidden = $false
	}
	elseif ($Hidden -and !$Visible)
	{
		$Params.Visible = $false
	}

	$ConfiguredAdapters = Select-IPInterface @SessionParams @Params

	if ($ConfiguredAdapters)
	{
		$ConfiguredAdapters = $ConfiguredAdapters | Select-Object -ExpandProperty IPv4Address
		$Count = ($ConfiguredAdapters | Measure-Object).Count

		if ($Count -gt 0)
		{
			[string[]] $BroadcastAddress = @()
			foreach ($Adapter in $ConfiguredAdapters)
			{
				[IPAddress] $IPAddress = $Adapter | Select-Object -ExpandProperty IPAddress
				$SubnetMask = ConvertTo-Mask ($Adapter | Select-Object -ExpandProperty PrefixLength)

				$BroadcastAddress += Get-NetworkSummary $IPAddress $SubnetMask |
				Select-Object -ExpandProperty BroadcastAddress |
				Select-Object -ExpandProperty IPAddressToString
			}

			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Network broadcast addresses are: $BroadcastAddress"
			Write-Output $BroadcastAddress
			return
		}
	}
	else
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] None of the adapters match the parameter set"
	}
}

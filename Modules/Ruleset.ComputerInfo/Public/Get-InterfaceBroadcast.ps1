
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

.PARAMETER Virtual
If specified, include only virtual adapters.
By default only physical adapters are reported

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
		[switch] $Virtual,

		[Parameter()]
		[switch] $Hidden
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	$Domain = Format-ComputerName $Domain

	if ($PSCmdlet.ParameterSetName -eq "Session")
	{
		$Domain = $Session.ComputerName
		$SessionParams.Session = $Session
	}
	else
	{
		$SessionParams.ComputerName = $Domain
		if ($Credential)
		{
			$SessionParams.Credential = $Credential
		}
	}

	$SessionParams.ErrorAction = "Stop"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting broadcast address of connected adapters"

	try
	{
		# Broadcast address makes sense only for IPv4
		# NOTE: Using Invoke-Command on localhost to avoid code bloat
		$ConfiguredAdapters = Invoke-Command @SessionParams -ScriptBlock {
			if ($using:Virtual)
			{
				Select-IPInterface -AddressFamily IPv4 -Connected -Virtual -Hidden:$using:Hidden -ErrorAction SilentlyContinue
			}
			else
			{
				Select-IPInterface -AddressFamily IPv4 -Connected -Physical -Hidden:$using:Hidden -ErrorAction SilentlyContinue
			}
		}
	}
	catch
	{
		# try\catch handles error with Invoke-Command only
		Write-Error -ErrorRecord $_
		return
	}

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
		Write-Warning -Message "[$($MyInvocation.InvocationName)] None of the adapters matches parameter set"
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] returns null"
}

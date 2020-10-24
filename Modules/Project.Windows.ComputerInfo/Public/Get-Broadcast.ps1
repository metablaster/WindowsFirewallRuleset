
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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

<#
.SYNOPSIS
Method to get broadcast addresses on local machine
.DESCRIPTION
Return multiple broadcast addresses, for each configured adapter.
This includes both physical and virtual adapters.
Returned broadcast addresses are only for IPv4
.PARAMETER IncludeAll
Include all possible adapter types present on target computer
.PARAMETER ExcludeHardware
Exclude hardware/physical network adapters
.PARAMETER IncludeVirtual
Whether to include virtual adapters
.PARAMETER IncludeHidden
Whether to include hidden adapters
.PARAMETER IncludeDisconnected
Whether to include disconnected
.EXAMPLE
TODO: provide examples
.INPUTS
None. You cannot pipe objects to Get-Broadcast
.OUTPUTS
[IPAddress[]] Array of broadcast addresses
.NOTES
None.
#>
function Get-Broadcast
{
	[OutputType([System.Net.IPAddress[]])]
	[CmdletBinding(DefaultParameterSetName = "Individual",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ComputerInfo/Help/en-US/Get-Broadcast.md")]
	param (
		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting broadcast address of connected adapters"

	# Broadcast address makes sense only for IPv4
	if ($IncludeAll)
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter IPv4 `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter IPv4 `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	$ConfiguredAdapters = $ConfiguredAdapters | Select-Object -ExpandProperty IPv4Address
	$Count = ($ConfiguredAdapters | Measure-Object).Count

	if ($Count -gt 0)
	{
		[IPAddress[]] $Broadcast = @()
		foreach ($Adapter in $ConfiguredAdapters)
		{
			[IPAddress] $IPAddress = $Adapter | Select-Object -ExpandProperty IPAddress
			$SubnetMask = ConvertTo-Mask ($Adapter | Select-Object -ExpandProperty PrefixLength)

			$Broadcast += Get-NetworkSummary $IPAddress $SubnetMask |
			Select-Object -ExpandProperty BroadcastAddress |
			Select-Object -ExpandProperty IPAddressToString
		}

		Write-Information -Tags "Result" -MessageData "INFO: Network broadcast addresses are: $Broadcast"
		return $Broadcast
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] returns null"
}

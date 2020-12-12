
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
Retrieve a list of IP addresses on local machine

.DESCRIPTION
Returns list of IPAddress objects for all configured adapters.
This could include both physical and virtual adapters.

.PARAMETER AddressFamily
IP version for which to obtain address, IPv4 or IPv6

.PARAMETER ExcludeHardware
Exclude hardware/physical network adapters

.PARAMETER IncludeAll
Include all possible adapter types present on target computer

.PARAMETER IncludeVirtual
Whether to include virtual adapters

.PARAMETER IncludeHidden
Whether to include hidden adapters

.PARAMETER IncludeDisconnected
Whether to include disconnected

.EXAMPLE
PS> Get-IPAddress "IPv4"

.EXAMPLE
PS> Get-IPAddress "IPv6"

.INPUTS
None. You cannot pipe objects to Get-IPAddress

.OUTPUTS
[ipaddress] Array of IP addresses and warning message if no adapter connected

.NOTES
None.
#>
function Get-IPAddress
{
	[CmdletBinding(DefaultParameterSetName = "Individual",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-IPAddress.md")]
	[OutputType([ipaddress])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("IPv4", "IPv6")]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[string] $AddressFamily,

		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[switch] $ExcludeHardware,

		[Parameter(ParameterSetName = "All")]
		[switch] $IncludeAll,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeVirtual,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeHidden,

		[Parameter(ParameterSetName = "Individual")]
		[switch] $IncludeDisconnected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting IP's of connected adapters for $AddressFamily network"

	if ($IncludeAll)
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter $AddressFamily `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredAdapters = Get-ConfiguredAdapter $AddressFamily `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	[ipaddress[]] $IPAddress = $ConfiguredAdapters |
	Select-Object -ExpandProperty ($AddressFamily + "Address") |
	Select-Object -ExpandProperty IPAddress

	$Count = ($IPAddress | Measure-Object).Count
	if ($Count -gt 1)
	{
		# TODO: bind result to custom function
		Write-Information -Tags "Result" -MessageData "INFO: Computer has multiple IP addresses: $IPAddress"
	}
	elseif ($Count -eq 0)
	{
		Write-Warning -Message "Computer not connected to $AddressFamily network, IP address will be missing"
	}

	return $IPAddress
}

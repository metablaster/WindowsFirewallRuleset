
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
Method to get aliases of configured adapters

.DESCRIPTION
Return list of interface aliases of all configured adapters.
Applies to adapters which have an IP assigned regardless if connected to network.
This may include virtual adapters as well such as Hyper-V adapters on all compartments.

.PARAMETER AddressFamily
IP version for which to obtain adapters, IPv4 or IPv6

.PARAMETER WildCardOption
TODO: describe parameter

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
PS> Get-InterfaceAlias "IPv4"

.EXAMPLE
PS> Get-InterfaceAlias "IPv6"

.INPUTS
None. You cannot pipe objects to Get-InterfaceAlias

.OUTPUTS
[System.Management.Automation.WildcardPattern]

.NOTES
None.
TODO: There is another function with the same name in Scripts folder
TODO: shorter parameter names: Virtual, All, Hidden, Hardware
#>
function Get-InterfaceAlias
{
	[CmdletBinding(DefaultParameterSetName = "Individual",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceAlias.md")]
	[OutputType([System.Management.Automation.WildcardPattern])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("IPv4", "IPv6")]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[string] $AddressFamily,

		[Parameter(Mandatory = $false)]
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Individual")]
		[System.Management.Automation.WildcardOptions]
		$WildCardOption = [System.Management.Automation.WildcardOptions]::None,

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
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($IncludeAll)
	{
		$ConfiguredInterfaces = Get-ConfiguredAdapter $AddressFamily `
			-IncludeAll:$IncludeAll -ExcludeHardware:$ExcludeHardware
	}
	else
	{
		$ConfiguredInterfaces = Get-ConfiguredAdapter $AddressFamily `
			-IncludeVirtual:$IncludeVirtual -ExcludeHardware:$ExcludeHardware `
			-IncludeHidden:$IncludeHidden -IncludeDisconnected:$IncludeDisconnected
	}

	if (!$ConfiguredInterfaces)
	{
		# NOTE: Error should be generated and shown by Get-ConfiguredAdapter
		return $null
	}

	[string[]] $InterfaceAliases = $ConfiguredInterfaces | Select-Object -ExpandProperty InterfaceAlias
	if ($InterfaceAliases.Length -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $InterfaceAliases `
			-Message "None of the adapters matches search criteria to get interface aliases from"
		return
	}

	[WildcardPattern[]] $InterfaceAliasPattern = @()
	foreach ($Alias in $InterfaceAliases)
	{
		if ([WildcardPattern]::ContainsWildcardCharacters($Alias))
		{
			Write-Warning -Message "$Alias Interface alias contains wildcard pattern"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Interface alias '$Alias' does not contain wildcard pattern"
		}

		$InterfaceAliasPattern += [WildcardPattern]::new($Alias, $WildCardOption)
	}

	if ($InterfaceAliasPattern.Length -eq 0)
	{
		Write-Error -Category ObjectNotFound -TargetObject $InterfaceAliasPattern `
			-Message "Creating interface alias patterns failed"
	}
	elseif ($InterfaceAliasPattern.Length -gt 1)
	{
		Write-Information -Tags "User" -MessageData "INFO: Got multiple adapter aliases"
	}

	return $InterfaceAliasPattern
}

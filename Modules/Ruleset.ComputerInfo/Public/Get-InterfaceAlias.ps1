
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Get interface aliases of specified network adapters

.DESCRIPTION
Get a list of interface aliases of specified network adapters.
This function takes care of interface aliases with wildcard patterns, by replacing them with
escape codes which is required to create valid fiewall rule based on interface alias.

.PARAMETER AddressFamily
Obtain interface aliases configured for specific IP version

.PARAMETER WildCardOption
Specify wildcard options that modify the wildcard patterns found in interface alias strings.
Compiled:
The wildcard pattern is compiled to an assembly.
This yields faster execution but increases startup time.
CultureInvariant:
Specifies culture-invariant matching.
IgnoreCase:
Specifies case-insensitive matching.
None:
Indicates that no special processing is required.

.PARAMETER Physical
If specified, include only physical adapters

.PARAMETER Virtual
If specified, include only virtual adapters

.PARAMETER Hidden
If specified, only hidden interfaces are included

.PARAMETER Connected
If specified, only interfaces connected to network are returned

.EXAMPLE
PS> Get-InterfaceAlias "IPv4"

.EXAMPLE
PS> Get-InterfaceAlias "IPv4" -Physical

.EXAMPLE
PS> Get-InterfaceAlias "IPv6" -WildcardOption "IgnoreCase"

.INPUTS
None. You cannot pipe objects to Get-InterfaceAlias

.OUTPUTS
[WildcardPattern]

.NOTES
TODO: There is another function with the same name in Scripts folder
#>
function Get-InterfaceAlias
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceAlias.md")]
	[OutputType([WildcardPattern])]
	param (
		[Parameter()]
		[Alias("IPVersion")]
		[ValidateSet("IPv4", "IPv6", "Any")]
		[string] $AddressFamily = "Any",

		[Parameter()]
		[System.Management.Automation.WildcardOptions] $WildCardOption = "None",

		[Parameter(ParameterSetName = "Physical")]
		[switch] $Physical,

		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Virtual,

		[Parameter()]
		[switch] $Hidden,

		[Parameter()]
		[switch] $Connected
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting connected adapters for $AddressFamily network"

	if ($Physical)
	{
		$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily `
			-Connected:$Connected -Hidden:$Hidden -Physical:$Physical
	}
	else
	{
		$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily `
			-Connected:$Connected -Hidden:$Hidden -Virtual:$Virtual
	}

	if (!$ConfiguredInterfaces)
	{
		# NOTE: Error should be generated and shown by Select-IPInterface
		return $null
	}

	[WildcardPattern[]] $EscapedAliasPattern = @()
	$InterfaceAliases = $ConfiguredInterfaces | Select-Object -ExpandProperty InterfaceAlias

	foreach ($Alias in $InterfaceAliases)
	{
		if ([WildcardPattern]::ContainsWildcardCharacters($Alias))
		{
			Write-Warning -Message "$Alias interface alias contains wildcard pattern"

			# NOTE: If WildCardOption == None, the pattern does not have wild cards
			$AliasPattern = [WildcardPattern]::new($Alias, $WildCardOption)
			$EscapedAliasPattern += [WildcardPattern]::Escape($AliasPattern)
		}
		else
		{
			$EscapedAliasPattern += $Alias
		}
	}

	Write-Output $EscapedAliasPattern
}

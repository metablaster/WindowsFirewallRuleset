
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Convert TCP\IP protocol number

.DESCRIPTION
ConvertFrom-Protocol converts TCP\IP protocol number to string representation

.PARAMETER Protocol
TCP\IP protocol number which is to be converted

.PARAMETER FirewallCompatible
Conversion is compatible with Windows firewall

.EXAMPLE
PS> ConvertFrom-Protocol 41

.EXAMPLE
PS> ConvertFrom-Protocol 17 -FirewallCompatible

.INPUTS
None. You cannot pipe objects to ConvertFrom-Protocol

.OUTPUTS
[string]
[int32]

.NOTES
None.
#>
function ConvertFrom-Protocol
{
	[CmdletBinding()]
	[OutputType([string], [int32])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateRange(0, 255)]
		[int32] $Protocol,

		[Parameter()]
		[switch] $FirewallCompatible
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($FirewallCompatible)
	{
		switch ($Protocol)
		{
			1 { "ICMPv4"; break }
			6 { "TCP"; break }
			17 { "UDP"; break }
			58 { "ICMPv6"; break }
			default { $Protocol }
		}
	}
	else
	{
		switch ($Protocol)
		{
			# TODO: This switch is incomplete
			1 { "ICMPv4"; break }
			2 { "IGMP"; break }
			6 { "TCP"; break }
			17 { "UDP"; break }
			41 { "IPv6"; break }
			58 { "ICMPv6"; break }
			default { $Protocol }
		}
	}
}

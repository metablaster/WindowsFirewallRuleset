
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

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
Format computer name to NETBIOS format

.DESCRIPTION
Format-ComputerName formats computer name string to NETBIOS format

.PARAMETER Domain
Computer name which to format

.EXAMPLE
PS> Format-ComputerName localhost

NETBIOSNAME

.EXAMPLE
PS> Format-ComputerName server01

SERVER01

.INPUTS
[string]

.OUTPUTS
None. Format-ComputerName does not generate any output

.NOTES
TODO: Need to handle FQDN
#>
function Format-ComputerName
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Format-ComputerName.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("ComputerName", "CN")]
		[string] $Domain
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (($Domain -eq [System.Environment]::MachineName) -or ($Domain -eq "localhost") -or ($Domain -eq "."))
	{
		[System.Environment]::MachineName
	}
	else
	{
		$Domain.ToUpper()
	}
}

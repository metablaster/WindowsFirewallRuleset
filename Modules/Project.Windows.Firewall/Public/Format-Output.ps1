
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
Format firewall rule output for display

.DESCRIPTION
Output of Net-NewFirewallRule is large, loading a lot of rules would spam the console
very fast, this function helps to output only relevant, formatted and colored output

.PARAMETER Rule
Firewall rule to format

.PARAMETER Label
Optional new label to replace default one

.EXAMPLE
PS> Net-NewFirewallRule ... | Format-Output

.INPUTS
Microsoft.Management.Infrastructure.CimInstance Firewall rule to format

.OUTPUTS
None. Format-Output does not generate any output

.NOTES
None.
#>
function Format-Output
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Justification = "There is no way to replace Write-Host here")]
	[OutputType([void])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.Firewall/Help/en-US/Format-Output.md")]
	param (
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[Microsoft.Management.Infrastructure.CimInstance] $Rule,

		[Parameter()]
		[string] $Label = "Load Rule"
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
		Write-Host "$($Label): [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
	}
}

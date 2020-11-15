
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Firewall rule to format, by default output status represents loading rule

.PARAMETER Modify
If specified, output status represents rule modification

.PARAMETER Import
If specified, output status represents importing rule

.EXAMPLE
PS> Net-NewFirewallRule ... | Format-Output

.INPUTS
[Microsoft.Management.Infrastructure.CimInstance[]]

.OUTPUTS
None. Format-Output does not generate any output

.NOTES
None.
#>
function Format-Output
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Justification = "There is no way to replace Write-Host here")]
	[CmdletBinding(DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-Output.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Microsoft.Management.Infrastructure.CimInstance[]] $Rule,

		[Parameter(ParameterSetName = "Modify")]
		[switch] $Modify,

		[Parameter(ParameterSetName = "Import")]
		[switch] $Import
	)

	begin
	{
		if ($Modify)
		{
			$Label = "Harden Rule"
		}
		elseif ($Import)
		{
			$Label = "Import Rule"
		}
		else
		{
			$Label = "Load Rule"
		}
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
		Write-Host "$($Label): [$($Rule | Select-Object -ExpandProperty DisplayGroup)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
	}
}

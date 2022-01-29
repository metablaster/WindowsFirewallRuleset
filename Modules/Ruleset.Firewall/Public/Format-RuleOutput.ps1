
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Format output of the Net-NewFirewallRule commandlet

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
PS> Net-NewFirewallRule ... | Format-RuleOutput

.EXAMPLE
PS> Net-NewFirewallRule ... | Format-RuleOutput -Import

.INPUTS
[Microsoft.Management.Infrastructure.CimInstance[]]

.OUTPUTS
None. Format-RuleOutput does not generate any output

.NOTES
TODO: For force loaded rules it should say: "Force Load Rule:"
#>
function Format-RuleOutput
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "Colored output is wanted")]
	[CmdletBinding(DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md")]
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
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		if ($Modify)
		{
			$Label = "Modify Rule"
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
		if ([string]::IsNullOrEmpty($Rule.DisplayGroup))
		{
			Write-Host "$($Label): $($Rule.DisplayName)" -ForegroundColor Cyan
		}
		else
		{
			Write-Host "$($Label): [$($Rule.DisplayGroup)] -> $($Rule.DisplayName)" -ForegroundColor Cyan
		}
	}
}

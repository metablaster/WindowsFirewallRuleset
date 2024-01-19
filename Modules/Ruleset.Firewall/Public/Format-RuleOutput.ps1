
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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

.PARAMETER Label
Specify action on how to format rule processing, acceptable values are:
Load, Modify, Import and Export.
The default value is "Load" which represent loading rule into firewall.

.PARAMETER ForegroundColor
Optionally specify text color of the output.
For acceptable color values see link section
The default is Cyan.

.EXAMPLE
PS> Net-NewFirewallRule ... | Format-RuleOutput

.EXAMPLE
PS> Net-NewFirewallRule ... | Format-RuleOutput -ForegroundColor Red -Label Modify

.INPUTS
[Microsoft.Management.Infrastructure.CimInstance[]]

.OUTPUTS
[string] colored version

.NOTES
TODO: For force loaded rules it should say: "Force Load Rule:"
TODO: Implementation needed to format rules which are not CimInstance see,
Remove-FirewallRule and Export-RegistryRule

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor
#>
function Format-RuleOutput
{
	[CmdletBinding(DefaultParameterSetName = "None", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("InputObject")]
		[Microsoft.Management.Infrastructure.CimInstance[]] $Rule,

		[Parameter()]
		[ValidateSet("Load", "Modify", "Import", "Export", "Remove")]
		[string] $Label = "Load",

		[Parameter()]
		[ConsoleColor] $ForegroundColor = [ConsoleColor]::Cyan
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$DisplayLabel = switch ($Label)
		{
			"Load" { "Load Rule"; break }
			"Modify" { "Modify Rule"; break }
			"Import" { "Import Rule"; break }
			"Export" { "Export Rule"; break }
			"Remove" { "Export Rule"; break }
		}
	}
	process
	{
		if ([string]::IsNullOrEmpty($Rule.DisplayGroup))
		{
			Write-ColorMessage "$($DisplayLabel): $($Rule.DisplayName)" $ForegroundColor
		}
		else
		{
			Write-ColorMessage "$($DisplayLabel): [$($Rule.DisplayGroup)] -> $($Rule.DisplayName)" $ForegroundColor
		}
	}
}

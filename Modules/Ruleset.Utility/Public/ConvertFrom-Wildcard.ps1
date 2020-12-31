
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
Convert wildcard pattern to regex

.DESCRIPTION
ConvertFrom-Wildcard converts wildcard pattern to regex equivalent and returns regex object
initialized with regex pattern

.PARAMETER Wildcard
Wildcard which to convert to regex object

.PARAMETER Options
Optionally specify regex options.
By default no options are set.

.PARAMETER TimeSpan
Optionally specify a time-out interval.
By default pattern-matching operation does not time out.

.PARAMETER AsRegex
Construct regex object in place with specified parameters.

.EXAMPLE
PS> ConvertFrom-Wildcard "*PowerShell*"

[string] regex pattern: .*PowerShell.*

.EXAMPLE
PS> $Regex = ConvertFrom-Wildcard "Po?er[A-Z]hell*" -AsRegex -TimeSpan ([System.TimeSpan]::FromSeconds(3))

[regex] set to pattern: ^Po.er[A-Z]hell.*

.EXAMPLE
PS> ConvertFrom-Wildcard "*[0-9][[]Po?er[A-Z]he*l?"

[string] regex pattern: .*[0-9][[]Po.er[A-Z]he.*l.$

.EXAMPLE
PS> $Regex = ConvertFrom-Wildcard "MatchThis*" -AsRegex -Options "IgnoreCase"

[regex] case insensitive regex set to pattern: MatchThis.*

.INPUTS
None. You cannot pipe objects to ConvertFrom-Wildcard

.OUTPUTS
[regex]
[string]

.NOTES
TODO: Convert from [WildcardPattern] object

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regexoptions?view=net-5.0
#>
function ConvertFrom-Wildcard
{
	[OutputType([regex], [string])]
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "String",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("Pattern")]
		[string] $Wildcard,

		[Parameter(ParameterSetName = "Regex")]
		[System.Text.RegularExpressions.RegexOptions] $Options = "None",

		[Parameter(ParameterSetName = "Regex")]
		[System.TimeSpan] $TimeSpan = [regex]::InfiniteMatchTimeout,

		[Parameter(Mandatory = $true, ParameterSetName = "Regex",
			HelpMessage = "ConvertFrom-Wildcard must be run with -AsRegex switch when either -Options or -TimeSpan is set")]
		[switch] $AsRegex
	)

	if ([WildcardPattern]::ContainsWildcardCharacters($Wildcard))
	{
		[string] $Pattern = [regex]::Escape($Wildcard)

		# NOTE: It makes no point to set TimeSpan here
		$Pattern = [regex]::Replace($Pattern, "\\\*", ".*", $Options)
		$Pattern = [regex]::Replace($Pattern, "\\\?", ".", $Options)
		$Pattern = [regex]::Replace($Pattern, "\\\[", "[", $Options)

		if (!$Wildcard.StartsWith("*"))
		{
			$Pattern = $Pattern.Insert(0, "^")
		}

		if (!$Wildcard.EndsWith("*"))
		{
			$Pattern += "$"
		}
	}
	else
	{
		$Pattern = $Wildcard.Insert(0, "^")
		$Pattern += "$"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Wildcard '$Wildcard' set to regex '$Pattern'"

	if ($AsRegex)
	{
		return [regex]::new($Pattern, $Options, $TimeSpan)
	}

	return $Pattern
}

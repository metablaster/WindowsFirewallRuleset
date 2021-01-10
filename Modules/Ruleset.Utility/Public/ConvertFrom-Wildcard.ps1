
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
Convert wildcard pattern to regex

.DESCRIPTION
ConvertFrom-Wildcard converts either wildcard pattern string or [WildcardPattern] object to regex
equivalent and optionally returns regex object instead of a string, initialized with specified options

.PARAMETER Pattern
Wildcard pattern string which is to be converted

.PARAMETER Wildcard
Wildcard pattern object which is to be converted

.PARAMETER AsRegex
Construct regex object in place with specified parameters.
By default regex string pattern is returned.

.PARAMETER Options
Optionally specify regex options.
By default no options are set.

.PARAMETER TimeSpan
Optionally specify a time-out interval.
By default pattern-matching operation does not time out.
This parameter has no effect if -AsRegex switch was not specified.

.EXAMPLE
PS> ConvertFrom-Wildcard "*[0-9][[]Po?er[A-Z]he*l?"

[string] regex pattern: .*[0-9][[]Po.er[A-Z]he.*l.$

.EXAMPLE
PS> $Result = ConvertFrom-Wildcard "Po?er[A-Z]hell*" -AsRegex -TimeSpan ([System.TimeSpan]::FromSeconds(3))

[regex] set to pattern: ^Po.er[A-Z]hell.* with a parse timeout of 3 seconds

.EXAMPLE
PS> ConvertFrom-Wildcard "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"

[string] regex pattern: ^a_b.*c%d[e\.\.f]\.\..g_%%_.*\?.{2}\*\\i[[].{2,}[%%]\\Z\\w\+$

.EXAMPLE
PS> $Result = ConvertFrom-Wildcard "MatchThis*" -AsRegex -Options "IgnoreCase"

[regex] case insensitive regex set to pattern: ^MatchThis.*

.INPUTS
None. You cannot pipe objects to ConvertFrom-Wildcard

.OUTPUTS
[regex]
[string]

.NOTES
This function is experimental and needs improvements.
Intended purpose of this function is to use regex to parse parameters marked as [SupportsWildcards()]

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regexoptions?view=net-5.0
#>
function ConvertFrom-Wildcard
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "String",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md")]
	[OutputType([regex], [string])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "String")]
		[ValidateScript( { $_ -ne "System.Management.Automation.WildcardPattern" })]
		[string] $Pattern,

		[Parameter(Mandatory = $true, ParameterSetName = "Wildcard")]
		[WildcardPattern] $Wildcard,

		[Parameter()]
		[switch] $AsRegex,

		[Parameter()]
		[System.Text.RegularExpressions.RegexOptions] $Options = "None",

		[Parameter()]
		[System.TimeSpan] $TimeSpan = [regex]::InfiniteMatchTimeout
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Optimize dots and stars excluding escaped dots
	$Optimize = {
		param ([string] $Target)

		[regex] $Regex = [regex]::new("(\*|\.(?<!\\\.)){2,}", $Options)
		$Match = $Regex.Match($Target)

		if ($Match.Success)
		{
			# Algorithm to optimize dots and stars
			$LocalOptimize = {
				param ([System.Text.RegularExpressions.Match] $Match)

				$Dots = [regex]::Matches($Match.Value, "\.", $Options).Count
				$Stars = [regex]::Matches($Match.Value, "\*", $Options).Count
				$Quantifier = $Dots - $Stars

				switch ($Quantifier)
				{
					# TODO: Is there a chance for .+
					0 { ".*"; break }
					1 { "."; break }
					default
					{
						if ($Stars) { ".{$Quantifier,}" }
						else { ".{$Quantifier}" }
					}
				}
			}

			$NewResult = $Target
			$Index = $Match.Index

			while ($Match.Success)
			{
				Write-Debug -Message "[& Optimize] Processing $NewResult"
				Write-Debug -Message "[& Optimize] Match at index ($Index) was $($Match.Value)"

				$NewResult = $Regex.Replace($NewResult, $LocalOptimize, 1, $Index)

				$Match = $Match.NextMatch()
				$Change = $Target.Length - $NewResult.Length
				$Index = $Match.Index - $Change
			}

			return $NewResult
		}

		return $Target
	}

	# Escape captured data
	[System.Text.RegularExpressions.MatchEvaluator] $EscapeEvaluator = {
		param ([System.Text.RegularExpressions.Match] $Match)

		Write-Debug -Message "[& Escape] Processing $($Match.Groups["data"].Value)"
		[regex]::Escape($Match.Groups["data"].Value)
	}

	# UnEscape captured data
	[System.Text.RegularExpressions.MatchEvaluator] $UnescapeEvaluator = {
		param ([System.Text.RegularExpressions.Match] $Match)

		Write-Debug -Message "[& UnEscape] Processing $($Match.Groups["data"].Value)"
		[regex]::Unescape($Match.Groups["data"].Value)
	}

	if ($PSCmdlet.ParameterSetName -eq "Wildcard")
	{
		try
		{
			# Encode wildcard characters and escape the escape codes
			# Wildcard		: a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+
			# WQL Pattern	: a[_]b%c[%]d[e..f].._g[_][%][%][_]%%[?]__[*]\i[[]%__%%%[%%]\Z\w+
			# ? becomes _
			# * becomes %
			# _ becomes [_]
			# % becomes [%]
			# [] stays valid regex syntax
			$Pattern = $Wildcard.ToWql()
		}
		catch
		{
			Write-Error -Category InvalidArgument -TargetObject $Pattern -Message "Specified wildcard pattern could not be converted"
			Write-Warning -Message $_.Exception.Message
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting wildcard object as WQL '$Pattern'"

		# result: a\[_]b%c\[%]d\[e\.\.f]\.\._g\[_]\[%]\[%]\[_]%%\[\?]__\[\*]\\i\[\[]%__%%%\[%%]\\Z\\w\+
		[string] $Result = [regex]::Escape($Pattern)

		# Convert WQL escape codes _ and % to regex equivalent characters . and .*
		# taking into account to escape existing dots for the second time
		[System.Text.RegularExpressions.MatchEvaluator] $ConvertWQL = {
			param ([System.Text.RegularExpressions.Match] $Match)

			# TODO: dots within [] should not be escaped, same case when converting string pattern
			$NewResult = [regex]::Replace($Match.Value, "\\\.", "\\\.", $Options)
			$NewResult = [regex]::Replace($NewResult, "%", ".*", $Options)
			$NewResult = [regex]::Replace($NewResult, "_", ".", $Options)

			Write-Debug -Message "[& ConvertWQL] Processing (index $($Match.Index)) $($Match.Value) to $NewResult"
			return $NewResult
		}

		# result: a\[_]b.*c\[%]d\[e\\\.\\\.f]\\\.\\\..g\[_]\[%]\[%]\[_].*.*\[\?]..\[\*]\\i\[\[].*...*.*.*\[%%]\\Z\\w\+
		$Result = [regex]::Replace($Result, "(?<!\[)(?<data>%|_)+(?!\])|\\\.", $ConvertWQL, $Options)

		# result: a\[_]b.*c\[%]d\[e\\\.\\\.f]\\\.\\\..g\[_]\[%]\[%]\[_].*\[\?].{2}\[\*]\\i\[\[].{2,}\[%%]\\Z\\w\+
		$Result = & $Optimize $Result

		# TODO: Escape/UnEscape should be performend in less Replace calls by improving match pattern
		# Convert encoded [_] and [%]
		# NOTE: ex. [__] or [%%%] are not WQL escape codes
		# result: a_b.*c%d\[e\\\.\\\.f]\\\.\\\..g_%%_.*\[\?].{2}\[\*]\\i\[\[].{2,}\[%%]\\Z\\w\+
		$Result = [regex]::Replace($Result, "\\\[(?<data>[_%])\]", $UnescapeEvaluator, $Options)

		# Convert wildcard escapes [\*] and [\?] to regex equivalent escapes before un-escaping entry pattern
		# result: a_b.*c%d\[e\\\.\\\.f]\\\.\\\..g_%%_.*\\\?.{2}\\\*\\i\[\[].{2,}\[%%]\\Z\\w\+
		$Result = [regex]::Replace($Result, "\\\[(?<data>\\(\?|\*))+\]", $EscapeEvaluator, $Options)

		# Unescape doubly esccaped: * ? /
		# result: a_b.*c%d\[e\.\.f]\.\..g_%%_.*\?.{2}\*\\i\[\[].{2,}\[%%]\\Z\\w\+
		$Result = [regex]::Replace($Result, "(?<data>\\\\\\(\?|\*|\.))", $UnescapeEvaluator, $Options)

		# Unescape [
		# result: a_b.*c%d[e\.\.f]\.\..g_%%_.*\?.{2}\*\\i[[].{2,}[%%]\\Z\\w\+
		$Result = [regex]::Replace($Result, "\\\[", "[", $Options)

		# Inserting here to reduce the length of processed pattern
		if (!$Pattern.StartsWith("%"))
		{
			$Result = $Result.Insert(0, "^")
		}

		if (!$Pattern.EndsWith("%"))
		{
			# wildcard:		a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+
			# regex:		^a_b.*c%d[e\.\.f]\.\..g_%%_.*\?.{2}\*\\i[[].{2,}[%%]\\Z\\w\+$
			$Result += "$"
		}
	}
	elseif ([WildcardPattern]::ContainsWildcardCharacters($Pattern))
	{
		try
		{
			$WildCardOptions = switch ($Options)
			{
				[System.Text.RegularExpressions.RegexOptions]::IgnoreCase
				{
					[System.Management.Automation.WildcardOptions]::IgnoreCase
					break
				}
				[System.Text.RegularExpressions.RegexOptions]::CultureInvariant
				{
					[System.Management.Automation.WildcardOptions]::CultureInvariant
					break
				}
				[System.Text.RegularExpressions.RegexOptions]::Compiled
				{
					[System.Management.Automation.WildcardOptions]::Compiled
					break
				}
				default
				{
					[System.Management.Automation.WildcardOptions]::None
				}
			}

			# Verify wildcard pattern is correct
			$Wildcard = [WildcardPattern]::new($Pattern, $WildCardOptions).ToWql()
		}
		catch
		{
			Write-Error -Category InvalidArgument -TargetObject $Pattern -Message "Wildcard pattern verification failed"
			Write-Warning -Message $_.Exception.Message
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting wildcard string '$Pattern'"

		# Convert wildcard escapes [*] and [?] to regex equivalent escape \* and \?
		$Result = [regex]::Replace($Pattern, "\[(?<data>(\?|\*))+\]", $EscapeEvaluator, $Options)

		$Result = [regex]::Escape($Result)

		# It makes no point to set TimeSpan here
		$Result = [regex]::Replace($Result, "(?<!\\)(\\\*)", ".*", $Options)
		$Result = [regex]::Replace($Result, "(?<!\\)(\\\?)", ".", $Options)
		$Result = [regex]::Replace($Result, "\\\[", "[", $Options)
		$Result = & $Optimize $Result

		# Unescape doubly esccaped * and ?
		$Result = [regex]::Replace($Result, "(?<data>\\\\\\(\?|\*))+", $UnescapeEvaluator, $Options)

		# To make it easier set anchors before escaping wildcard pattern
		if (!$Pattern.StartsWith("*"))
		{
			$Result = $Result.Insert(0, "^")
		}

		if (!$Pattern.EndsWith("*"))
		{
			$Result += "$"
		}
	}
	elseif ($Pattern -eq "System.Management.Automation.WildcardPattern")
	{
		Write-Error -Category InvalidArgument -TargetObject $Pattern -Message "Please specify -Wildcard parameter to convert WildcardPattern object"
		return
	}
	else
	{
		Write-Warning -Message "Wildcard pattern '$Pattern' contains no wildcard characters"

		$Result = $Pattern.Insert(0, "^")
		$Result += "$"
	}

	try
	{
		[regex] $Regex = [regex]::new($Result, $Options, $TimeSpan)
	}
	catch [System.ArgumentException]
	{
		Write-Error -Category InvalidResult -TargetObject $Result -Message "Unable to convert wildcard pattern to regex equivalent"
		Write-Warning -Message $_.Exception.Message
		return
	}
	catch
	{
		Write-Error -Category InvalidResult -TargetObject $Result -Message $_
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting string '$Pattern' resolved to regex '$Result'"

	if ($AsRegex)
	{
		return $Regex
	}

	return $Result
}

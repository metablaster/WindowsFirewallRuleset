---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md
schema: 2.0.0
---

# ConvertFrom-Wildcard

## SYNOPSIS

Convert wildcard pattern to regex

## SYNTAX

### String (Default)

```powershell
ConvertFrom-Wildcard [-Pattern] <String> [-AsRegex] [-Options <RegexOptions>] [-TimeSpan <TimeSpan>]
 [-SkipAnchor] [<CommonParameters>]
```

### Wildcard

```powershell
ConvertFrom-Wildcard -Wildcard <WildcardPattern> [-AsRegex] [-Options <RegexOptions>] [-TimeSpan <TimeSpan>]
 [<CommonParameters>]
```

## DESCRIPTION

ConvertFrom-Wildcard converts either wildcard pattern string or \[WildcardPattern\] object to regex
equivalent and optionally returns regex object instead of a string, initialized with specified options

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-Wildcard "*[0-9][[]Po?er[A-Z]he*l?"
```

\[string\] regex pattern: .*\[0-9\]\[\[\]Po.er\[A-Z\]he.*l.$

### EXAMPLE 2

```
$Result = ConvertFrom-Wildcard "Po?er[A-Z]hell*" -AsRegex -TimeSpan ([System.TimeSpan]::FromSeconds(3))
```

\[regex\] set to pattern: ^Po.er\[A-Z\]hell.* with a parse timeout of 3 seconds

### EXAMPLE 3

```powershell
ConvertFrom-Wildcard "a_b*c%d[e..f]..?g_%%_**[?]??[*]\i[[]*??***[%%]\Z\w+"
```

\[string\] regex pattern: ^a_b.*c%d\[e\.\.f\]\.\..g_%%_.*\?.{2}\*\\\\i\[\[\].{2,}\[%%\]\\\\Z\\\\w\+$

### EXAMPLE 4

```
$Result = ConvertFrom-Wildcard "MatchThis*" -AsRegex -Options "IgnoreCase"
```

\[regex\] case insensitive regex set to pattern: ^MatchThis.*

## PARAMETERS

### -Pattern

Wildcard pattern string which is to be converted

```yaml
Type: System.String
Parameter Sets: String
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wildcard

Wildcard pattern object which is to be converted

```yaml
Type: System.Management.Automation.WildcardPattern
Parameter Sets: Wildcard
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsRegex

Construct regex object in place with specified parameters.
By default regex string pattern is returned.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Options

Optionally specify regex options.
By default no options are set.

```yaml
Type: System.Text.RegularExpressions.RegexOptions
Parameter Sets: (All)
Aliases:
Accepted values: None, IgnoreCase, Multiline, ExplicitCapture, Compiled, Singleline, IgnorePatternWhitespace, RightToLeft, ECMAScript, CultureInvariant

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeSpan

Optionally specify a time-out interval.
By default pattern-matching operation does not time out.
This parameter has no effect if -AsRegex switch was not specified.

```yaml
Type: System.TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [regex]::InfiniteMatchTimeout
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipAnchor

If specified, does not add ^ and $ anchors to the result pattern.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: String
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to ConvertFrom-Wildcard

## OUTPUTS

### [regex]

### [string]

## NOTES

This function is experimental and needs improvements.
Intended purpose of this function is to use regex to parse parameters marked as \[SupportsWildcards()\]

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/ConvertFrom-Wildcard.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.1](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards?view=powershell-7.1)

[https://docs.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regexoptions?view=net-5.0](https://docs.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regexoptions?view=net-5.0)

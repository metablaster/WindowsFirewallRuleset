---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ColorMessage.md
schema: 2.0.0
---

# Write-ColorMessage

## SYNOPSIS

Write a colored output

## SYNTAX

```powershell
Write-ColorMessage [[-Message] <String>] [[-ForegroundColor] <ConsoleColor>] [-BackgroundColor <ConsoleColor>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Write-ColorMessage writes colored output, which let's you avoid using Write-Host to
avoid having to suppress code analysis warnings with PSScriptAnalyzer.

## EXAMPLES

### EXAMPLE 1

```powershell
Write-ColorMessage sample_text Green
```

sample_text (in green)

### EXAMPLE 2

```powershell
Write-ColorMessage sample_text Red -BackGroundColor White
```

sample_text (in red with white background)

## PARAMETERS

### -Message

An object such as test which is to be printed or outputted in color

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: InputObject

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ForegroundColor

Specifies foreground color

```yaml
Type: System.ConsoleColor
Parameter Sets: (All)
Aliases:
Accepted values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BackgroundColor

Specifies background color

```yaml
Type: System.ConsoleColor
Parameter Sets: (All)
Aliases:
Accepted values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]

## OUTPUTS

### [string]

## NOTES

HACK: Should be possible for input object to be any object not just string, but it
works unexpectedly depending on PS edition used.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ColorMessage.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Write-ColorMessage.md)

[https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor](https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor)

[https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshost](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshost)

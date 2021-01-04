---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-NetworkService.md
schema: 2.0.0
---

# Get-NetworkService

## SYNOPSIS

Get a list of windows services involved in rules

## SYNTAX

```powershell
Get-NetworkService [-Folder] <String> [<CommonParameters>]
```

## DESCRIPTION

Scan all scripts in this repository and get windows service names involved in rules,
the result is saved to file and used to verify existence of these services on target system.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-NetworkService "C:\PathToRepo"
```

## PARAMETERS

### -Folder

Root folder name which to scan recursively

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-NetworkService

## OUTPUTS

### None. Get-NetworkService does not generate any output

## NOTES

None.

## RELATED LINKS

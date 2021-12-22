---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Build-ServiceList.md
schema: 2.0.0
---

# Build-ServiceList

## SYNOPSIS

Build a list of windows services involved in script rules

## SYNTAX

```powershell
Build-ServiceList [-Path] <DirectoryInfo> [-Log] [<CommonParameters>]
```

## DESCRIPTION

Scan all scripts in this repository and get windows service names involved in firewall rules.
The result is saved to file and used to verify existence and digital signature of these services
on target system.

## EXAMPLES

### EXAMPLE 1

```powershell
Build-ServiceList "C:\PathToRepo"
```

### EXAMPLE 2

```powershell
Build-ServiceList "C:\PathToRepo" -Log
```

## PARAMETERS

### -Path

Root folder name which to scan recursively

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Log

If specified, the list of services is also logged.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Build-ServiceList

## OUTPUTS

### [string]

## NOTES

TODO: -Log parameter should be accompanied with -LogName parameter

## RELATED LINKS

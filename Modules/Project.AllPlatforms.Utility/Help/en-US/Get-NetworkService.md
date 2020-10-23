---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-NetworkService.md
schema: 2.0.0
---

# Get-NetworkService

## SYNOPSIS

Scan all scripts in this repository and get windows service names involved in rules

## SYNTAX

```none
Get-NetworkService [-Folder] <String> [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1

```none
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

### None, File with the list of services is made

## NOTES

None.

## RELATED LINKS

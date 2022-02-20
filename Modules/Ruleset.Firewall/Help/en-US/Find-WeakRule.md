---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Find-WeakRule.md
schema: 2.0.0
---

# Find-WeakRule

## SYNOPSIS

Get potentially weak firewall rules

## SYNTAX

```powershell
Find-WeakRule -Path <DirectoryInfo> [-FileName <String>] [-Direction <String>] [<CommonParameters>]
```

## DESCRIPTION

Find-WeakRule gets all rules which are not restrictive enough, and saves the result into a JSON file.
Intended purpose of this function is to find potentially weak rules to be able to quickly sport
incomplete rules to update them as needed for security reasons.

## EXAMPLES

### EXAMPLE 1

```powershell
Find-WeakRule -Path $Exports -Direction Outbound -FileName "WeakRules"
```

### EXAMPLE 2

```powershell
Find-WeakRule -Path $Exports -FileName "WeakRules"
```

## PARAMETERS

### -Path

Path into which to save file.
Wildcard characters are supported.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FileName

Output file name, which is json file into which result is saved

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: WeakRules
Accept pipeline input: False
Accept wildcard characters: False
```

### -Direction

Firewall rule direction, default is '*' both directions

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Find-WeakRule

## OUTPUTS

### [System.Void]

## NOTES

None.

## RELATED LINKS

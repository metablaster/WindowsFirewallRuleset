---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Find-RulePrincipal.md
schema: 2.0.0
---

# Find-RulePrincipal

## SYNOPSIS

Get all firewall rules without or with specified LocalUser value

## SYNTAX

### None (Default)

```powershell
Find-RulePrincipal -Path <DirectoryInfo> [-FileName <String>] [-Direction <String>] [<CommonParameters>]
```

### Group

```powershell
Find-RulePrincipal -Path <DirectoryInfo> [-FileName <String>] [-User <String>] -Group <String>
 [-Direction <String>] [<CommonParameters>]
```

### User

```powershell
Find-RulePrincipal -Path <DirectoryInfo> [-FileName <String>] -User <String> [-Direction <String>]
 [<CommonParameters>]
```

## DESCRIPTION

Get all rules which are either missing missing LocalUser value or rules which match specified
LocalUser value, and save the result into a JSON file.
Intended purpose of this function is to find rules without LocalUser value set to be able
to quickly sport incomplete rules and assign LocalUser value for security reasons.

## EXAMPLES

### EXAMPLE 1

```powershell
Find-RulePrincipal -Path $Exports -Direction Outbound -FileName "PrincipalRules" -Group "Users"
```

### EXAMPLE 2

```powershell
Find-RulePrincipal -Path $Exports -FileName "NoPrincipalRules"
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
Default value: PrincipalRules
Accept pipeline input: False
Accept wildcard characters: False
```

### -User

User for which to obtain rules

```yaml
Type: System.String
Parameter Sets: Group
Aliases: UserName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: System.String
Parameter Sets: User
Aliases: UserName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group

Group for which to obtain rules

```yaml
Type: System.String
Parameter Sets: Group
Aliases: UserGroup

Required: True
Position: Named
Default value: None
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

### None. You cannot pipe objects to Find-RulePrincipal

## OUTPUTS

### [System.Void]

## NOTES

TODO: Should be able to query rules for multiple users or groups

## RELATED LINKS

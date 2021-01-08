---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Update-Table.md
schema: 2.0.0
---

# Update-Table

## SYNOPSIS

Fill data table with principal and program location

## SYNTAX

```powershell
Update-Table -Search <String> [-UserProfile] [-Executable <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Module scope installation table is updated
Search system for programs with input search string, and add new program installation directory
to the table, as well as other information needed to make a firewall rule

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Table -Search "GoogleChrome"
```

### EXAMPLE 2

```powershell
Update-Table -Search "Microsoft Edge" -Executable "msedge.exe"
```

### EXAMPLE 3

```powershell
Update-Table -Search "Greenshot" -UserProfile
```

## PARAMETERS

### -Search

Search string which corresponds to the output of "Get programs" functions

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserProfile

true if user profile is to be searched too, system locations only otherwise

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

### -Executable

Optionally specify executable name which will be search first.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Update-Table

## OUTPUTS

### None. Update-Table does not generate any output

## NOTES

TODO: For programs in user profile rules should update LocalUser parameter accordingly,
currently it looks like we assign entry user group for program that applies to user only
TODO: Using "Executable" parameter should be possible without the use of "Search" parameter
TODO: Consider optional parameter for search by regex, wildcard, case sensitive or positional search

## RELATED LINKS

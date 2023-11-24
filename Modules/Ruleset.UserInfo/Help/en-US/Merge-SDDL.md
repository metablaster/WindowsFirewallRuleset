---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Merge-SDDL.md
schema: 2.0.0
---

# Merge-SDDL

## SYNOPSIS

Merge 2 SDDL strings into one

## SYNTAX

```powershell
Merge-SDDL [-SDDL] <PSReference> -From <String> [-Unique] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

This function helps to merge 2 SDDL strings into one
Referenced SDDL is expanded with new one

## EXAMPLES

### EXAMPLE 1

```powershell
$SDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)"
PS> $RefSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
PS> Merge-SDDL ([ref] $SDDL) -From $RefSDDL
```

## PARAMETERS

### -SDDL

SDDL into which to merge new SDDL

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From

Reference SDDL string which to merge into original SDDL

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

### -Unique

If specified, only SDDL's with unique SID are merged

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

### None. You cannot pipe objects to Merge-SDDL

## OUTPUTS

### None. Merge-SDDL does not generate any output

## NOTES

TODO: Validate input using regex
TODO: Process an array of SDDL's or Join-SDDL function to join multiple SDDL's
TODO: Pipeline input and -From parameter should accept an array.

## RELATED LINKS

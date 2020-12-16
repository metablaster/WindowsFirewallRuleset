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
Merge-SDDL [-RefSDDL] <PSReference> [-NewSDDL] <String> [<CommonParameters>]
```

## DESCRIPTION

This function helps to merge 2 SDDL strings into one
Referenced SDDL is expanded with new one

## EXAMPLES

### EXAMPLE 1

```powershell
$RefSDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)
$NewSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
Merge-SDDL ([ref] $RefSDDL) $NewSDDL
```

## PARAMETERS

### -RefSDDL

Reference to SDDL into which to merge new SDDL

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

### -NewSDDL

New SDDL string which to merge with reference SDDL

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
TODO: Process an array of SDDL's
TODO: Pipeline input

## RELATED LINKS

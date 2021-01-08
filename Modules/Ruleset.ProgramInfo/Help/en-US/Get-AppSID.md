---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md
schema: 2.0.0
---

# Get-AppSID

## SYNOPSIS

Get store app SID

## SYNTAX

```powershell
Get-AppSID [-PackageFamilyName] <String> [<CommonParameters>]
```

## DESCRIPTION

Get SID for single store app if the app exists

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AppSID "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
```

## PARAMETERS

### -PackageFamilyName

"PackageFamilyName" string

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: FamilyName

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-AppSID

## OUTPUTS

### [string] store app SID (security identifier) if app found

## NOTES

Big thanks to Jani for this awesome solution, see issue from "related links" section
TODO: remote computers?

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md)

[https://github.com/metablaster/WindowsFirewallRuleset/issues/6](https://github.com/metablaster/WindowsFirewallRuleset/issues/6)

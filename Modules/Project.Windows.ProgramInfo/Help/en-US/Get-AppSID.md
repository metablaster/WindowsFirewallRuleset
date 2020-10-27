---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-AppSID.md
schema: 2.0.0
---

# Get-AppSID

## SYNOPSIS

Get store app SID

## SYNTAX

```none
Get-AppSID [-UserName] <String> [-AppName] <String> [<CommonParameters>]
```

## DESCRIPTION

Get SID for single store app if the app exists

## EXAMPLES

### EXAMPLE 1

```none
sample: Get-AppSID "User" "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
```

## PARAMETERS

### -UserName

Username for which to query app SID

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: User

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AppName

"PackageFamilyName" string

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

### None. You cannot pipe objects to Get-AppSID

## OUTPUTS

### [string] store app SID (security identifier) if app found

## NOTES

TODO: Test if path exists
TODO: remote computers?

## RELATED LINKS

---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-WindowsSDK.md
schema: 2.0.0
---

# Get-WindowsSDK

## SYNOPSIS

Get installed Windows SDK

## SYNTAX

```powershell
Get-WindowsSDK [[-Domain] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Get installation information about installed Windows SDK

## EXAMPLES

### EXAMPLE 1

```powershell
Get-WindowsSDK
```

### EXAMPLE 2

```powershell
Get-WindowsSDK Server01
```

## PARAMETERS

### -Domain

Computer name for which to list installed installed framework

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: [System.Environment]::MachineName
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

### None. You cannot pipe objects to Get-WindowsSDK

## OUTPUTS

### [PSCustomObject] for installed Windows SDK versions and install paths

## NOTES

None.

## RELATED LINKS

---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemProgram.md
schema: 2.0.0
---

# Get-SystemProgram

## SYNOPSIS

Search installed programs for all users, system wide

## SYNTAX

```powershell
Get-SystemProgram [[-Domain] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Get a list of software installed system wide, for all users.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SystemProgram
```

### EXAMPLE 2

```powershell
Get-SystemProgram "Server01"
```

## PARAMETERS

### -Domain

Computer name which to check

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

### None. You cannot pipe objects to Get-SystemProgram

## OUTPUTS

### [PSCustomObject] list of programs installed for all users

## NOTES

We should return empty PSCustomObject if test computer fails
TODO: Parameter for x64 vs x86 software, then update Search-Installation switch as needed

## RELATED LINKS

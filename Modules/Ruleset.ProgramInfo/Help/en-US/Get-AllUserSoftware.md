---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AllUserSoftware.md
schema: 2.0.0
---

# Get-AllUserSoftware

## SYNOPSIS

Search program install properties for all users, system wide

## SYNTAX

```powershell
Get-AllUserSoftware [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search separate location in the registry for programs installed for all users.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AllUserSoftware "COMPUTERNAME"
```

## PARAMETERS

### -ComputerName

Computer name which to check

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-AllUserSoftware

## OUTPUTS

### [PSCustomObject] list of programs installed for all users

## NOTES

TODO: should be renamed into Get-InstallProperties or something else because it has nothing to do
with system wide installed programs

## RELATED LINKS

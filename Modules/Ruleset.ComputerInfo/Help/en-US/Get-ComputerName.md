---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-ComputerName.md
schema: 2.0.0
---

# Get-ComputerName

## SYNOPSIS

Retrieve localhost NETBIOS name

## SYNTAX

```powershell
Get-ComputerName [<CommonParameters>]
```

## DESCRIPTION

Retrieve localhost NETBIOS name

## EXAMPLES

### EXAMPLE 1

```powershell
Get-ComputerName
```

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-ComputerName

## OUTPUTS

### [string] computer name in form of COMPUTERNAME

## NOTES

TODO: Possible function purpose such as conversion from NETBIOS to UPN name or reading different
formats of file with a list of computernames which are then converted to desired format.
TODO: Maybe implement querying computers on network by specifying IP address and vice versa.

## RELATED LINKS

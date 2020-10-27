---
external help file: Project.Windows.ComputerInfo-help.xml
Module Name: Project.Windows.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ComputerInfo/Help/en-US/Get-SystemSKU.md
schema: 2.0.0
---

# Get-SystemSKU

## SYNOPSIS

Get operating system SKU information

## SYNTAX

### Number

```none
Get-SystemSKU [-SKU <Int32>] [<CommonParameters>]
```

### Computer

```none
Get-SystemSKU [-ComputerName <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Get the SKU (Stock Keeping Unit) information for one or multiple target computers,
or translate SKU number to SKU

## EXAMPLES

### EXAMPLE 1

```none
Get-SystemSKU
Home Premium N
```

## PARAMETERS

### -SKU

Operating system SKU number, can't be used with ComputerName parameter

```yaml
Type: System.Int32
Parameter Sets: Number
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerName

One or more computer names, can't be used with SKU parameter

```yaml
Type: System.String[]
Parameter Sets: Computer
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-SystemSKU

## OUTPUTS

### [PSCustomObject[]] array with Computer/SKU value pairs

## NOTES

TODO: accept UPN and NETBIOS computer names
TODO: ComputerName default value is just a placeholder to be able to use foreach
which is needed for pipeline, need better design

## RELATED LINKS

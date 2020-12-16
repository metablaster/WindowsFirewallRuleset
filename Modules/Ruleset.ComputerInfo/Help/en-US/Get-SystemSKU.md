---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-SystemSKU.md
schema: 2.0.0
---

# Get-SystemSKU

## SYNOPSIS

Get operating system SKU information

## SYNTAX

### Number

```powershell
Get-SystemSKU [-SKU <Int32>] [<CommonParameters>]
```

### Computer

```powershell
Get-SystemSKU [-ComputerName <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Get the SKU (Stock Keeping Unit) information for one or multiple target computers,
or translate SKU number to SKU

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SystemSKU
```

Home Premium N

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

### [int32]

## OUTPUTS

### [PSCustomObject] Computer/SKU value pair

## NOTES

TODO: accept UPN and NETBIOS computer names
TODO: ComputerName default value is just a placeholder, need better design

## RELATED LINKS

[https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0](https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0)

[https://docs.microsoft.com/en-us/surface/surface-system-sku-reference](https://docs.microsoft.com/en-us/surface/surface-system-sku-reference)

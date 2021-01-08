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
Get-SystemSKU -SKU <Int32> [<CommonParameters>]
```

### Computer

```powershell
Get-SystemSKU [-Domain <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Get the SKU (Stock Keeping Unit) information for one or multiple target computers,
or translate SKU number to SKU string

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SystemSKU
```

Domain      SystemSKU     SKU
------      ---------     ---
MY-DESKTOP  Professional  48

### EXAMPLE 2

```
@(Server1, Server2, Server3) | Get-SystemSKU
```

Domain    SystemSKU                SKU
------    ---------                ---
Server1   Professional             48
Server2   Home Premium N           26
Server3   Microsoft Hyper-V Server 42

### EXAMPLE 3

```powershell
Get-SystemSKU -SKU 7
```

Domain   SystemSKU   SKU
------   ---------   ---
         Server      Standard  7

## PARAMETERS

### -SKU

Operating system SKU number

```yaml
Type: System.Int32
Parameter Sets: Number
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

One or more computer names

```yaml
Type: System.String[]
Parameter Sets: Computer
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]

## OUTPUTS

### [PSCustomObject]

## NOTES

TODO: Accept UPN and NETBIOS computer names

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-SystemSKU.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-SystemSKU.md)

[https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0](https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0)

[https://docs.microsoft.com/en-us/surface/surface-system-sku-reference](https://docs.microsoft.com/en-us/surface/surface-system-sku-reference)

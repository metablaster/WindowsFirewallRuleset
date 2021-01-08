---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Out-DataTable.md
schema: 2.0.0
---

# Out-DataTable

## SYNOPSIS

Creates a DataTable for an object

## SYNTAX

```powershell
Out-DataTable [-InputObject] <PSObject[]> [-NonNullable <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Creates a DataTable based on an object's properties.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PSDrive | Out-DataTable
```

Creates a DataTable from the properties of Get-PSDrive

### EXAMPLE 2

```powershell
Get-Process | Select-Object Name, CPU | Out-DataTable
```

Get a list of processes and their CPU and create a datatable

## PARAMETERS

### -InputObject

One or more objects to convert into a DataTable

```yaml
Type: System.Management.Automation.PSObject[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -NonNullable

A list of columns to set disable AllowDBNull on

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [PSObject[]] Any object can be piped to Out-DataTable

## OUTPUTS

### [System.Data.DataTable]

## NOTES

Adapted from script by Marc van Orsouw and function from Chad Miller
Version History
v1.0  - Chad Miller - Initial Release
v1.1  - Chad Miller - Fixed Issue with Properties
v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0
v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties
v1.4  - Chad Miller - Corrected issue with DBNull
v1.5  - Chad Miller - Updated example
v1.6  - Chad Miller - Added column datatype logic with default to string
v1.7  - Chad Miller - Fixed issue with IsArray
v1.8  - ramblingcookiemonster - Removed if($Value) logic. 
This would not catch empty strings, zero, $false and other non-null items
							  - Added perhaps pointless error handling

Modifications by metablaster January 2021:
Updated formatting, casing and naming according to the rest of project
Updated comment based help
Convert inner function to scriptblock

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Out-DataTable.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Out-DataTable.md)

[https://github.com/RamblingCookieMonster/PowerShell](https://github.com/RamblingCookieMonster/PowerShell)


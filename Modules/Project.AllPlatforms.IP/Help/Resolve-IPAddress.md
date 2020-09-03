---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version:
schema: 2.0.0
---

# Resolve-IPAddress

## SYNOPSIS

Resolves an IP address expression using wildcard expressions to individual IP addresses.

## SYNTAX

```powershell
Resolve-IPAddress [-IPAddress] <String> [<CommonParameters>]
```

## DESCRIPTION

Resolves an IP address expression using wildcard expressions to individual IP addresses.

Resolve-IPAddress expands groups and values in square brackets to generate a list of IP addresses
or networks using CIDR-notation.

Ranges of values may be specified using a start and end value using "-" to separate the values.

Specific values may be listed as a comma separated list.

## EXAMPLES

### EXAMPLE 1

```powershell
Resolve-IPAddress "10.[1,2].[0-2].0/24"
```

Returns the addresses 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.2.0.0/24, and so on.

## PARAMETERS

### -IPAddress

The IPAddress expression to resolve.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable,
-Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

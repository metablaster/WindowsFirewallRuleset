
# Ruleset.IP

## about_Ruleset.IP

## SHORT DESCRIPTION

Module to perform IPv4 subnet math

## LONG DESCRIPTION

Ruleset.IP module is used to perform binary, decimal and hex conversions on IP and netmask

## EXAMPLES

```powershell
ConvertFrom-HexIP
```

Converts a hexadecimal IP address into a dotted decimal string

```powershell
ConvertTo-BinaryIP
```

Converts a Decimal IP address into a binary format

```powershell
ConvertTo-DecimalIP
```

Converts a Decimal IP address into a 32-bit unsigned integer

```powershell
ConvertTo-DottedDecimalIP
```

Converts either an unsigned 32-bit integer or a dotted binary string to an IP Address

```powershell
ConvertTo-HexIP
```

Convert a dotted decimal IP address into a hexadecimal string

```powershell
ConvertTo-Mask
```

Convert a mask length to a dotted-decimal subnet mask

```powershell
ConvertTo-MaskLength
```

Convert a dotted-decimal subnet mask to a mask length

```powershell
ConvertTo-Subnet
```

Convert a start and end IP address to the closest matching subnet

```powershell
Get-BroadcastAddress
```

Get the broadcast address for a network range

```powershell
Get-NetworkAddress
```

Get the network address for a network range

```powershell
Get-NetworkRange
```

Get a list of IP addresses within the specified network

```powershell
Get-NetworkSummary
```

Generates a summary describing several properties of a network range

```powershell
Get-Subnet
```

Get a list of subnets of a given size within a defined supernet

```powershell
Resolve-IPAddress
```

Resolves an IP address expression using wildcard expressions to individual IP addresses

```powershell
Test-SubnetMember
```

Tests an IP address to determine if it falls within IP address range

## KEYWORDS

- IPMath
- IPCalculator
- SubnetMath

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.IP/Help/en-US
https://github.com/indented-automation/Indented.Net.IP

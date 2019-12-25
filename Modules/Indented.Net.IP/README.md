# Indented.Net.IP

[![Build status](https://ci.appveyor.com/api/projects/status/u09nudqyvm1nbp6k?svg=true)](https://ci.appveyor.com/project/indented-automation/indented-net-ip)

A collection of commands written to perform IPv4 subnet math.

## Installation

```powershell
Install-Module Indented.Net.IP
```

## Commands

| Name | Synopsis |
| --- | --- |
| ConvertFrom-HexIP | Converts a hexadecimal IP address into a dotted decimal string. |
| ConvertTo-BinaryIP | Converts a Decimal IP address into a binary format. |
| ConvertTo-DecimalIP | Converts a Decimal IP address into a 32-bit unsigned integer. |
| ConvertTo-DottedDecimalIP | Converts either an unsigned 32-bit integer or a dotted binary string to an IP Address. |
| ConvertTo-HexIP | Convert a dotted decimal IP address into a hexadecimal string. |
| ConvertTo-Mask | Convert a mask length to a dotted-decimal subnet mask. |
| ConvertTo-MaskLength | Convert a dotted-decimal subnet mask to a mask length. |
| ConvertTo-Subnet | Convert a start and end IP address to the closest matching subnet. |
| Get-BroadcastAddress | Get the broadcast address for a network range. |
| Get-NetworkAddress | Get the network address for a network range. |
| Get-NetworkRange | Get a list of IP addresses within the specified network. |
| Get-NetworkSummary | Generates a summary describing several properties of a network range. |
| Get-Subnet | Get a list of subnets of a given size within a defined supernet. |
| Resolve-IPAddress | Resolves an IP address expression using wildcard expressions to individual IP addresses. |
| Test-SubnetMember | Tests an IP address to determine if it falls within IP address range. |

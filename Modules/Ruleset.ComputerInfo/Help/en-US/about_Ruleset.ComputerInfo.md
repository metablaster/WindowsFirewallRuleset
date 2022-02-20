
# Ruleset.ComputerInfo

## about_Ruleset.ComputerInfo

## SHORT DESCRIPTION

Query computer, system and network information

## LONG DESCRIPTION

Ruleset.ComputerInfo module is used to query information about Windows computers,
operating system and network configuration.

## EXAMPLES

```powershell
ConvertFrom-OSBuild
```

Convert from OS build number to OS version

```powershell
Get-InterfaceAlias
```

Get interface aliases of specified network adapters

```powershell
Get-InterfaceBroadcast
```

Get interface broadcast address

```powershell
Get-SystemSKU
```

Get operating system SKU information

```powershell
Resolve-Host
```

Resolve host to IP or an IP to host

```powershell
Select-IPInterface
```

Select IP configuration for specified network adapters

```powershell
Test-Computer
```

Test target computer (policy store) to which to deploy firewall

```powershell
Test-DnsName
```

Validate DNS domain name syntax

```powershell
Test-NetBiosName
```

Validate NETBIOS name syntax

```powershell
Test-UNC
```

Validate UNC path syntax

## KEYWORDS

- Computer
- ComputerInfo
- SystemInfo
- NetworkInfo

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.ComputerInfo/Help/en-US

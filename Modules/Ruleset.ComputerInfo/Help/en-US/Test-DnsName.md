---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-DnsName.md
schema: 2.0.0
---

# Test-DnsName

## SYNOPSIS

Validate DNS domain name syntax

## SYNTAX

```powershell
Test-DnsName [-Name] <String[]> [-Strict] [-Quiet] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Test if DNS domain name has correct syntax.
The validation is valid at Windows 2000 DNS and the Windows Server 2003 DNS and later Windows
systems in Active Direcotry.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-DnsName
```

Repeat ".EXAMPLE" keyword for each example.

## PARAMETERS

### -Name

DNS domain name which is to be checked

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Strict

If specified, unicode characters are not valid.
By default unicode characters are valid for systems mentioned in description.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, syntax errors are not shown, only true or false is returned.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, domain name isn't checked against reserved words

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]

## OUTPUTS

### [bool]

## NOTES

TODO: The following are syntax rules which need to be implemented:
DNS names can contain only alphabetical characters (A-Z), numeric characters (0-9),
the minus sign (-), and the period (.)
Period characters are allowed only when they are used to delimit the components of domain style names.

In the Windows 2000 domain name system (DNS) and the Windows Server 2003 DNS, Unicode characters are supported.
Other implementations of DNS don't support Unicode characters.

DNS domain names can't contain the following characters:
, ~ : !
@ # $ % ^ & ' .
( ) { } _ SPACE

The underscore has a special role.
It's permitted for the first character in SRV records by RFC definition.
But newer DNS servers may also allow it anywhere in a name.
All characters preserve their case formatting except for ASCII characters.
The first character must be alphabetical or numeric.
The last character must not be a minus sign or a period.
Minimum name length: 2 characters
Maximum name length: 255 characters
The maximum length of the host name and of the fully qualified domain name (FQDN) is 63 bytes per
label and 255 characters per FQDN.
The latter is based on the maximum path length possible with an Active Directory Domain name with the
paths needed in SYSVOL, and it needs to obey to the 260 character MAX_PATH limitation.

An example path in SYSVOL contains:
\\\\\<FQDN domain name\>\sysvol\\\<FQDN domain name\>\policies\{\<policy GUID\>}\\\[user|machine\]\\\<CSE-specific path\>

Single-label DNS names can't be registered by using an Internet registrar.
The DNS Server service may not be used to locate domain controllers in domains that have single-label DNS names.
Don't use top-level Internet domain names on the intranet, such as .com, .net, and .org.
TODO: There is a best practices list on MS site, for which we should generate a warning.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-DnsName.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-DnsName.md)

[https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou](https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou)

[https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10)](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10))

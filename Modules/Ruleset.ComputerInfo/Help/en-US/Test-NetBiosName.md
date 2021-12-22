---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md
schema: 2.0.0
---

# Test-NetBiosName

## SYNOPSIS

Validate NETBIOS name syntax

## SYNTAX

```powershell
Test-NetBiosName [-Name] <String[]> [-Operation <String>] [-Strict] [-Quiet] [-Force] [<CommonParameters>]
```

## DESCRIPTION

Test if NETBIOS computer name and/or user name has correct syntax
The validation is valid for Windows 2000 DNS and the Windows Server 2003 DNS and later Windows
systems in Active Direcotry.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-NetBiosName "*SERVER" -Operation Domain
False
```

### EXAMPLE 2

```powershell
Test-NetBiosName "-SERVER-01" -Quiet -Strict -Operation Domain
True
```

### EXAMPLE 3

```powershell
Test-NetBiosName "-Server-01\UserName"
True
```

### EXAMPLE 4

```powershell
Test-NetBiosName "User+Name" -Operation User -Strict -Quiet
False
```

## PARAMETERS

### -Name

Computer and/or user NETBIOS name which is to be checked

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Operation

Specifies the kind of name checking to perform on -Name parameter as follows:

- User: Name parameter is logon name
- Domain: Name parameter is domain name
- Principal: Name parameter is both, in the form of DOMAIN\USERNAME

The default is Principal.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Principal
Accept pipeline input: False
Accept wildcard characters: False
```

### -Strict

If specified, domain name must conform to IBM specifications.
By default verification conforms only to Microsoft specifications.
This switch is experimental.

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

If specified, name syntax errors are not shown, only true or false is returned.

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

If specified, domain name isn't checked against reserved words, thus the length of domain
name isn't check either since reserved words may exceed the limit.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]

## OUTPUTS

### [bool]

## NOTES

According to Microsoft:
NetBIOS computer names can't contain the following characters \ / : * ?
" \< \> |
Computers names can contain a period (.) but the name can't start with a period.
Computers that are members of an AD domain can't have names that are composed completely of numbers
Computer name must not be reserved word.
Minimum computer name length: 1 character
Maximum computer name length: 15 characters
Logon names can be up to 104 characters.
However, it isn't practical to use logon names that are longer than 64 characters.
Logon names can't contain following characters " / \ \[ \] : ; | = , + * ?
\< \>
Logon names can contain all other special characters, including spaces, periods, dashes, and underscores.
But it's generally not a good idea to use spaces in account names.

TODO: The use of NetBIOS scopes in names is a legacy configuration.
It shouldn't be used with Active Directory forests.
TODO: There is a best practices list on MS site, for which we should generate warnings.

According to IBM:
NetBIOS names are always converted to uppercase when sent to other
systems, and may consist of any character, except:
- Any character less than a space (0x20)
- the characters " .
/ \ \[ \] : | \< \> + = ; ,
The name should not start with an asterisk (*)
The NetBIOS name is 16 ASCII characters, however Microsoft limits the host name to 15 characters and
reserves the 16th character as a NetBIOS Suffix

Microsoft allows the dot, while IBM does not
Space character may work on Windows system as well even though it's not allowed, it may be useful
for domains such as NT AUTHORITY\NETWORK SERVICE
Important to understand is, the choice of name used by a higher-layer protocol or application is up
to that protocol or application and not NetBIOS.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d)

[http://www.asciitable.com/](http://www.asciitable.com/)

[https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou](https://docs.microsoft.com/da-dk/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou)

[https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10)](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/bb726984(v=technet.10))

[https://en.wikipedia.org/wiki/NetBIOS](https://en.wikipedia.org/wiki/NetBIOS)

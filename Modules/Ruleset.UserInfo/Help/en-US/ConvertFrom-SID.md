---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SID.md
schema: 2.0.0
---

# ConvertFrom-SID

## SYNOPSIS

Convert SID to principal, user and domain name

## SYNTAX

### Domain (Default)

```powershell
ConvertFrom-SID [-SID] <String[]> [-Domain <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Session

```powershell
ConvertFrom-SID [-SID] <String[]> -CimSession <CimSession> -Session <PSSession> [<CommonParameters>]
```

## DESCRIPTION

Convert SID to principal, user and domain name, in case of pseudo and built in accounts
only relevant login name is returned, not full reference name.
In all other cases result if full account name in form of COMPUTERNAME\USERNAME

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-SID S-1-5-21-2139171146-395215898-1246945465-2359
```

### EXAMPLE 2

```
"S-1-5-32-580", "S-1-5-21-34223-2342-234234-518" | ConvertFrom-SID
```

## PARAMETERS

### -SID

One or more SIDs to convert

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

### -Domain

Computer to check if SID is not known, the default is localhost

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: Computer, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession

Specifies the CIM session to use

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: Session
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] One or multiple SID's

## OUTPUTS

### [PSCustomObject] composed of SID information

## NOTES

To avoid confusion, pseudo accounts ("Local Service" in the example below) can be represented as:
1.
SID (S-1-5-19)
2.
Name (NT AUTHORITY)
3.
Reference Name (NT AUTHORITY\Local Service)
4.
Display Name (Local Service)

On the other side built in accounts ("Administrator" in the example below) can be represented as:
1.
SID (S-1-5-21-500)
2.
Name (Administrator)
3.
Reference Name (BUILTIN\Administrator)
4.
Display Name (Administrator)

This is important to understand because MSDN site (links in comment) just says "Name",
but we can't just use given "Name" value to refer to user when defining rules because it's
not valid for multiple reasons such as:
1.
There are duplicate names, which SID do you want if "Name" is duplicate?
2.
Some "names" are not login usernames or accounts, but we need either username or account
3.
Some "names" are NULL, such as capability SID's
See also: https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers

To solve this problem "Name" must be replaced with "Display Name", most "Name" values are OK,
but those which are not are replaced with "Display Name" in the "WellKnownSIDs" switch below.

TODO: Need to implement switch parameters for UPN and NETBIOS name format in addition to display name, see:
https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
TODO: Need to have consistent output ex.
domain name, principal and username, see test results,
probably not for pseudo accounts but for built in accounts it makes sense
TODO: Need to implement CIM switch
TODO: Test pipeline with multiple computers and SID's, probably it make no sense for multiple targets

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SID.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SID.md)

[http://support.microsoft.com/kb/243330](http://support.microsoft.com/kb/243330)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab)

[https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers](https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers)

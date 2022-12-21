---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md
schema: 2.0.0
---

# Test-Credential

## SYNOPSIS

Validates Windows user credentials.

## SYNTAX

```powershell
Test-Credential [-Credential] <PSCredential> [-Local] [<CommonParameters>]
```

## DESCRIPTION

Validates a \[PSCredential\] instance representing user-account credentials
against the current user's logon domain or local machine.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-Credential -Credential user
True
```

Prompts for the password for user "user" and validates it against the current
logon domain (which may be the local machine).
'True' ($true) as the output
indicates successful validation.

### EXAMPLE 2

```powershell
Test-Credential domain\user
```

Prompts for the password for user "domain\user" and validates it against
the current logon domain, whose NETBIOS name (as reflected in $env:USERDOMAIN)
must match.

### EXAMPLE 3

```powershell
Test-Credential user@domain.example.org
```

Prompts for the password for user "user@domain.example.org" and validates it against
the current logon domain, whose DNS name (as reflected in $env:USERDNSDOMAIN)
is expected to match; if not, a warning is issued, but validation is still
attempted.

### EXAMPLE 4

```powershell
Test-Credential Administrator -Local
```

Prompts for the password of the machine-local administrator account and
validates it against the local user database.

## PARAMETERS

### -Credential

The \[PSCredential\] instance to validate, typically obtained with Get-Credential.

The .UserName value may be:

- A mere username: e.g, "user"
- Prefixed with a NETBIOS domain name (NTLM format): e.g., "domain\user"
- In UPN format: e.g., "user@domain.example.org"

IMPORTANT:
If the logon domain is the current machine, validation happens against the local user database.

IRRESPECTIVE OF THE DOMAIN NAME SPECIFIED, VALIDATION IS ONLY EVER PERFORMED
AGAINST THE CURRENT USER'S LOGON DOMAIN.

If an NTLM-format username is specified, the NETBIOS domain prefix, if specified,
must match the NETBIOS logon domain as reflected in $env:USERDOMAIN

If a UPN-format username is specified, its domain suffix should match $env:USERDNSDOMAIN,
although if it doesn't, only a warning is issued and an attempt to validate against the
logon domain is still attempted, so as to support UPNs whose domain suffix differs from
the logon DNS name.
To avoid the warning, use the NTLM-format username with the NETBIOS domain prefix,
or omit the domain part altogether.

If the credentials are valid in principle, but using them with the target account is
in effect not possible - such as due to the account being disabled or having expired -
a warning to that effect is issued and $false is returned.

The SecureString instance containing the decrypted password in the input credentials is
decrypted *in local memory*, though it is again encrypted *in transit* when querying
Active Directory.

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Local

Use this switch to validate perform validation against the local machine's
user database rather than against the current logon domain.

If you're not currently logged on to a domain, use of this switch is optional.
Conversely, however, the only way to validate against a domain is to be logged on to it.

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

### None. You cannot pipe objects to Test-Credential

## OUTPUTS

### [bool] A Boolean indicating whether the credentials were successfully validated

## NOTES

Gratefully adapted from:
https://gallery.technet.microsoft.com/scriptcenter/Test-Credential-dda902c6,
via https://stackoverflow.com/q/10802850/45375
WinAPI solution for local-account validation inspired by:
https://stackoverflow.com/a/15644447/45375

Modifications by metablaster:
February 2022:
Added SuppressMessageAttribute to suppress PSUseCompatibleType warning
Adapted code and comment formating and variable casing to be in line with the rest of code in repository
Added OutputType attribute and additional links

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-Credential.md)

[https://gist.github.com/mklement0/83e8e6a2b39ecec7b0a14a8e631769ce](https://gist.github.com/mklement0/83e8e6a2b39ecec7b0a14a8e631769ce)

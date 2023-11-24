---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md
schema: 2.0.0
---

# Test-UPN

## SYNOPSIS

Validate Universal Principal Name syntax

## SYNTAX

### None (Default)

```powershell
Test-UPN [-Name] <String[]> [-Quiet] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Prefix

```powershell
Test-UPN [-Name] <String[]> [-Prefix] [-Quiet] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Suffix

```powershell
Test-UPN [-Name] <String[]> [-Suffix] [-Quiet] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Test if Universal Principal Name (UPN) has valid syntax.
UPN consists of user account name, also known as the logon name and
UPN suffix, also known as the domain name.
(or an IP address)

## EXAMPLES

### EXAMPLE 1

```powershell
Test-UPN Administrator@machine.lan
True or False
```

### EXAMPLE 2

```powershell
Test-UPN "Use!r" -Prefix
False
```

### EXAMPLE 3

```powershell
Test-UPN "user@192.8.1.1"
False
```

### EXAMPLE 4

```powershell
Test-UPN "user@[192.8.1.1]"
True
```

### EXAMPLE 5

```powershell
Test-UPN "User@site.domain.-com" -Suffix
False
```

## PARAMETERS

### -Name

Universal Principal Name in form of: user@domain.com
If -Prefix is specified, domain name can be omitted.
If -Suffix is specified, logon name can be omitted.

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

### -Prefix

If specified, validate only the user name portion of a User Principal Name

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Prefix
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Suffix

If specified, validate only the domain name portion of a User Principal Name

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Suffix
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, UPN syntax errors are not shown, only true or false is returned.

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

User Principal Name (UPN)
A user account name (sometimes referred to as the user logon name) and a domain name identifying the
domain in which the user account is located.
This is the standard usage for logging on to a Windows domain.
The format is: someone@example.com (as for an email address).
TODO: There is a thing such as: "MicrosoftAccount\TestUser@domain.com"

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-UPN.md)

[https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats](https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats)

---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Split-Principal.md
schema: 2.0.0
---

# Split-Principal

## SYNOPSIS

Split principal to either user name or domain

## SYNTAX

```powershell
Split-Principal [-Principal] <String[]> [-DomainName] [<CommonParameters>]
```

## DESCRIPTION

Split principal, either UPN or NETBIOS name to user name or domain name

## EXAMPLES

### EXAMPLE 1

```powershell
Split-Principal COMPUTERNAME\USERNAME
```

### EXAMPLE 2

```
@(SERVER\USER, user@domain.lan, SERVER2\USER2) | Split-Principal -DomainName
```

## PARAMETERS

### -Principal

One or more principals in form of UPN or NetBIOS Name.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Account

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DomainName

If specified, the result is domain name instead of user name

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

### [string]

## NOTES

None.

## RELATED LINKS

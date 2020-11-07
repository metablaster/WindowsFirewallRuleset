---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-UserAccount.md
schema: 2.0.0
---

# ConvertFrom-UserAccount

## SYNOPSIS

Strip computer names out of computer accounts

## SYNTAX

```none
ConvertFrom-UserAccount [-UserAccount] <String[]> [<CommonParameters>]
```

## DESCRIPTION

ConvertFrom-UserAccount is a helper method to reduce typing common code
related to splitting up user accounts

## EXAMPLES

### EXAMPLE 1

```none
ConvertFrom-UserAccounts COMPUTERNAME\USERNAME
```

### EXAMPLE 2

```none
ConvertFrom-UserAccounts SERVER\USER, COMPUTER\USER, SERVER2\USER2
```

## PARAMETERS

### -UserAccount

One or more user accounts in form of: COMPUTERNAME\USERNAME

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Account

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to ConvertFrom-UserAccount

## OUTPUTS

### [string[]] array of usernames in form of: USERNAME

## NOTES

None.

## RELATED LINKS

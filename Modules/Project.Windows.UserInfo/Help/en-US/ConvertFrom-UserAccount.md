---
external help file: Project.Windows.UserInfo-help.xml
Module Name: Project.Windows.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.UserInfo/Help/en-US/ConvertFrom-UserAccount.md
schema: 2.0.0
---

# ConvertFrom-UserAccount

## SYNOPSIS
Strip computer names out of computer accounts

## SYNTAX

```
ConvertFrom-UserAccount [-UserAccounts] <String[]> [<CommonParameters>]
```

## DESCRIPTION
ConvertFrom-UserAccount is a helper method to reduce typing common code
related to splitting up user accounts

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-UserAccounts COMPUTERNAME\USERNAME
```

### EXAMPLE 2
```
ConvertFrom-UserAccounts SERVER\USER, COMPUTER\USER, SERVER2\USER2
```

## PARAMETERS

### -UserAccounts
Array of user accounts in form of: COMPUTERNAME\USERNAME

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

### None. You cannot pipe objects to ConvertFrom-UserAccounts
## OUTPUTS

### [string[]] array of usernames in form of: USERNAME
## NOTES
None.

## RELATED LINKS

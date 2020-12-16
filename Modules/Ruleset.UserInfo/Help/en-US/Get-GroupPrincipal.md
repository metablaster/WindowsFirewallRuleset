---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupPrincipal.md
schema: 2.0.0
---

# Get-GroupPrincipal

## SYNOPSIS

Get computer accounts for specified user groups on target computers

## SYNTAX

```powershell
Get-GroupPrincipal [-UserGroups] <String[]> [-ComputerNames <String[]>] [-Disabled] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1

```powershell
Get-GroupPrincipal "Users", "Administrators"
```

### EXAMPLE 2

```powershell
Get-GroupPrincipal "Users" -Machine @(DESKTOP, LAPTOP) -CIM
```

## PARAMETERS

### -UserGroups

User group on local or remote computer

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Group

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerNames

One or more computers which to query for group users

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Disabled

If specified, result is disabled accounts instead

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

### -CIM

Whether to contact CIM server (required for remote computers)

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

### [string[]] User groups

## OUTPUTS

### [PSCustomObject] Enabled user accounts in specified groups

## NOTES

CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: should we handle NT AUTHORITY, BUILTIN and similar?
TODO: plural parameter
See also (according to docs but doesn't work): Get-LocalUser -Name "MicrosoftAccount\username@outlook.com"

## RELATED LINKS

---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupPrincipal.md
schema: 2.0.0
---

# Get-GroupPrincipal

## SYNOPSIS

Get principals of specified groups on target computers

## SYNTAX

```powershell
Get-GroupPrincipal [-Group] <String[]> [-Domain <String[]>] [-Include <String>] [-Exclude <String>] [-Disabled]
 [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Get computer accounts for one or more user groups on local computer or one or more remote computers.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-GroupPrincipal "Users", "Administrators"
```

### EXAMPLE 2

```powershell
Get-GroupPrincipal "Users" -Domain @(DESKTOP, LAPTOP) -CIM
```

## PARAMETERS

### -Group

User group on local or remote computer

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: UserGroup

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Domain

One or more computers which to query for group users

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Include

Specifies a username as a wildcard pattern that this function includes in the operation.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### -Exclude

Specifies a username as a wildcard pattern that this function excludes from operation.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
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

TODO: should we handle NT AUTHORITY, BUILTIN and similar?
See also (according to docs but doesn't work): Get-LocalUser -Name "MicrosoftAccount\username@outlook.com"

## RELATED LINKS

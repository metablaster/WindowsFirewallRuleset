---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-SDDL.md
schema: 2.0.0
---

# Get-SDDL

## SYNOPSIS

Get SDDL string of a user, group or from path

## SYNTAX

### User (Default)

```powershell
Get-SDDL -User <String[]> [-Domain <String>] [-CIM] [-Merge] [<CommonParameters>]
```

### Group

```powershell
Get-SDDL [-User <String[]>] -Group <String[]> [-Domain <String>] [-CIM] [-Merge] [<CommonParameters>]
```

### Path

```powershell
Get-SDDL -Path <String> [-Domain <String>] [-CIM] [-Merge] [<CommonParameters>]
```

## DESCRIPTION

Get SDDL string for single or multiple user names and/or user groups, file system or registry
locations on a single target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SDDL -User USERNAME -Domain COMPUTERNAME -CIM
```

### EXAMPLE 2

```powershell
Get-SDDL -Group @("Users", "Administrators") -Merge
```

### EXAMPLE 3

```powershell
Get-SDDL -Domain "NT AUTHORITY" -User "System"
```

### EXAMPLE 4

```powershell
Get-SDDL -Path "HKLM:\SOFTWARE\Microsoft\Clipboard"
```

## PARAMETERS

### -User

One or more users for which to obtain SDDL string

```yaml
Type: System.String[]
Parameter Sets: User
Aliases: UserName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: System.String[]
Parameter Sets: Group
Aliases: UserName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group

One or more user groups for which to obtain SDDL string

```yaml
Type: System.String[]
Parameter Sets: Group
Aliases: UserGroup

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Single file system or registry location for which to obtain SDDL.
Wildcard characters are supported.

```yaml
Type: System.String
Parameter Sets: Path
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Domain

Single domain or computer such as remote computer name or builtin computer domain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
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

### -Merge

If specified, combines resultant SDDL strings into one

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

### None. You cannot pipe objects to Get-SDDL

## OUTPUTS

### [string]

## NOTES

None.

## RELATED LINKS

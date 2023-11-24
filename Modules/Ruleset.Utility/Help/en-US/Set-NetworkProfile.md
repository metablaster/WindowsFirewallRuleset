---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-NetworkProfile.md
schema: 2.0.0
---

# Set-NetworkProfile

## SYNOPSIS

Set network profile on connected network interfaces

## SYNTAX

### None (Default)

```powershell
Set-NetworkProfile [-NetworkCategory <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Domain

```powershell
Set-NetworkProfile [-NetworkCategory <String>] [-Domain <String>] [-Credential <PSCredential>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Session

```powershell
Set-NetworkProfile [-NetworkCategory <String>] [-Session <PSSession>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Set network profile for each connected network interface.
Recommended is "Public" profile for maximum security, unless "Private" is needed.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-NetworkProfile
```

### EXAMPLE 2

```powershell
Set-NetworkProfile Public
```

## PARAMETERS

### -NetworkCategory

Specify network category which to apply to all NIC's.
If not specified, you're prompted for each NIC individually

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Computer name on which to set network profile

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specify Credential used for authentication to Domain.

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

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
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

### None. You cannot pipe objects to Set-NetworkProfile

## OUTPUTS

### None. Set-NetworkProfile does not generate any output

## NOTES

None.

## RELATED LINKS

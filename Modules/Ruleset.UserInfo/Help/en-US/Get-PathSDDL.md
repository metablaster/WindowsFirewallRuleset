---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-PathSDDL.md
schema: 2.0.0
---

# Get-PathSDDL

## SYNOPSIS

Get SDDL string for a path

## SYNTAX

### Domain (Default)

```powershell
Get-PathSDDL [-Path] <String> [-Domain <String>] [-Credential <PSCredential>] [-Merge]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Session

```powershell
Get-PathSDDL [-Path] <String> [-Session <PSSession>] [-Merge] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Get SDDL string for file system or registry locations on a single target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PathSDDL -Path "C:\Users\Public\Desktop\" -Domain Server01 -Credential (Get-Credential)
```

### EXAMPLE 2

```powershell
Get-PathSDDL -Path "C:\Users" -Session (New-PSSession)
```

### EXAMPLE 3

```powershell
Get-PathSDDL -Path "HKLM:\SOFTWARE\Microsoft\Clipboard"
```

## PARAMETERS

### -Path

Single file system or registry location for which to obtain SDDL.
Wildcard characters are supported.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Domain

Computer name on which specified path is located

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

### None. You cannot pipe objects to Get-PathSDDL

## OUTPUTS

### [string]

## NOTES

None.

## RELATED LINKS

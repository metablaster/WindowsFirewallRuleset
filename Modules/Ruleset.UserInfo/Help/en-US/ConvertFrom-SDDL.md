---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SDDL.md
schema: 2.0.0
---

# ConvertFrom-SDDL

## SYNOPSIS

Convert SDDL string to Principal

## SYNTAX

### Domain (Default)

```powershell
ConvertFrom-SDDL [-SDDL] <String[]> [-Domain <String>] [-Credential <PSCredential>] [-Force]
 [<CommonParameters>]
```

### Session

```powershell
ConvertFrom-SDDL [-SDDL] <String[]> [-Session <PSSession>] [-Force] [<CommonParameters>]
```

## DESCRIPTION

Convert one or multiple SDDL strings to Principal, a custom object containing
relevant information about the principal.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-SDDL -SDDL "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
```

### EXAMPLE 2

```powershell
ConvertFrom-SDDL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
```

### EXAMPLE 3

```powershell
$SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)" | ConvertFrom-SDDL
```

## PARAMETERS

### -SDDL

One or more strings of SDDL syntax

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

### -Domain

Computer name from which SDDL's were taken

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

### -Force

If specified, does not perform name checking of converted string.
This is useful for example to force spliting name like:
"NT APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet"

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

### [PSCustomObject]

## NOTES

None.

## RELATED LINKS

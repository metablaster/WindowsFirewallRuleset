---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-TargetComputer.md
schema: 2.0.0
---

# Test-TargetComputer

## SYNOPSIS

Test target computer (policy store) on which to apply firewall

## SYNTAX

```powershell
Test-TargetComputer [-ComputerName] <String> [-Count <Int16>] [-Timeout <Int16>] [<CommonParameters>]
```

## DESCRIPTION

The purpose of this function is to reduce typing checks depending on whether PowerShell
core or desktop edition is used, since parameters for Test-Connection are not the same
for both PowerShell editions.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-TargetComputer "COMPUTERNAME" -Count 2 -Timeout 1
```

### EXAMPLE 2

```powershell
Test-TargetComputer "COMPUTERNAME"
```

## PARAMETERS

### -ComputerName

Target computer which to test

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Count

Valid only for PowerShell Core.
Specifies the number of echo requests to send.
The default value is 4

```yaml
Type: System.Int16
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $ConnectionCount
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout

Valid only for PowerShell Core.
The test fails if a response isn't received before the timeout expires

```yaml
Type: System.Int16
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-TargetComputer

## OUTPUTS

### [bool] false or true if target host is responsive

## NOTES

TODO: Avoid error message, check all references which handle errors (code bloat)
TODO: We should check for common issues for GPO management, not just ping status (ex.
Test-NetConnection)

## RELATED LINKS

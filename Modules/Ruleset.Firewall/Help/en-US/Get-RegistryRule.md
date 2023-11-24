---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Get-RegistryRule.md
schema: 2.0.0
---

# Get-RegistryRule

## SYNOPSIS

Gets firewall rules directly from registry

## SYNTAX

### None (Default)

```powershell
Get-RegistryRule [-Domain <String>] [-Local] [-GroupPolicy] [-DisplayGroup <String>] [-Direction <String>]
 [-Action <String>] [-Enabled <String>] [-Raw] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### NotAllowingEmptyString

```powershell
Get-RegistryRule [-Domain <String>] [-Local] [-GroupPolicy] -DisplayName <String> [-DisplayGroup <String>]
 [-Direction <String>] [-Action <String>] [-Enabled <String>] [-Raw] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Get-RegistryRule gets firewall rules by drilling registry and parsing registry values.
This method to retrieve rules results is very fast export compared to conventional way.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-RegistryRule -GroupPolicy
```

### EXAMPLE 2

```powershell
Get-RegistryRule -Action Block -Enabled False
```

### EXAMPLE 3

```powershell
Get-RegistryRule -Direction Outbound -DisplayName "Edge-Chromium HTTPS"
```

## PARAMETERS

### -Domain

Computer name from which rules are to be retrieved

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

### -Local

Retrive rules from persistent store (control panel firewall)

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

### -GroupPolicy

Retrive rules from local group policy store (GPO firewall)

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

### -DisplayName

Specifies that only matching firewall rules of the indicated display name are retrieved
Wildcard characters are accepted.
DisplayName is case sensitive.

```yaml
Type: System.String
Parameter Sets: NotAllowingEmptyString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -DisplayGroup

Specifies that only matching firewall rules of the indicated group association are retrieved
Wildcard characters are accepted.
DisplayGroup is case sensitive.

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

### -Direction

Specifies that matching firewall rules of the indicated direction are retrieved

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

### -Action

Specifies that matching firewall rules of the indicated action are retrieved

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

### -Enabled

Specifies that matching firewall rules of the indicated state are retrieved

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

### -Raw

If specified, instead of PSCustomObject a string array of rules is returned exactly as they are
stored in the registry.
Output format is same as for *.reg files

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

### None. You cannot pipe objects to Get-RegistryRule

## OUTPUTS

### [PSCustomObject]

## NOTES

TODO: Getting rules from persistent store (-Local switch) needs testing.
TODO: Design, Parameters -Local and -GroupPolicy must be converted to -PolicyStore?
what about -Domain then?
Not implementing more parameters because only those here are always present in registry in all rules.
ParameterSetName = "NotAllowingEmptyString" is there because $DisplayName if not specified casts to
empty string due to \[string\] declaration, which is the same thing as specifying -DisplayName "",
we deny both with dummy parameter set name and setting default parameter set name to something else.
TODO: Parameter to ignore case sensitive DisplayName and DisplayGroup, then also update  Export-RegistryRule

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Get-RegistryRule.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Get-RegistryRule.md)

[https://stackoverflow.com/questions/53246271/get-netfirewallruleget-netfirewallportfilter-are-too-slow](https://stackoverflow.com/questions/53246271/get-netfirewallruleget-netfirewallportfilter-are-too-slow)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpfas/2efe0b76-7b4a-41ff-9050-1023f8196d16](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpfas/2efe0b76-7b4a-41ff-9050-1023f8196d16)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fasp/8c008258-166d-46d4-9090-f2ffaa01be4b](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fasp/8c008258-166d-46d4-9090-f2ffaa01be4b)

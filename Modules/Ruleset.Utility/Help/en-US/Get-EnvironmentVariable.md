---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-EnvironmentVariable.md
schema: 2.0.0
---

# Get-EnvironmentVariable

## SYNOPSIS

Get a group of environment variables

## SYNTAX

```none
Get-EnvironmentVariable [-Group] <String> [<CommonParameters>]
```

## DESCRIPTION

Get-EnvironmentVariable gets a predefined group of environment variables.
This is useful to verify path patterns, ex.
paths for firewall rules must not
contain paths with userprofile environment variable.

## EXAMPLES

### EXAMPLE 1

```none
Get-EnvironmentVariable UserProfile
```

Returns all environment variables that lead to user profile

### EXAMPLE 2

```none
Get-EnvironmentVariable All
```

Returns all environment variables on computer

## PARAMETERS

### -Group

A group of environment variables to get as follows:
1.
UserProfile - Environment variables that leads to valid directory in user profile
2.
WhiteList - Environment variables which are valid directories
3.
BlackList - The opposite of WhiteList
4.
All - Whitelist and BlackList together

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-EnvironmentVariable

## OUTPUTS

### [System.Collections.DictionaryEntry]

## NOTES

None.

## RELATED LINKS

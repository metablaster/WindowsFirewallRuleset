---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-UserProfile.md
schema: 2.0.0
---

# Test-UserProfile

## SYNOPSIS

Check if input path leads to user profile

## SYNTAX

```none
Test-UserProfile [[-FilePath] <String>] [<CommonParameters>]
```

## DESCRIPTION

User profile paths are not valid for firewall rules, this method help make a check
if this is true

## EXAMPLES

### EXAMPLE 1

```none
Test-UserProfile "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
```

## PARAMETERS

### -FilePath

File path to check, can be unformatted or have environment variables

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-UserProfile

## OUTPUTS

### [bool] true if userprofile path or false otherwise

## NOTES

TODO: is it possible to nest this into Test-Environment somehow?

## RELATED LINKS

---
external help file: Ruleset.PolicyFileEditor-help.xml
Module Name: Ruleset.PolicyFileEditor
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.PolicyFileEditor/Help/en-US/Get-PolicyFileEntry.md
schema: 2.0.0
---

# Get-PolicyFileEntry

## SYNOPSIS

Retrieves the current setting(s) from a .pol file.

## SYNTAX

### ByKeyAndValue (Default)

```powershell
Get-PolicyFileEntry [-Path] <String> [-Key] <String> [-ValueName] <String> [<CommonParameters>]
```

### All

```powershell
Get-PolicyFileEntry [-Path] <String> [-All] [<CommonParameters>]
```

## DESCRIPTION

Retrieves the current setting(s) from a .pol file.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue
```

Reads the value of Software\Policies\Something\SomeValue from the Machine admin templates of the local GPO.
Either returns an object with the data and type of this registry value (if present),
or returns nothing, if not found.

### EXAMPLE 2

```powershell
Get-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol -All
```

Outputs all of the registry values from the local machine Administrative Templates

## PARAMETERS

### -Path

Path to the .pol file that is to be read.

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

### -Key

The registry key inside the .pol file that you want to read.

```yaml
Type: System.String
Parameter Sets: ByKeyAndValue
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValueName

The name of the registry value.
May be set to an empty string to read the default value of a key.

```yaml
Type: System.String
Parameter Sets: ByKeyAndValue
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All

Switch indicating that all entries from the specified .pol file should be output,
instead of searching for a specific key\ValueName pair.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. This command does not accept pipeline input.

## OUTPUTS

### If the specified registry value is found, the function outputs a PSCustomObject with the following properties:

### ValueName: The same value that was passed to the -ValueName parameter

### Key: The same value that was passed to the -Key parameter

### Data: The current value assigned to the specified Key\ValueName in the .pol file.

### Type: The RegistryValueKind type of the specified Key\ValueName in the .pol file.

### If the specified registry value is not found in the .pol file, the command returns nothing. No error is produced.

## NOTES

None.

## RELATED LINKS

---
external help file: Ruleset.PolicyFileEditor-help.xml
Module Name: Ruleset.PolicyFileEditor
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.PolicyFileEditor/Help/en-US/Remove-PolicyFileEntry.md
schema: 2.0.0
---

# Remove-PolicyFileEntry

## SYNOPSIS

Removes a value from a .pol file.

## SYNTAX

```powershell
Remove-PolicyFileEntry [-Path] <String> [-Key] <String> [-ValueName] <String> [-NoGptIniUpdate] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Removes a value from a .pol file.
By default, also updates the version number in the policy's gpt.ini file.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
    -Key Software\Policies\Something -ValueName SomeValue
```

Removes the value Software\Policies\Something\SomeValue from the local computer Machine GPO, if present.
Updates the Machine version counter in $env:systemroot\system32\GroupPolicy\gpt.ini

### EXAMPLE 2

```powershell
$Entries = @(
    New-Object PSObject -Property @{ ValueName = "MaxXResolution"; Data = 1680 }
    New-Object PSObject -Property @{ ValueName = "MaxYResolution"; Data = 1050 }
)
PS> $Entries | Remove-PolicyFileEntry -Path $env:SystemRoot\system32\GroupPolicy\Machine\registry.pol `
    -Key "SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
```

Example of using pipeline input to remove multiple values at once.
The advantage to this approach is that the .pol file on disk (and the GPT.ini file) will be updated
if _any_ of the specified settings had to be removed, and will be left alone if the file already
did not contain any of those values.

The Key property could have also been specified via the pipeline objects instead of on the command line,
but since both values shared the same Key, this example shows that you can pass the value in either way.

## PARAMETERS

### -Path

Path to the .pol file that is to be modified.

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

The registry key inside the .pol file from which you want to remove a value.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ValueName

The name of the registry value to be removed.
May be set to an empty string to remove the default value of a key.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NoGptIniUpdate

When this switch is used, the command will not attempt to update the version number in the gpt.ini file

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### The Key and ValueName properties may be bound via the pipeline by property name

## OUTPUTS

### None. Remove-PolicyFileEntry does not generate output

## NOTES

If the specified policy file is already not present in the .pol file,
the file will not be modified, and the gpt.ini file will not be updated.

## RELATED LINKS

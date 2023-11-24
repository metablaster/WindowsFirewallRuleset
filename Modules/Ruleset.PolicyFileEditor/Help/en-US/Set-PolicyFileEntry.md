---
external help file: Ruleset.PolicyFileEditor-help.xml
Module Name: Ruleset.PolicyFileEditor
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.PolicyFileEditor/Help/en-US/Set-PolicyFileEntry.md
schema: 2.0.0
---

# Set-PolicyFileEntry

## SYNOPSIS

Creates or modifies a value in a .pol file.

## SYNTAX

```powershell
Set-PolicyFileEntry [-Path] <String> [-Key] <String> [-ValueName] <String> [-Data] <Object>
 [-Type <RegistryValueKind>] [-NoGptIniUpdate] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Creates or modifies a value in a .pol file.
By default, also updates the version number in the policy's gpt.ini file.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
        -Key Software\Policies\Something -ValueName SomeValue -Data "Hello, World!" -Type String
```

Assigns a value of "Hello, World!" to the String value Software\Policies\Something\SomeValue in the
local computer Machine GPO.
Updates the Machine version counter in $env:systemroot\system32\GroupPolicy\gpt.ini

### EXAMPLE 2

```powershell
Set-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
        -Key Software\Policies\Something -ValueName SomeValue -Data "Hello, World!" -Type String -NoGptIniUpdate
```

Same as example 1, except this one does not update gpt.ini right away.
This can be useful if you want to set multiple
values in the policy file and only trigger a single Group Policy refresh.

### EXAMPLE 3

```powershell
Set-PolicyFileEntry -Path $env:systemroot\system32\GroupPolicy\Machine\registry.pol `
        -Key Software\Policies\Something -ValueName SomeValue -Data "0x12345" -Type DWord
```

Example demonstrating that strings with valid numeric data (including hexadecimal strings beginning with 0x)
can be assigned to the numeric types DWord, QWord and Binary.

### EXAMPLE 4

```powershell
$entries = @(
    New-Object PSObject -Property @{ ValueName = "MaxXResolution"; Data = 1680 }
    New-Object PSObject -Property @{ ValueName = "MaxYResolution"; Data = 1050 }
)
PS> $entries | Set-PolicyFileEntry -Path $env:SystemRoot\system32\GroupPolicy\Machine\registry.pol `
        -Key "SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Type DWord
```

Example of using pipeline input to set multiple values at once.
The advantage to this approach is that the .pol file on disk (and the GPT.ini file) will be updated
if _any_ of the specified settings had to be modified,
and will be left alone if the file already contained all of the correct values.

The Key and Type properties could have also been specified via the pipeline objects instead of on the
command line, but since both values shared the same Key and Type, this example shows that you can
pass the values in either way.

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

The registry key inside the .pol file that you want to modify.

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

The name of the registry value.
May be set to an empty string to modify the default value of a key.

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

### -Data

The new value to assign to the registry key / value.
Cannot be $null, but can be set to an empty string or empty array.

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Type

The type of registry value to set in the policy file.
Cannot be set to Unknown or None, but all other values of the RegistryValueKind enum are legal.

```yaml
Type: Microsoft.Win32.RegistryValueKind
Parameter Sets: (All)
Aliases:
Accepted values: Unknown, String, ExpandString, Binary, DWord, MultiString, QWord, None

Required: False
Position: Named
Default value: String
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

### The Key, ValueName, Data, and Type properties may be bound via the pipeline by property name

## OUTPUTS

### None. Set-PolicyFileEntry does not generate output

## NOTES

If the specified policy file already contains the correct value, the file will not be modified,
and the gpt.ini file will not be updated.

## RELATED LINKS

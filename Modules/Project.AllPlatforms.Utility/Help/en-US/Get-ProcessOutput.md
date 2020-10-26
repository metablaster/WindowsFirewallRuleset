---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-ProcessOutput.md
schema: 2.0.0
---

# Get-ProcessOutput

## SYNOPSIS

Run process and capture output

## SYNTAX

```none
Get-ProcessOutput [-FilePath] <String> [[-ArgumentList] <String>] [-NoNewWindow] [[-Wait] <UInt32>] [-Format]
 [<CommonParameters>]
```

## DESCRIPTION

Run process with or without arguments, set wait time and capture output.
If the target process results in an error, error message is formatted and shown in addition
to standard output if any.

## EXAMPLES

### EXAMPLE 1

```none
Get-ProcessOutput -FilePath "git.exe" -ArgumentList "status" -NoNewWindow -Wait 3000
```

## PARAMETERS

### -FilePath

The application or document to start

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

### -ArgumentList

A collection of command-line arguments to use when starting the application

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoNewWindow

Whether to use the operating system shell to start the process

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

### -Wait

Number of milliseconds to wait for the associated process to exit
Default is 0, which means wait indefinitely

```yaml
Type: System.UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Format

If specified formats standard output into INFO messages

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

### None. You cannot pipe objects to Get-ProcessOutput

## OUTPUTS

### None.

## NOTES

None.

## RELATED LINKS

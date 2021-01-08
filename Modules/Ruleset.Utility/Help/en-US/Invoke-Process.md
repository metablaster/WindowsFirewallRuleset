---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md
schema: 2.0.0
---

# Invoke-Process

## SYNOPSIS

Run process and format captured output

## SYNTAX

```powershell
Invoke-Process [-Path] <String> [-ArgumentList <String>] [-NoNewWindow] [-Timeout <Int32>] [-Async] [-Raw]
 [<CommonParameters>]
```

## DESCRIPTION

Run process with or without arguments, set process timeout, capture and format output.
If target process produces error, error message is formatted and shown in addition
to standard output if any.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-Process git.exe -ArgumentList "status" -NoNewWindow -Wait 3000
```

### EXAMPLE 2

```powershell
Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Async -Timeout 3000
```

## PARAMETERS

### -Path

Executable name or path to application to which to start.
Wildcard characters and relative paths are supported.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: FilePath

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -ArgumentList

A collection of command-line arguments to use when starting the application

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

### -Timeout

The amount of time, in milliseconds, to wait for the associated process to exit.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 10000 (10 seconds).

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 10000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Async

If specified, reading process output is asynchronous.
This functionality is experimental because current thread will block until timeout.

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

### -Raw

If specified, process output is returned as string.
By default process output is redirected to information and error stream.

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

### None. You cannot pipe objects to Invoke-Process

## OUTPUTS

### [string]

### [System.Threading.CancellationTokenSource]

### [void]

## NOTES

TODO: Because of uncertain output this function needs a lot of improvements and a lot more test cases
to handle variable varieties of process outputs.
TODO: Domain parameter needed to invoke process remotely

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Invoke-Process.md)

[https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process](https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process)

---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md
schema: 2.0.0
---

# Test-ExecutableFile

## SYNOPSIS

Check if executable file exists and is trusted.

## SYNTAX

```powershell
Test-ExecutableFile [-LiteralPath] <String> [-Force] [<CommonParameters>]
```

## DESCRIPTION

Test-ExecutableFile verifies the path to executable file is valid and that executable itself exists.
File extension is then verified to confirm it is whitelisted, ex.
such as an *.exe
The executable is then verified to ensure it's digitaly signed and that signature is valid.
If the file can't be found or verified, an error is genrated possibly with informational message,
to explain if there is any problem with the path or file name syntax, otherwise information is
present to the user to explain how to resolve the problem including a stack trace to script that
is producing this issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-ExecutableFile "C:\Windows\UnsignedFile.exe"
```

ERROR: Digital signature verification failed for: C:\Windows\UnsignedFile.exe

### EXAMPLE 2

```powershell
Test-ExecutableFile "C:\Users\USERNAME\AppData\Application\chrome.exe"
```

WARNING: Executable 'chrome.exe' was not found, firewall rule not loaded
INFO: Searched path was: C:\Users\USERNAME\AppData\Application\chrome.exe
INFO: To fix this problem find 'chrome.exe' and update installation directory in Test-ExecutableFile.ps1 script

### EXAMPLE 3

```powershell
Test-ExecutableFile "\\COMPUTERNAME\Directory\file.exe"
```

ERROR: Specified file path is missing a file system qualifier: \\\\COMPUTERNAME\Directory\file.exe

### EXAMPLE 4

```powershell
Test-ExecutableFile ".\..\file.exe"
```

ERROR: Specified file path is relative: .\..\file.exe

### EXAMPLE 5

```powershell
Test-ExecutableFile "C:\Bad\<Path>\Loca'tion"
```

ERROR: Specified file path contains invalid characters: C:\Bad\\\<Path\>\Loca'tion

## PARAMETERS

### -LiteralPath

Fully qualified path to executable file

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

### -Force

If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in bypassed signature test.

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

### None. You cannot pipe objects to Test-ExecutableFile

## OUTPUTS

### [bool]

## NOTES

TODO: We should attempt to fix the path if invalid here, ex.
Get-Command
TODO: We should return true or false and conditionally load rule
TODO: Verify file is executable file (and path formatted?)

## RELATED LINKS

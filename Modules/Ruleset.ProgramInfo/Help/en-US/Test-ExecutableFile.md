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

### Domain (Default)

```powershell
Test-ExecutableFile [-LiteralPath] <String> [-Domain <String>] [-Credential <PSCredential>]
 [-SigcheckLocation <DirectoryInfo>] [-TimeOut <Int32>] [-Quiet] [-Force] [<CommonParameters>]
```

### Session

```powershell
Test-ExecutableFile [-LiteralPath] <String> [-Session <PSSession>] [-SigcheckLocation <DirectoryInfo>]
 [-TimeOut <Int32>] [-Quiet] [-Force] [<CommonParameters>]
```

## DESCRIPTION

Test-ExecutableFile verifies the path to executable file is valid and that executable itself exists.
File extension is then verified to confirm it is whitelisted, ex.
such as an *.exe
The executable is then verified to ensure it's digitaly signed and that signature is valid.
If digital signature is missing or not valid, the file is optionally scanned on VirusTotal to
confirm it's not malware.
If the file can't be found or verified, an error is genrated possibly with informational message,
to explain if there is any problem with the path or file name syntax, otherwise information is
present to the user to explain how to resolve the problem including a stack trace to script that
is producing this issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-ExecutableFile "C:\Windows\UnsignedFile.exe"
```

ERROR: Digital signature verification failed for 'C:\Windows\UnsignedFile.exe'
INFO: If you trust this executable run 'CallerScript.ps1' with -Trusted switch

### EXAMPLE 2

```powershell
Test-ExecutableFile "C:\Users\USERNAME\AppData\Application\file.paf"
```

ERROR: File extension 'PAF' is blacklisted executable file 'C:\Users\USERNAME\AppData\Application\file.paf'
INFO: Blocked file 'file.paf' is Portable Application Installer File

### EXAMPLE 3

```powershell
Test-ExecutableFile ".\directory\..\file.exe"
```

WARNING: Specified file path contains parent directory notation '$ExpandedPath'

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

### -Domain

Computer name on which executable file to be tested is located

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SigcheckLocation

Specify path to sigcheck executable program.
Do not specify sigcheck file, only path to where sigcheck is located.
By default working directory and PATH is searched for sigcheck64.exe.
On 32 bit operating system sigcheck.exe is searched instead.
If location to sigcheck executable is not found then no VirusTotal scan and report is done.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $SigcheckPath
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeOut

Specify maximum wait time expressed in seconds for VirusTotal to scan individual file.
Value 0 means an immediate return, and a value of -1 specifies an infinite wait.
The default wait time is 300 (5 minutes).

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 300
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, no information, warning or error message is shown, only true or false is returned

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

### -Force

If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in bypassed signature test.
This parameter has no effect on VirusTotal check, if the file is reported as malware the return
value is $false unless SkipVirusTotalCheck global variable is set.

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
Get-Command (-Repair parameter)
TODO: We should return true or false and conditionally load rule
TODO: Verify file is executable file (and path formatted?)

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-ExecutableFile.md)

[https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.signature](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.signature)

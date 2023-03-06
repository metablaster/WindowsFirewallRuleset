---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md
schema: 2.0.0
---

# Test-VirusTotal

## SYNOPSIS

Analyze file trough VirusTotal API

## SYNTAX

### Domain (Default)

```powershell
Test-VirusTotal -LiteralPath <String> [-Domain <String>] [-Credential <PSCredential>]
 [-SigcheckLocation <String>] [-TimeOut <Int32>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Session

```powershell
Test-VirusTotal -LiteralPath <String> [-Session <PSSession>] [-SigcheckLocation <String>] [-TimeOut <Int32>]
 [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Test-VirusTotal performs malware analysis on file by using sysinternals sigcheck
program which in turn uses VirusTotal API to perform analysis.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-VirusTotal -LiteralPath "C:\Windows\notepad.exe" -SigcheckLocation "C:\tools"
```

## PARAMETERS

### -LiteralPath

Fully qualified path to executable file which is to be tested

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### -Force

If specified, sigcheck is downloaded if it's not found and is used without user prompt

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

### None. You cannot pipe objects to Test-VirusTotal

## OUTPUTS

### [bool]

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-VirusTotal.md)

[https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck](https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck)

[https://support.virustotal.com/hc/en-us/articles/115002145529-Terms-of-Service](https://support.virustotal.com/hc/en-us/articles/115002145529-Terms-of-Service)

[https://support.virustotal.com/hc/en-us/articles/115002168385-Privacy-Policy](https://support.virustotal.com/hc/en-us/articles/115002168385-Privacy-Policy)

---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md
schema: 2.0.0
---

# Test-Service

## SYNOPSIS

Check if system service exists and is trusted

## SYNTAX

### Domain (Default)

```powershell
Test-Service [-Name] <String> [-Domain <String>] [-Credential <PSCredential>]
 [-SigcheckLocation <DirectoryInfo>] [-TimeOut <Int32>] [-Quiet] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Session

```powershell
Test-Service [-Name] <String> [-Session <PSSession>] [-SigcheckLocation <DirectoryInfo>] [-TimeOut <Int32>]
 [-Quiet] [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Test-Service verifies specified Windows services exists.
The service is then verified to confirm it's digitaly signed and that signature is valid.
If the service can't be found or verified, an error is genrated.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-Service dnscache
```

### EXAMPLE 2

```powershell
Test-Service WSearch -Domain Server01
```

### EXAMPLE 3

```powershell
Test-Service SomeService -Quiet -Force
```

## PARAMETERS

### -Name

Service short name (not display name)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ServiceName

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Domain

Computer name on which service to be tested is located

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
instead of an error resulting in passed test.

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

### [string[]]

## OUTPUTS

### [bool]

## NOTES

TODO: Implement accept ServiceController object, should be called InputObject, a good design needed,
however it doesn't make much sense since the function is to test existence of a service too.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md)

[https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.signature](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.signature)

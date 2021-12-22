---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md
schema: 2.0.0
---

# Test-WinRM

## SYNOPSIS

Test WinRM service configuration

## SYNTAX

### Default (Default)

```powershell
Test-WinRM [[-Domain] <String>] [-Protocol <String>] [-Port <Int32>] [-UICulture <CultureInfo>]
 [-Culture <CultureInfo>] [-Status <PSReference>] [-Quiet] [<CommonParameters>]
```

### ThumbPrint

```powershell
Test-WinRM [[-Domain] <String>] [-Protocol <String>] [-Port <Int32>] [-CertThumbprint <String>]
 [-UICulture <CultureInfo>] [-Culture <CultureInfo>] [-Status <PSReference>] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION

Test WinRM service (server) configuration on either client or server computer.
WinRM service is tested for functioning connectivity which includes
PowerShell remoting, remoting with CIM commandlets and user authentication.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-WinRM HTTP
```

### EXAMPLE 2

```powershell
Test-WinRM -Domain Server1 -Protocol Any
```

### EXAMPLE 3

```
$RemoteStatus = $false
PS> Test-WinRM HTTP -Quiet -Status $RemoteStatus
```

## PARAMETERS

### -Domain

Target host which is to be tested.
If not specified, local machine is the default

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protocol

Specify protocol to use for test, HTTP, HTTPS or both.
By default only HTTPS is tested.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: HTTPS
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port

Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint

Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

```yaml
Type: System.String
Parameter Sets: ThumbPrint
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UICulture

Specifies the user interface culture to use for the CIM session,
in Windows this setting is known as "Windows display language"
The default value is en-US, current value can be obtained with Get-UICulture

```yaml
Type: System.Globalization.CultureInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [System.Globalization.CultureInfo]::new("en-US", $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Culture

Controls the formats used to represent numbers, currency values, and date/time values,
in Windows this setting is known as "Region and regional format"
The default value is en-US, current value can be obtained with Get-Culture

```yaml
Type: System.Globalization.CultureInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [System.Globalization.CultureInfo]::new("en-US", $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status

Boolean reference variable used for return value which indicates whether the test was success

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, does not produce errors, success messages or informational action messages

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

### None. You cannot pipe objects to Test-WinRM

## OUTPUTS

### None. Test-WinRM does not generate any output

## NOTES

TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Remote registry test
TODO: Default test should be to localhost which must not ask for credentials

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md)

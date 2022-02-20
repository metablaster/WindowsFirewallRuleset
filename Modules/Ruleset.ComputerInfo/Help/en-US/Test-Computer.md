---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-Computer.md
schema: 2.0.0
---

# Test-Computer

## SYNOPSIS

Test target computer (policy store) on which to deploy firewall

## SYNTAX

### WSMan (Default)

```powershell
Test-Computer [-Domain] <String> [-Protocol <String>] [-Port <Int32>] [-Credential <PSCredential>]
 [-Authentication <String>] [-CertThumbprint <String>] [<CommonParameters>]
```

### Ping

```powershell
Test-Computer [-Domain] <String> [-Protocol <String>] [-Retry <Int16>] [-Timeout <Int16>] [<CommonParameters>]
```

## DESCRIPTION

The purpose of this function is network test consistency, depending on whether PowerShell
Core or Desktop edition is used and depending on kind of test needed, since parameters are
different for Test-Connection, Test-NetConnection, Test-WSMan, PS edition etc.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-Computer "Server1" -Credential (Get-Credential)
```

### EXAMPLE 2

```powershell
Test-Computer "Server2" -Count 2 -Timeout 1 -Protocol Ping
```

### EXAMPLE 3

```powershell
Test-Computer "Server3" -Count 2 -Timeout 1
```

## PARAMETERS

### -Domain

Target computer which to test for connectivity

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protocol

Specify the kind of a test to perform.
Acceptable values are HTTP (WSMan), HTTPS (WSMan), Ping or Default
The default is "Default" which tries connectivity in this order: HTTPS\HTTP\Ping

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port

Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port

```yaml
Type: System.Int32
Parameter Sets: WSMan
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specify credentials required for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: WSMan
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Authentication

Specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.

```yaml
Type: System.String
Parameter Sets: WSMan
Aliases:

Required: False
Position: Named
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint

Optionally specify certificate thumbprint which is to be used for WinRM over SSL.

```yaml
Type: System.String
Parameter Sets: WSMan
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retry

Specifies the number of echo requests to send.
The default value is 4.
Valid only for PowerShell Core
The default value is defined in $PSSessionOption preference variable

```yaml
Type: System.Int16
Parameter Sets: Ping
Aliases:

Required: False
Position: Named
Default value: $PSSessionOption.MaxConnectionRetryCount
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout

The test fails if a response isn't received before the timeout expires.
Valid only for PowerShell Core.
The default value is 2 seconds.

```yaml
Type: System.Int16
Parameter Sets: Ping
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-Computer

## OUTPUTS

### [bool] True if target host is responsive, false otherwise

## NOTES

TODO: We should check for common issues for GPO management, not just ping status (ex.
Test-NetConnection)

## RELATED LINKS

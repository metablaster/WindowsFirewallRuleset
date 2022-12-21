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

### Credential (Default)

```powershell
Test-WinRM [[-Domain] <String>] [-Credential <PSCredential>] [-Protocol <String>] [-Port <Int32>]
 [-Authentication <String>] [-UICulture <CultureInfo>] [-Culture <CultureInfo>] [-ApplicationName <String>]
 [-SessionOption <PSSessionOption>] [-ConfigurationName <String>] [-CimOptions <CimSessionOptions>]
 [-Status <PSReference>] [-Quiet] [<CommonParameters>]
```

### Cert

```powershell
Test-WinRM [[-Domain] <String>] [-Protocol <String>] [-Port <Int32>] [-Authentication <String>]
 [-CertThumbprint <String>] [-UICulture <CultureInfo>] [-Culture <CultureInfo>] [-ApplicationName <String>]
 [-SessionOption <PSSessionOption>] [-ConfigurationName <String>] [-CimOptions <CimSessionOptions>]
 [-Status <PSReference>] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION

Test WinRM service (server) configuration on either client or server computer.
WinRM service is tested for functioning connectivity which includes
PowerShell remoting, remoting with CIM commandlets and creation of PS session.

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

```powershell
$RemoteStatus = $false
PS> Test-WinRM HTTP -Quiet -Status $RemoteStatus
```

## PARAMETERS

### -Domain

Computer name which is to be tested for functioning WinRM.
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

### -Credential

Specify credentials which to use to test connection to remote computer.
Credentials are required for HTTPS and remote connections.
If not specified, you'll be asked for credentials

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Credential
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protocol

Specify protocol to use for test, HTTP, HTTPS or Default.
The default value is "Default", which means HTTPS is tested first and if failed HTTP is tested.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $RemotingProtocol
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port

Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port.
The default value if 5985 for HTTP and 5986 for HTTPS.

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

### -Authentication

Optionally specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.
The default value is "Default"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $RemotingAuthentication
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertThumbprint

Optionally specify certificate thumbprint which is to be used for HTTPS.
Use this parameter when there are multiple certificates with same DNS entries.

```yaml
Type: System.String
Parameter Sets: Cert
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
Default value: $DefaultUICulture
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
Default value: $DefaultCulture
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationName

Specifies the application name in the connection.
The default value is controlled with PSSessionApplicationName preference variable

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PSSessionApplicationName
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionOption

Specify custom PSSessionOption object to use for remoting.
The default value is controlled with PSSessionOption variable from caller scope

```yaml
Type: System.Management.Automation.Remoting.PSSessionOption
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PSSessionOption
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specify session configuration to use for remoting, this session configuration must
be registered and enabled on remote computer.
The default value is controlled with PSSessionConfigurationName preference variable

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PSSessionConfigurationName
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimOptions

Optionally specify custom CIM session options to fine tune CIM session test.
By default new CIM options object is made and set to use SSL if protocol is HTTPS

```yaml
Type: Microsoft.Management.Infrastructure.Options.CimSessionOptions
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### [void]

### [System.Xml.XmlElement]

### [System.String]

### [System.URI]

### [System.Management.Automation.Runspaces.PSSession]

### [Microsoft.PowerShell.Commands.Internal.Format.GroupStartData]

### [Microsoft.PowerShell.Commands.Internal.Format.FormatStartData]

## NOTES

Regarding CertThumbprint problems with Test-WSMan see this issue https://github.com/PowerShell/PowerShell/issues/16752

TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: Test for private profile to avoid cryptic error message

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-WinRM.md)

[https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.authenticationmechanism](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.authenticationmechanism)

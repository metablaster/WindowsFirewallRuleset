---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Connect-Computer.md
schema: 2.0.0
---

# Connect-Computer

## SYNOPSIS

Connect to remote computer

## SYNTAX

### Protocol (Default)

```powershell
Connect-Computer [[-Domain] <String>] [-Credential <PSCredential>] [-Protocol <String>] [-Port <Int32>]
 [-Authentication <String>] [-SessionOption <PSSessionOption>] [-ConfigurationName <String>]
 [-ApplicationName <String>] [-CimOptions <CimSessionOptions>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Thumbprint

```powershell
Connect-Computer [[-Domain] <String>] [-Credential <PSCredential>] [-Port <Int32>] [-CertThumbprint <String>]
 [-Authentication <String>] [-SessionOption <PSSessionOption>] [-ConfigurationName <String>]
 [-ApplicationName <String>] [-CimOptions <CimSessionOptions>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Connect local machine to local (loopback) or remote computer onto which to deploy firewall.

The following global variables are set and objects created:
RemoteCim (CimSession), CIM session object
RemoteSession (PSSession), PS session object which represent remote session
RemoteRegistry (PSDrive), administrative share C$ to remote computer (needed for authentication)
CimServer (variable), to be used by CIM commandlets to access "RemoteCim" object for -CimSession parameter
SessionInstance (variable), to be used by Invoke-Command to access "RemoteSession" object for -Session parameter

## EXAMPLES

### EXAMPLE 1

```powershell
Connect-Computer COMPUTERNAME
```

### EXAMPLE 2

```powershell
$ConnectParams = @{
  SessionOption = $PSSessionOption
  ErrorAction = "Stop"
  Domain = "Server01"
  Protocol = "HTTP"
  ConfigurationName = $PSSessionConfigurationName
  ApplicationName = $PSSessionApplicationName
  CimOptions = New-CimSessionOption -Protocol Wsman -UICulture "en-US" -Culture "en-US"
}
PS> Connect-Computer @ConnectParams
```

## PARAMETERS

### -Domain

Computer name with which to connect for remoting

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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protocol

Specify protocol to use for connection, HTTP, HTTPS or Default.
The default value is "Default" which means HTTPS is used for connection to remote computer
and if not working fallback to HTTP, for localhost "Default" means use HTTP.

```yaml
Type: System.String
Parameter Sets: Protocol
Aliases:

Required: False
Position: Named
Default value: $RemotingProtocol
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

Optionally specify certificate thumbprint which is to be used for HTTPS.
Use this parameter when there are multiple certificates with same DNS entries.

```yaml
Type: System.String
Parameter Sets: Thumbprint
Aliases:

Required: False
Position: Named
Default value: None
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

### -ApplicationName

Specify application name use for remote connection,
Currently only "wsman" is supported.
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

### -CimOptions

Optionally specify custom CIM session options to fine tune CIM session.
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

### None. You cannot pipe objects to Connect-Computer

## OUTPUTS

### None. Connect-Computer does not generate any output

## NOTES

None.

## RELATED LINKS

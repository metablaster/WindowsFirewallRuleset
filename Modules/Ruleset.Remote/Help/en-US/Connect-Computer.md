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

```powershell
Connect-Computer [[-Domain] <String>] [-Credential <PSCredential>] [-Protocol <String>] [-Port <Int32>]
 [-CertThumbprint <String>] [-SessionOption <PSSessionOption>] [-ConfigurationName <String>]
 [-ApplicationName <String>] [-CimOptions <CimSessionOptions>] [<CommonParameters>]
```

## DESCRIPTION

Connect to remote computer onto which to deploy firewall.
This script will perform necessary initialization to enter PS session to remote computer,
in addition required authentication is made to use remote registry service and to run commands
against remote CIM server.

Following global variables or objects are created:
CimServer (variable), to be used by CIM commandlets to specify cim session to use
RemoteRegistry (PSDrive), administrative share C$ to remote computer (needed for authentication)
RemoteSession (PSSession), PS session object which represent remote session
RemoteCim (CimSession), CIM session object

## EXAMPLES

### EXAMPLE 1

```powershell
Connect-Computer COMPUTERNAME
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

Specify credentials which to use to connect to remote computer.
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

Specify protocol to use for test, HTTP, HTTPS or any.
The default value is "Any" which means HTTPS is used for connection to remote computer
and HTTP for local machine.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Any
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionOption

Specify custom PSSessionOption object to use for remoting.
The default value is controlled with PSSessionOption preference variable

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

Specify custom CIM session object to fine tune CIM sessions.
By default new blank CIM options object is made and set to use SSL if protocol is HTTPS

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Connect-Computer

## OUTPUTS

### None. Connect-Computer does not generate any output

## NOTES

TODO: When localhost or dot (.) is specified it should be treated as localhost which means localhost
requirements must be met.

## RELATED LINKS

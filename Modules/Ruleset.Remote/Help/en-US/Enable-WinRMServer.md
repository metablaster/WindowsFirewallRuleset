---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-WinRMServer.md
schema: 2.0.0
---

# Enable-WinRMServer

## SYNOPSIS

Configure WinRM server for CIM and PowerShell remoting

## SYNTAX

### Default (Default)

```powershell
Enable-WinRMServer [-Protocol <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### File

```powershell
Enable-WinRMServer [-Protocol <String>] [-CertFile <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ThumbPrint

```powershell
Enable-WinRMServer [-Protocol <String>] [-CertThumbprint <String>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Configures local machine to accept remote CIM and PowerShell requests using WS-Management.
In addition it initializes specialized remoting session configuration as well as most common
issues are handled and attempted to be resolved or bypassed automatically.

If specified -Protocol is set to HTTPS, it will export public key (DER encoded CER file)
to default repository location (\Exports), which you should then copy to client machine
to be picked up by Set-WinRMClient and used for communication over SSL.

## EXAMPLES

### EXAMPLE 1

```powershell
Enable-WinRMServer
```

Configures server machine to accept remote commands using SSL.
If there is no server certificate a new one self signed is made and put into trusted root.

### EXAMPLE 2

```powershell
Enable-WinRMServer -CertFile C:\Cert\Server2.pfx -Protocol Any
```

Configures server machine to accept remote commands using using either HTTPS or HTTP.
Client will authenticate with specified certificate for HTTPS.

### EXAMPLE 3

```powershell
Enable-WinRMServer -Protocol HTTP
```

Configures server machine to accept remoting commands trough HTTP.

## PARAMETERS

### -Protocol

Specifies listener protocol to HTTP, HTTPS or both.
By default only HTTPS is configured.

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

### -CertFile

Optionally specify custom certificate file.
By default new self signed certifcate is made and trusted if no suitable certificate exists.
This must be PFX file.

```yaml
Type: System.String
Parameter Sets: File
Aliases:

Required: False
Position: Named
Default value: None
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

### -Force

If specified, overwrites an existing exported certificate (*.cer) file,
unless it has the Read-only attribute set.

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

### None. You cannot pipe objects to Enable-WinRMServer

## OUTPUTS

### [void]

### [System.Xml.XmlElement]

### [Selected.System.Xml.XmlElement]

## NOTES

NOTE: Set-WSManQuickConfig -UseSSL will not work if certificate is self signed
TODO: How to control language?
in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Authenticate users using certificates optionally or instead of credential object
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
TODO: Configure server remotely either with WSMan or trough SSH, to test and configure server
remotely use Connect-WSMan and New-WSManSessionOption
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-WinRMServer.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-WinRMServer.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management](https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configuration_files](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configuration_files)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration)

[https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)

[winrm help config]()
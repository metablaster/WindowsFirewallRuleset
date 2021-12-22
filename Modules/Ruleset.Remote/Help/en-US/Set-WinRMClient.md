---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Set-WinRMClient.md
schema: 2.0.0
---

# Set-WinRMClient

## SYNOPSIS

Configure client computer for WinRM remoting

## SYNTAX

### Default (Default)

```powershell
Set-WinRMClient [[-Domain] <String>] [-Protocol <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### File

```powershell
Set-WinRMClient [[-Domain] <String>] [-Protocol <String>] [-CertFile <String>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CertThumbprint

```powershell
Set-WinRMClient [[-Domain] <String>] [-Protocol <String>] [-CertThumbprint <String>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Configures client machine to send CIM and PowerShell commands to remote server using WS-Management.
This functionality is most useful when setting up WinRM with SSL.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-WinRMClient -Domain Server1
```

Configures client machine to run commands remotely on computer Server1 using SSL,
by installing Server1 certificate into trusted root.

### EXAMPLE 2

```powershell
Set-WinRMClient -Domain Server2 -CertFile C:\Cert\Server2.cer
```

Configures client machine to run commands remotely on computer Server2, using SSL
by installing specified certificate file into trusted root store.

### EXAMPLE 3

```powershell
Set-WinRMClient -Domain Server3 -Protocol HTTP
```

Configures client machine to run commands remotely on computer Server3 using HTTP

## PARAMETERS

### -Domain

Computer name which is to be managed remotely from this machine.
If not specified local machine is the default.

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

Specifies protocol to HTTP, HTTPS or any.
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
By default certificate store is searched for certificate with CN entry set to value specified by
-Domain parameter.
If not found, default repository location (\Exports) is searched for DER encoded CER file.

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
Parameter Sets: CertThumbprint
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, does not prompt to set connected network adapters to private profile,
and does not prompt to temporarily disable any non connected network adapter if needed.

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

### None. You cannot pipe objects to Set-WinRMClient

## OUTPUTS

### [void]

### [System.Xml.XmlElement]

### [Selected.System.Xml.XmlElement]

## NOTES

TODO: How to control language?
in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Authenticate users using certificates optionally or instead of credential object
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Set-WinRMClient.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Set-WinRMClient.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management](https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management)

[https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)

[winrm help config]()

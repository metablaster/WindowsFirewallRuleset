---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Register-SslCertificate.md
schema: 2.0.0
---

# Register-SslCertificate

## SYNOPSIS

Register SSL certificate for CIM and PowerShell remoting

## SYNTAX

### Default (Default)

```powershell
Register-SslCertificate [-Domain <String>] -ProductType <String> [-PassThru] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### File

```powershell
Register-SslCertificate [-Domain <String>] -ProductType <String> [-CertFile <String>] [-PassThru] [-Force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Thumbprint

```powershell
Register-SslCertificate [-Domain <String>] -ProductType <String> [-CertThumbprint <String>] [-PassThru]
 [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Install SSL certificate to be used for encrypted PowerShell remoting session.
By default certificate store is searched for existing certificate that matches CN entry,
if not found, default repository location (\Exports) is searched for certificate file which must
have same name as -Domain parameter value.

Otherwise you can specify your own custom certificate file location.
The script will always attempt to export public key (DER encoded CER file) on server computer
to default repository location (\Exports), which you should then copy to client machine to be
picked up by Set-WinRMClient and used for client authentication.

## EXAMPLES

### EXAMPLE 1

```powershell
Register-SslCertificate -ProductType Server
```

Installs existing or new SSL certificate on server computer,
public key is exported to be used on client computer.

### EXAMPLE 2

```powershell
Register-SslCertificate -ProductType Client -CertFile C:\Cert\Server.cer
```

Installs specified SSL certificate on client computer.

### EXAMPLE 3

```powershell
Register-SslCertificate -ProductType Server -CertThumbprint "96158c29ab14a96892c1a5202058c6fe25f06fd7"
```

Installs existing SSL certificate with specified thumbprint on the server computer,
public key is exported to be used on client computer.

## PARAMETERS

### -Domain

Specify host name which is to be managed remotely from this machine.
This parameter is required only when setting up client computer.
For server -ProductType this defaults to server NetBios host name.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductType

Specify current system role which controls script behavior.
This is either Client (management computer) or Server (managed computer).

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

### -CertFile

Optionally specify custom certificate file.
By default new self signed certifcate is made and trusted if no suitable certificate exists.
For server -ProductType this must be PFX file, for client -ProductType it must be DER encoded CER file

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
Parameter Sets: Thumbprint
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Returns an object that represents the certificate.
By default, no output is generated.

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

If specified, overwrites an existing exported certificate file,
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

### None. You cannot pipe objects to Register-SslCertificate

## OUTPUTS

### [System.Security.Cryptography.X509Certificates.X509Certificate2]

## NOTES

This script is called by Enable-WinRMServer and doesn't need to be run on it's own.
HACK: What happens when exporting a certificate that is already installed?
(no error is shown)
TODO: This function must be simplified and certificate creation should probably be separate function

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Register-SslCertificate.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Register-SslCertificate.md)

[https://docs.microsoft.com/en-us/powershell/module/pki](https://docs.microsoft.com/en-us/powershell/module/pki)

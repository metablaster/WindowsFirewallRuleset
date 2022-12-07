---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Publish-SshKey.md
schema: 2.0.0
---

# Publish-SshKey

## SYNOPSIS

Deploy public SSH key to remote host using SSH

## SYNTAX

```powershell
Publish-SshKey [-Domain] <String> -User <String> -Key <String> [-Port <UInt32>] [-System] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Authorize this Windows machine to connect to SSH server host by uploading
public SSH key to default location on remote host and adjust required permissions.

For standard users this is ~\.ssh\authorized_keys, for administrators it's
%ProgramData%\ssh\administrators_authorized_keys

## EXAMPLES

### EXAMPLE 1

```powershell
Publish-SshKey -User ServerAdmin -Domain Server1 -System
```

### EXAMPLE 2

```powershell
Publish-SshKey -User ServerUser -Domain Server1 -Key "$HOME\.ssh\id_ecdsa.pub"
```

## PARAMETERS

### -Domain

Target computer or host name

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

### -User

The user to log in as, on the remote machine.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: UserName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key

Specify public SSH key with is to be transferred.
By default this is: $HOME\.ssh\id_ecdsa-remote-ssh.pub

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

### -Port

Specify SSH port on which the remote server is listening.
The default is port 22

```yaml
Type: System.UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 22
Accept pipeline input: False
Accept wildcard characters: False
```

### -System

If specified, the key is added to system wide configuration.
Valid only if the User parameter belongs to Administrators group on remote host.

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

Overwrite file on remote host instead of appending key to existing file

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

### None. You cannot pipe objects to Publish-SshKey

## OUTPUTS

### None. Publish-SshKey does not generate any output

## NOTES

Remote computer must install SSH server in optional features
Remote computer must have OpenSSH SSH server service running
Local computer must create a "config" file in $HOME\.ssh\
Sample config file can be found in Config\SSH

Password based authentication is needed for first time setup or
if no existing public SSH key is ready on remote host.

TODO: Optionally deploy sshd_config to remote
TODO: Make use of certificates
TODO: When specifying port for ssh.exe?
progress bar doesn't remove it's status on completion

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Publish-SshKey.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Publish-SshKey.md)

[https://code.visualstudio.com/docs/remote/troubleshooting#_configuring-key-based-authentication](https://code.visualstudio.com/docs/remote/troubleshooting#_configuring-key-based-authentication)

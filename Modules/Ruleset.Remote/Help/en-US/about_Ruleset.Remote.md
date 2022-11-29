# Ruleset.Remote

## about_Ruleset.Remote

## SHORT DESCRIPTION

Module used for remoting configuration of WinRM, CIM and remote registry

## LONG DESCRIPTION

Ruleset.Remote module provides several functions to help configure, manage and test
configuration used for remoting using WinRM (WS Management) service, remote registry
service and CIM (Common Information Model)

## EXAMPLES

```powershell
Connect-Computer
```

Connect to remote computer onto which to deploy firewall

```powershell
Disable-RemoteRegistry
```

Disable remote registry service previously enabled by Enable-RemoteRegistry

```powershell
Disable-WinRMServer
```

Disable WinRM server previously enabled by Enable-WinRMServer

```powershell
Disconnect-Computer
```

Disconnect remote computer previously connected with Connect-Computer

```powershell
Enable-RemoteRegistry
```

Enable remote users to modify registry settings on this computer

```powershell
Enable-WinRMServer
```

Configure WinRM server for CIM and PowerShell remoting

```powershell
Export-WinRM
```

Export WinRM configuration to file

```powershell
Import-WinRM
```

Import WinRM configuration from file

```powershell
Publish-SshKey
```

Deploy public SSH key to remote host using SSH

```powershell
Register-SslCertificate
```

Install SSL certificate for PowerShell and CIM remoting

```powershell
Reset-WinRM
```

Reset WinRM configuration to either system default or to previous settings

```powershell
Set-WinRMClient
```

Configure client computer for WinRM remoting

```powershell
Show-WinRMConfig
```

Show WinRM service configuration

```powershell
Test-RemoteRegistry
```

Test remote registry service

```powershell
Test-WinRM
```

Test WinRM service configuration

```powershell
Unregister-SslCertificate
```

Uninstall SSL certificate for CIM and PowerShell remoting

## KEYWORDS

- WinRM
- CIM
- Remote

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Remote/Help/en-US

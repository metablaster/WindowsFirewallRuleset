---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md
schema: 2.0.0
---

# Initialize-Service

## SYNOPSIS

Configure and start specified system services

## SYNTAX

```powershell
Initialize-Service [-Name] <String[]> [-Status <String>] [-StartupType <String>] [<CommonParameters>]
```

## DESCRIPTION

Test if required system services are started, if not all services on which target service depends
are started before starting requested service and setting it to automatic startup.
Some services are essential for correct firewall and network functioning,
without essential services running code may result in errors hard to debug

## EXAMPLES

### EXAMPLE 1

```powershell
Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")
```

Returns True if all requested services are started successfully False otherwise

### EXAMPLE 2

```powershell
Initialize-Service "WinRM"
$true if WinRM service was started $false otherwise
```

## PARAMETERS

### -Name

Enter one or more service (short) names to configure

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Status

Optionally specify service status, acceptable values are Running or Stopped

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Running
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartupType

Optionally specify service startup type, acceptable values are Automatic or Manual.
The default Automatic startup type.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Automatic
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] One or more service short names to check

## OUTPUTS

### [bool]

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: Optionally set services to automatic startup, most of services are needed only to run code.
\[System.ServiceProcess.ServiceController\[\]\]
TODO: RemoteRegistry starts on demand and stops on it's own when not used, no need to start it,
only manual trigger start is needed

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md)

[https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicecontrollerstatus](https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicecontrollerstatus)

[https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicestartmode](https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicestartmode)

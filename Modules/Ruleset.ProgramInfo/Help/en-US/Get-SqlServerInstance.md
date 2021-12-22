---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlServerInstance.md
schema: 2.0.0
---

# Get-SqlServerInstance

## SYNOPSIS

Get SQL server information from a local or remote servers

## SYNTAX

```powershell
Get-SqlServerInstance [[-Domain] <String[]>] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Retrieves SQL server information from a local or remote servers.
Pulls all
instances from a SQL server and detects if in a cluster or not.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SqlServerInstance -Domain Server01 | Select-Object *
```

Domain          : Server01
SqlInstance     : MSSQLSERVER
InstallLocation : %ProgramW6432%\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Binn
SqlPath         : %ProgramW6432%\Microsoft SQL Server\150\DTS
Version         : 15.0.2080.9
Name            : SQL Server 2019
IsCluster       : False
FullName        : Server01
IsClusterNode   : False
Edition         : Developer Edition
ClusterName     :
ClusterNodes    : {}

Domain          : Server01
SqlInstance     : MSSQLSERVER
InstallLocation : %ProgramW6432%\Microsoft SQL Server\MSSQL8.MSSQLSERVER\MSSQL\Binn
SqlPath         : %ProgramW6432%\Microsoft SQL Server\80\DTS
Version         : 10.0.1600.22
Name            : SQL Server 2008
IsCluster       : False
FullName        : Server01
IsClusterNode   : False
Edition         : Enterprise Edition
ClusterName     :
ClusterNodes    : {}

### EXAMPLE 2

```powershell
Get-SqlServerInstance -Domain Server1, Server2 -CIM
```

Domain           : Server1
SqlInstance      : MSSQLSERVER
InstallLocation  : D:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Binn
SqlPath          : D:\Program Files\Microsoft SQL Server\80\DTS
Edition          : Enterprise Edition: Core-based Licensing
Version          : 11.0.3128.0
Name             : SQL Server 2012
IsCluster        : False
IsClusterNode    : False
ClusterName      :
ClusterNodes     : {}
FullName         : Server1
ServiceName      : SQL Server (MSSQLSERVER)
ServiceState     : Running
ServiceAccount   : domain\Server1SQL
ServiceStartMode : Auto

Domain           : Server2
SqlInstance      : MSSQLSERVER
InstallLocation  : D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
SqlPath          : D:\Program Files\Microsoft SQL Server\100\DTS
Edition          : Enterprise Edition
Version          : 10.50.4000.0
Name             : SQL Server 2008 R2
IsCluster        : False
IsClusterNode    : False
ClusterName      :
ClusterNodes     : {}
FullName         : Server2
ServiceName      : SQL Server (MSSQLSERVER)
ServiceState     : Running
ServiceAccount   : domain\Server2SQL
ServiceStartMode : Auto

## PARAMETERS

### -Domain

Local or remote systems to query for SQL information.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CIM

If specified, try to pull and correlate CIM information for SQL
TODO: limited testing was performed in matching up the service info to registry info.

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

### [string[]]

## OUTPUTS

### [PSCustomObject]

## NOTES

Name: Get-SqlServer
Author: Boe Prox, edited by cookie monster (to cover wow6432node, CIM tie in)

Version History:

v1.5 Boe Prox - 31 May 2016:

- Added CIM queries for more information
- Custom object type name

v1.0 Boe Prox -  07 Sept 2013:

- Initial Version

Following modifications by metablaster based on both originals 15 Feb 2020:

- change syntax, casing, code style and function name
- resolve warnings, replacing aliases with full names
- change how function returns
- Add code to return SQL DTS Path
- separate support for 32 bit systems
- Include license into file (MIT all 3), links to original sites and add appropriate Copyright for each author/contributor
- update reported server versions
- added more verbose and debug output, path formatting.
- Replaced WMI calls with CIM calls which are more universal and cross platform

12 December 2020:

- Renamed from Get-SQLInstance to Get-SqlServerInstance because of name colision from SQLPS module

14 April 2021:

- Check returned key is not null when opening from top registry node

See links section for original and individual versions of code

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlServerInstance.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlServerInstance.md)

[https://github.com/RamblingCookieMonster/PowerShell](https://github.com/RamblingCookieMonster/PowerShell)

[https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0](https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0)

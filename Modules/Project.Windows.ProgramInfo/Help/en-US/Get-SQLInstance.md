---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-SQLInstance.md
schema: 2.0.0
---

# Get-SQLInstance

## SYNOPSIS

Retrieves SQL server information from a local or remote servers.

## SYNTAX

```none
Get-SQLInstance [[-ComputerNames] <String[]>] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Retrieves SQL server information from a local or remote servers.
Pulls all
instances from a SQL server and detects if in a cluster or not.

## EXAMPLES

### EXAMPLE 1

```none
Get-SQLInstance -Computername DC1
```

SQLInstance   : MSSQLSERVER
Version       : 10.0.1600.22
isCluster     : False
Computername  : DC1
FullName      : DC1
isClusterNode : False
Edition       : Enterprise Edition
ClusterName   :
ClusterNodes  : {}
Caption       : SQL Server 2008

SQLInstance   : MINASTIRITH
Version       : 10.0.1600.22
isCluster     : False
Computername  : DC1
FullName      : DC1\MINASTIRITH
isClusterNode : False
Edition       : Enterprise Edition
ClusterName   :
ClusterNodes  : {}
Caption       : SQL Server 2008

### EXAMPLE 2

```none
Get-SQLInstance -Computername Server1, Server2 -CIM
```

Computername     : Server1
SQLInstance      : MSSQLSERVER
SQLBinRoot       : D:\MSSQL11.MSSQLSERVER\MSSQL\Binn
Edition          : Enterprise Edition: Core-based Licensing
Version          : 11.0.3128.0
Caption          : SQL Server 2012
isCluster        : False
isClusterNode    : False
ClusterName      :
ClusterNodes     : {}
FullName         : Server1
ServiceName      : SQL Server (MSSQLSERVER)
ServiceState     : Running
ServiceAccount   : domain\Server1SQL
ServiceStartMode : Auto

Computername     : Server2
SQLInstance      : MSSQLSERVER
SQLBinRoot       : D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
Edition          : Enterprise Edition
Version          : 10.50.4000.0
Caption          : SQL Server 2008 R2
isCluster        : False
isClusterNode    : False
ClusterName      :
ClusterNodes     : {}
FullName         : Server2
ServiceName      : SQL Server (MSSQLSERVER)
ServiceState     : Running
ServiceAccount   : domain\Server2SQL
ServiceStartMode : Auto

## PARAMETERS

### -ComputerNames

Local or remote systems to query for SQL information.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Servers, Machines

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

## OUTPUTS

## NOTES

Name: Get-SQLInstance
Author: Boe Prox, edited by cookie monster (to cover wow6432node, CIM tie in)

Version History:
1.5 //Boe Prox - 31 May 2016
	- Added CIM queries for more information
	- Custom object type name
1.0 //Boe Prox -  07 Sept 2013
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
- Replaced WMI calls with CIM calls which are more universal and cross platform that WMI

Links to original and individual versions of code
https://github.com/RamblingCookieMonster/PowerShell
https://github.com/metablaster/WindowsFirewallRuleset
https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0

TODO: update examples to include DTS directory

## RELATED LINKS


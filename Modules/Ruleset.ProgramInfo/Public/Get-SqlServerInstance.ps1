
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2013, 2016 Boe Prox
Copyright (C) 2016 Warren Frame
Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Get SQL server information from a local or remote servers

.DESCRIPTION
Retrieves SQL server information from a local or remote servers. Pulls all
instances from a SQL server and detects if in a cluster or not.

.PARAMETER Domain
Local or remote systems to query for SQL information.

.PARAMETER CIM
If specified, try to pull and correlate CIM information for SQL
TODO: limited testing was performed in matching up the service info to registry info.

.EXAMPLE
PS> Get-SqlServerInstance -Domain Server01 | Select-Object *

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

.EXAMPLE
PS> Get-SqlServerInstance -Domain Server1, Server2 -CIM

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

.INPUTS
[string[]]

.OUTPUTS
[PSCustomObject]

.NOTES
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

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlServerInstance.md

.LINK
https://github.com/RamblingCookieMonster/PowerShell

.LINK
https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0
#>
function Get-SqlServerInstance
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlServerInstance.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# TODO: begin scope for all registry functions
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine

		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				"SOFTWARE\Microsoft\Microsoft SQL Server"
				"SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server")
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Microsoft SQL Server"
		}
	}

	process
	{
		foreach ($Computer in $Domain)
		{
			[PSCustomObject[]] $AllInstances = @()

			# TODO: what is this?
			$Computer = $Computer -replace '(.*?)\..+', '$1'
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

			if (!(Test-Connection -ComputerName $Computer -Count 2 -Quiet))
			{
				continue
			}

			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Computer"
				$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer, $RegistryView)
			}
			catch
			{
				Write-Error -ErrorRecord $_
				continue
			}

			foreach ($HKLMRootKey in $HKLM)
			{
				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:\$HKLMRootKey"
					$RootKey = $RemoteKey.OpenSubKey($HKLMRootKey, $RegistryPermission, $RegistryRights)

					if (!$RootKey)
					{
						throw [System.Data.ObjectNotFoundException]::new("Following registry key does not exist: HKLM:\$HKLMRootKey")
					}
				}
				catch
				{
					Write-Warning -Message "Failed to open registry root key: HKLM:\$HKLMRootKey"
					continue
				}

				[array] $Instances = $null
				if ($RootKey.GetSubKeyNames() -contains "Instance Names")
				{
					try
					{
						$KeyPath = "$HKLMRootKey\Instance Names\SQL"
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: HKLM:\$KeyPath"
						$RootKey = $RemoteKey.OpenSubKey($KeyPath, $RegistryPermission, $RegistryRights)

						if (!$RootKey)
						{
							throw [System.Data.ObjectNotFoundException]::new(
								"Following registry key does not exist: HKLM:\$KeyPath")
						}
					}
					catch
					{
						Write-Warning -Message "Failed to open registry sub key: HKLM:\$KeyPath"
					}

					if ($RootKey)
					{
						$Instances = @($RootKey.GetValueNames())
					}
				}
				elseif ($RootKey.GetValueNames() -contains "InstalledInstances")
				{
					$IsCluster = $false
					$Instances = $RootKey.GetValue("InstalledInstances")
				}
				else
				{
					continue
				}

				if ($Instances.Count -gt 0)
				{
					foreach ($Instance in $Instances)
					{
						$ClusterName = $null
						$IsCluster = $false
						$InstanceValue = $RootKey.GetValue($Instance)
						$Nodes = New-Object -TypeName System.Collections.Arraylist

						try
						{
							$KeyPath = "$HKLMRootKey\$InstanceValue"
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening InstanceReg key: HKLM:\$KeyPath"
							$InstanceReg = $RemoteKey.OpenSubKey($KeyPath, $RegistryPermission, $RegistryRights)

							if (!$InstanceReg)
							{
								throw [System.Data.ObjectNotFoundException]::new(
									"Following registry key does not exist: HKLM:\$KeyPath")
							}
						}
						catch
						{
							Write-Warning -Message "Failed to open InstanceReg key: HKLM:\$KeyPath"
							continue
						}

						if ($InstanceReg.GetSubKeyNames() -contains "Cluster")
						{
							$IsCluster = $true

							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening InstanceRegCluster sub key: Cluster"
							$InstanceRegCluster = $InstanceReg.OpenSubKey("Cluster")

							if ($InstanceRegCluster)
							{
								$ClusterName = $InstanceRegCluster.GetValue("ClusterName")
							}
							else
							{
								Write-Warning -Message "Failed to open InstanceRegCluster sub key: Cluster"
							}

							try
							{
								$KeyPath = "$HKLMRootKey\$InstanceValue\Cluster\Nodes"
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening ClusterReg key: HKLM:\$KeyPath"
								# TODO: this could probably be $InstanceReg.OpenSubKey("Cluster\Nodes") ?
								Write-Debug -Message "[$($MyInvocation.InvocationName)] TODO: Verify this is good!" -Debug
								$ClusterReg = $RemoteKey.OpenSubKey("Cluster\Nodes", $RegistryPermission, $RegistryRights)

								if (!$ClusterReg)
								{
									throw [System.Data.ObjectNotFoundException]::new(
										"Following registry key does not exist: HKLM:\$KeyPath")
								}
							}
							catch
							{
								Write-Warning -Message "Failed to open ClusterReg key: HKLM:\$KeyPath"
							}

							if ($ClusterReg)
							{
								$ClusterReg.GetSubKeyNames() | ForEach-Object {
									# TODO: check opening sub key and getting value
									$Nodes.Add($ClusterReg.OpenSubKey($_).GetValue("NodeName")) | Out-Null
								}
							}
						}

						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening InstanceRegSetup key: $HKLMRootKey\$InstanceValue\Setup"
						$InstanceRegSetup = $InstanceReg.OpenSubKey("Setup")

						if ($InstanceRegSetup)
						{
							$Edition = $InstanceRegSetup.GetValue("Edition")
							$SQLBinRoot = $InstanceRegSetup.GetValue("SQLBinRoot")

							if ([string]::IsNullOrEmpty($SQLBinRoot))
							{
								Write-Warning -Message "Failed to read registry key entry 'SQLBinRoot' for SQL Binn directory"
							}
							else
							{
								$SQLBinRoot = Format-Path $SQLBinRoot
							}
						}
						else
						{
							Write-Warning -Message "Failed to open InstanceRegSetup sub key: $HKLMRootKey\$InstanceValue\Setup"
							continue
						}

						try
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Settings ErrorActionPreference to: Stop"
							$ErrorActionPreference = "Stop"

							try
							{
								# Get from filename to determine version
								$KeyPath = "SYSTEM\CurrentControlSet\Services"
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening ServicesReg key: HKLM:\$KeyPath"
								$ServicesReg = $RemoteKey.OpenSubKey($KeyPath, $RegistryPermission, $RegistryRights)

								if (!$ServicesReg)
								{
									throw [System.Data.ObjectNotFoundException]::new(
										"Following registry key does not exist: HKLM:\$KeyPath")
								}
							}
							catch
							{
								Write-Warning -Message "Failed to open ServiceReg key: HKLM:\$KeyPath"
							}

							if ($ServicesReg)
							{
								$ServiceKey = $ServicesReg.GetSubKeyNames() | Where-Object {
									$_ -match $Instance
								} | Select-Object -First 1

								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening Service sub key: $ServiceKey"
								$Service = $ServicesReg.OpenSubKey($ServiceKey).GetValue("ImagePath")

								if ($Service)
								{
									$File = $Service -replace '^.*(\w:\\.*\\sqlservr.exe).*', '$1'
									$Version = (Get-Item ("\\$Computer\$($File -replace ":", "$")")).VersionInfo.ProductVersion
								}
								else
								{
									Write-Warning -Message "Failed to open Service sub key: $ServiceKey"
								}
							}
						}
						catch
						{
							# Use potentially less accurate version from registry
							$Version = $InstanceRegSetup.GetValue("Version")
						}
						finally
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Restoring ErrorActionPreference to Continue"
							$ErrorActionPreference = "Continue"
						}

						# Get SQL DTS Path
						$Major, $Minor, $Build, $Revision = $Version.Split(".")
						try
						{
							$KeyPath = "$HKLMRootKey\$Major$Minor"
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: HKLM:\$KeyPath"
							# TODO: this should probably be $ClusterReg.OpenSubKey("$Major$Minor") ?
							Write-Debug -Message "[$($MyInvocation.InvocationName)] TODO: Verify this is good!" -Debug
							$VersionKey = $RemoteKey.OpenSubKey($KeyPath, $RegistryPermission, $RegistryRights)

							if (!$VersionKey)
							{
								throw [System.Data.ObjectNotFoundException]::new(
									"Following registry key does not exist: HKLM:\$KeyPath")
							}
						}
						catch
						{
							Write-Warning -Message "Failed to open VersionKey sub key: HKLM:\$KeyPath"
						}

						if ($VersionKey)
						{
							if ($VersionKey.GetSubKeyNames() -contains "DTS")
							{
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening DTSKey sub key: DTS\Setup"
								$DTSKey = $VersionKey.OpenSubKey("DTS\Setup")

								if ($DTSKey)
								{
									$SQLPath = $DTSKey.GetValue("SQLPath")

									if ([string]::IsNullOrEmpty($SQLPath))
									{
										Write-Warning -Message "Failed to read registry key entry 'SQLPath' for SQL DTS Path"
									}
									else
									{
										$SQLPath = Format-Path $SQLPath
									}
								}
								else
								{
									Write-Warning -Message "Failed to open DTSKey sub key: DTS\Setup"
								}
							}
						}

						$AllInstances += [PSCustomObject]@{
							Domain = $Computer
							SqlInstance = $Instance
							InstallLocation = $SQLBinRoot
							SqlPath = $SQLPath
							Edition = $Edition
							Version = $Version

							Name = {
								switch -Regex ($Version)
								{
									# https://en.wikipedia.org/wiki/History_of_Microsoft_SQL_Server
									"^15"	{ "SQL Server 2019"; break }
									"^14"	{ "SQL Server 2017"; break }
									"^13"	{ "SQL Server 2016"; break }
									"^12"	{ "SQL Server 2014"; break }
									"^11"	{ "SQL Server 2012"; break }
									"^10\.5" { "SQL Server 2008 R2"; break }
									"^10"	{ "SQL Server 2008"; break }
									"^9"	{ "SQL Server 2005"; break }
									"^8"	{ "SQL Server 2000"; break }
									"^7"	{ "SQL Server 7.0"; break }
									default { "Unknown" }
								}
							}.InvokeReturnAsIs()

							IsCluster = $IsCluster
							IsClusterNode = ($Nodes -contains $Computer)
							ClusterName = $ClusterName
							ClusterNodes = ($Nodes -ne $Computer)

							FullName = {
								if ($Instance -eq "MSSQLSERVER")
								{
									$Computer
								}
								else
								{
									"$($Computer)\$($Instance)"
								}
							}.InvokeReturnAsIs()

							PSTypeName = "Ruleset.ProgramInfo"
						}
					} # foreach ($Instance in $Instances)
				} # $Instances.Count -gt 0
			} # foreach($HKLMRootKey in $HKLM)

			# If the CIM param was specified, get CIM info and correlate it!
			# Will not work with PowerShell core.
			if ($CIM)
			{
				[PSCustomObject[]] $AllInstancesCIM = @()

				try
				{
					# Get the CIM info we care about.
					$SQLServices = $null # TODO: what does this mean?
					$SQLServices = @(
						Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" -QueryDialect WQL -ErrorAction stop `
							-Query "SELECT DisplayName, Name, PathName, StartName, StartMode, State from win32_service where Name LIKE 'MSSQL%'" |
						# This regex matches MSSQLServer and MSSQL$*
						Where-Object { $_.Name -match "^MSSQL(Server$|\$)" } |
						Select-Object -Property DisplayName, StartName, StartMode, State, PathName
					)

					# If we pulled CIM info and it wasn't empty, correlate!
					if ($SQLServices)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM service info:`n$($SQLServices | Format-List -Property * | Out-String)"

						foreach ($Instance in $AllInstances)
						{
							$MatchingService = $SQLServices |
							Where-Object {
								# We need to format here because Instance path is formatted, while the path from CIM query isn't
								# TODO: can be improved by formatting when all is done, ie. at the end before returning.
								(Format-Path $_.PathName) -like "$($Instance.InstallLocation)*" -or $_.PathName -like "`"$($Instance.InstallLocation)*"
							} | Select-Object -First 1

							Write-Debug -Message "[$($MyInvocation.InvocationName)] Matching service info:`n$($MatchingService | Format-List -Property * | Out-String)"

							$AllInstancesCIM += $Instance | Select-Object -Property Domain,
							SqlInstance,
							InstallLocation,
							SqlPath,
							Edition,
							Version,
							Name,
							IsCluster,
							IsClusterNode,
							ClusterName,
							ClusterNodes,
							FullName,
							# TODO: Object not recognized as ProgramInfo
							PSTypeName,
							@{
								label = "ServiceName"; expression = {
									if ($MatchingService)
									{
										$MatchingService.DisplayName
									}
									else
									{
										"No CIM Match"
									}
								}
							},
							@{
								label = "ServiceState"; expression = {
									if ($MatchingService)
									{
										$MatchingService.State
									}
									else
									{
										"No CIM Match"
									}
								}
							},
							@{
								label = "ServiceAccount"; expression = {
									if ($MatchingService)
									{
										$MatchingService.StartName
									}
									else
									{
										"No CIM Match"
									}
								}
							},
							@{
								label = "ServiceStartMode"; expression = {
									if ($MatchingService)
									{
										$MatchingService.StartMode
									}
									else
									{
										"No CIM Match"
									}
								}
							}
						} # foreach($Instance in $AllInstances)
					} # if($SQLServices)
				}
				catch
				{
					Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject `
						-Message "Could not retrieve CIM info for computer $Computer, $($_.Exception.Message)"
					Write-Output $AllInstances
					continue
				}

				Write-Output $AllInstancesCIM
			} # if CIM
			else
			{
				Write-Output $AllInstances
			}

			$RemoteKey.Dispose()
		} # foreach computer
	}
}

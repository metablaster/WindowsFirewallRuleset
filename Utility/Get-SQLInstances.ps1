
<#
MIT License

Copyright (c) 2013, 2016 Boe Prox
Copyright (c) 2016 Warren Frame
Copyright (c) 2020 metablaster zebal@protonmail.ch

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


<# Links to original and individual versions of code
https://github.com/RamblingCookieMonster/PowerShell
https://github.com/metablaster/WindowsFirewallRuleset
https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0
#>

<#
.SYNOPSIS
	Retrieves SQL server information from a local or remote servers.

.DESCRIPTION
	Retrieves SQL server information from a local or remote servers. Pulls all
	instances from a SQL server and detects if in a cluster or not.

.PARAMETER Computers
	Local or remote systems to query for SQL information.

.PARAMETER WMI
	If specified, try to pull and correlate WMI information for SQL

	I've done limited testing in matching up the service info to registry info.
	Suggestions would be appreciated!

.NOTES
	Name: Get-SQLInstances
	Author: Boe Prox, edited by cookie monster (to cover wow6432node, WMI tie in)

	Version History:
	1.5 //Boe Prox - 31 May 2016
		- Added WMI queries for more information
		- Custom object type name
	1.0 //Boe Prox -  07 Sept 2013
		- Initial Version

	Modified by metablaster based on both originals 15 Feb 2020:
	- change syntax, casing, code style and function name
	- resolve warnings, replacing aliases with full names
	- change how function returns
	- separate support for 32 bit systems
	- Include license into file (MIT all 3), links to original sites and add appropriate Copyright for each author/contributor

.FUNCTIONALITY
	Computers

.EXAMPLE
	Get-SQLInstances -Computername DC1

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

	Description
	-----------
	Retrieves the SQL information from DC1

.EXAMPLE
	#Get SQL instances on servers 1 and 2, match them up with service information from WMI
	Get-SQLInstances -Computername Server1, Server2 -WMI

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
#>
function Get-SQLInstances
{
	[Cmdletbinding()]
	param (
		[parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('__Server','DNSHostName','IPAddress')]
		[string[]] $Computers = $env:COMPUTERNAME,
		[switch]$WMI
	)

	begin
	{
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
		$AllInstances = @()
		foreach ($Computer in $Computers)
		{
			$Computer = $Computer -replace '(.*?)\..+','$1'
			Write-Verbose ("Checking {0}" -f $Computer)

			if (!(Test-Connection -ComputerName $Computer -Count 2 -Quiet))
			{
				Write-Error -Category ConnectionError -TargetObject $Computer -Message "Unable to contact '$Computer'"
				continue
			}

			try
			{
				$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
			}
			catch
			{
				Write-Warning "[$Computer] $_"
                continue
			}

			foreach($HKLMKey in $HKLM)
			{
				$SubKey = $RemoteKey.OpenSubKey($HKLMKey)

				if ($SubKey.GetSubKeyNames() -contains "Instance Names")
				{
					$SubKey = $RemoteKey.OpenSubKey("$HKLMKey\Instance Names\SQL" )
					$Instances = @($SubKey.GetValueNames())
				}
				elseif ($SubKey.GetValueNames() -contains 'InstalledInstances')
				{
					$isCluster = $false
					$Instances = $SubKey.GetValue('InstalledInstances')
				}
				else
				{
					continue
				}

				if ($Instances.Count -gt 0)
				{
					foreach ($instance in $Instances)
					{
						$Nodes = New-Object System.Collections.Arraylist
						$ClusterName = $null
						$isCluster = $false
						$instanceValue = $SubKey.GetValue($instance)
						$InstanceReg = $RemoteKey.OpenSubKey("$HKLMKey\$instanceValue")

						if ($InstanceReg.GetSubKeyNames() -contains "Cluster")
						{
							$isCluster = $true
							$InstanceRegCluster = $InstanceReg.OpenSubKey('Cluster')
							$ClusterName = $InstanceRegCluster.GetValue('ClusterName')
							$ClusterReg = $RemoteKey.OpenSubKey("Cluster\Nodes")
							$ClusterReg.GetSubKeyNames() | ForEach-Object {
								$null = $Nodes.Add($ClusterReg.OpenSubKey($_).GetValue('NodeName'))
							}
						}

						$instanceRegSetup = $InstanceReg.OpenSubKey("Setup")

						try {
							$Edition = $instanceRegSetup.GetValue('Edition')
						}
						catch {
							$Edition = $null
						}

						try {
							$SQLBinRoot = $instanceRegSetup.GetValue('SQLBinRoot')
						}
						catch {
							$SQLBinRoot = $null
						}

						try
						{
							$ErrorActionPreference = 'Stop'

							# Get from filename to determine version
							$servicesReg = $RemoteKey.OpenSubKey("SYSTEM\CurrentControlSet\Services")

							$ServiceKey = $servicesReg.GetSubKeyNames() | Where-Object {
								$_ -match "$instance"
							} | Select-Object -First 1

							$Service = $servicesReg.OpenSubKey($ServiceKey).GetValue('ImagePath')
							$File = $Service -replace '^.*(\w:\\.*\\sqlservr.exe).*','$1'
							$Version = (Get-Item ("\\$Computer\$($File -replace ":","$")")).VersionInfo.ProductVersion
						}
						catch
						{
							#Use potentially less accurate version from registry
							$Version = $instanceRegSetup.GetValue('Version')
						}
						finally
						{
							$ErrorActionPreference = 'Continue'
						}

						$AllInstances += New-Object PSObject -Property @{
							Computername = $Computer
							SQLInstance = $instance
							SQLBinRoot = $SQLBinRoot
							Edition = $Edition
							Version = $Version

							Caption = {
								switch -Regex ($Version)
								{
									"^13"	{'SQL Server 2016'; break}
									"^12"	{'SQL Server 2014'; break}
									"^11"	{'SQL Server 2012'; break}
									"^10\.5"{'SQL Server 2008 R2'; break}
									"^10"	{'SQL Server 2008'; break}
									"^9"	{'SQL Server 2005'; break}
									"^8"	{'SQL Server 2000'; break}
									"^7"	{'SQL Server 7.0'; break}
									default {'Unknown'}
								}
							}.InvokeReturnAsIs()

							isCluster = $isCluster
							isClusterNode = ($Nodes -contains $Computer)
							ClusterName = $ClusterName
							ClusterNodes = ($Nodes -ne $Computer)

							FullName = {
								if ($Instance -eq 'MSSQLSERVER')
								{
									$Computer
								}
								else
								{
									"$($Computer)\$($instance)"
								}
							}.InvokeReturnAsIs()
						}
					} # foreach ($instance in $Instances)
				} # $Instances.Count -gt 0
			} # foreach($HKLMKey in $HKLM)

			#If the wmi param was specified, get wmi info and correlate it!
			if($WMI)
			{
				$AllInstancesWMI = @()

				try
				{
					#Get the WMI info we care about.
					$SQLServices = $null # TODO: what does this mean?
					$SQLServices = @(
						Get-WmiObject -ComputerName $Computer -query "select DisplayName, Name, PathName, StartName, StartMode, State from win32_service where Name LIKE 'MSSQL%'" -ErrorAction stop  |
							#This regex matches MSSQLServer and MSSQL$*
							Where-Object {$_.Name -match "^MSSQL(Server$|\$)"} |
							Select-Object DisplayName, StartName, StartMode, State, PathName
					)

					#If we pulled WMI info and it wasn't empty, correlate!
					if($SQLServices)
					{
						Write-Verbose "WMI Service info:`n$($SQLServices | Format-Table -AutoSize -Property * | Out-String)"
						foreach($Instance in $AllInstances)
						{
							$MatchingService = $SQLServices |
								Where-Object {
									$_.PathName -like "$( $Instance.SQLBinRoot )*" -or $_.PathName -like "`"$( $Instance.SQLBinRoot )*"
								} | Select-Object -First 1

							$AllInstancesWMI += $Instance | Select-Object -Property Computername,
							SQLInstance,
							SQLBinRoot,
							Edition,
							Version,
							Caption,
							isCluster,
							isClusterNode,
							ClusterName,
							ClusterNodes,
							FullName,
							@{ label = "ServiceName"; expression = {
								if($MatchingService)
								{
									$MatchingService.DisplayName
								}
								else
								{
									"No WMI Match"
								}
							}},
							@{ label = "ServiceState"; expression = {
								if($MatchingService)
								{
									$MatchingService.State
								}
								else
								{
									"No WMI Match"
								}
							}},
							@{ label = "ServiceAccount"; expression = {
								if($MatchingService)
								{
									$MatchingService.StartName
								}
								else
								{
									"No WMI Match"
								}
							}},
							@{ label = "ServiceStartMode"; expression = {
								if($MatchingService)
								{
									$MatchingService.StartMode
								}
								else
								{
									"No WMI Match"
								}
							}}
						} # foreach($Instance in $AllInstances)
					} # if($SQLServices)
				}
				catch
				{
					Write-Warning "Could not retrieve WMI info for '$Computer':`n$_"
					$AllInstances
				}

				return $AllInstancesWMI
			} # if WMI
			else
			{
				return $AllInstances
			}
		}
	}
}

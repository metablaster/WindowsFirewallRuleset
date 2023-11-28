
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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

using namespace System.ServiceProcess
using namespace System.Management.Automation.Host

<#
.SYNOPSIS
Configure and start specified system services

.DESCRIPTION
Test if required system services are started, if not all services on which target service depends
are started before starting requested service and setting it to automatic startup.
Some services are essential for correct firewall and network functioning,
without essential services running code may result in errors hard to debug

.PARAMETER Name
Enter one or more service (short) names to configure

.PARAMETER Status
Optionally specify service status, acceptable values are Running or Stopped

.PARAMETER StartupType
Optionally specify service startup type, acceptable values are Automatic or Manual.
The default Automatic startup type.

.EXAMPLE
PS> Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")

Returns $true if all requested services were started successfully and set to
Automatic startup $false otherwise

.EXAMPLE
PS> Initialize-Service "WinRM"

$true if WinRM service was started and set to automatic startup $false otherwise

.EXAMPLE
PS> Initialize-Service RemoteRegistry -Status Stopped -StartupType Manual

$true if RemoteRegistry was set to either stopped or started and set to Manual startup type

.INPUTS
[string[]] One or more service short names to check

.OUTPUTS
[bool]

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: Some services are logged as change from ex. from Manual to Manual, but that's not change,
this will happen ie. if restarting service.
TODO: Service 'Function Discovery Provider Host (fdPHost)' cannot be stopped due to the following error:
Cannot stop 'FDResPub' service on computer '.'.
This error indicates this script fails to recognize service status that is not in valid state to be configured

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicecontrollerstatus

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicestartmode

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicetype
#>
function Initialize-Service
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[string[]] $Name,

		[Parameter()]
		[ValidateSet("Running", "Stopped")]
		[string] $Status = "Running",

		[Parameter()]
		[ValidateSet("Automatic", "Manual")]
		[string] $StartupType = "Automatic"
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# User prompt default values
		[int32] $Default = 0
		[ChoiceDescription[]] $Choices = @()
		$Accept = [ChoiceDescription]::new("&Yes")
		$Deny = [ChoiceDescription]::new("&No")
		$Deny.HelpMessage = "Skip operation"
		[string] $Title = "System service not set to required state"

		# Timeout to start a service
		$ServiceTimeout = "00:00:30"

		# Log file header to use for this script
		$HeaderStack.Push("System services status change")
	}
	process
	{
		foreach ($ServiceName in $Name)
		{
			# [System.ServiceProcess.ServiceController]
			$Service = Get-Service -Name $ServiceName -ErrorAction Ignore

			if (!$Service)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Service '$ServiceName' not found, starting this service was ignored"
				continue
			}

			# Current service status and startup type
			$PreviousStatus = $Service.Status
			$PreviousStartType = $Service.StartType

			#
			# Boolean logic for possible service scenarios
			#

			# Either status or startup type is not in desired state
			$ConfigureService = ($PreviousStatus -ne $Status) -or ($PreviousStartType -ne $StartupType)
			# Startup type is OK and Service is running but desired state is stopped (stopping a service makes no sense unless it's paused)
			$SkipConfiguration = ($PreviousStartType -eq $StartupType) -and ($PreviousStatus -eq [ServiceControllerStatus]::Running)
			# If fdPHost or FDResPub are already running restart them to rule out known issues with host discovery
			$RestartFdp = (($ServiceName -eq "fdPHost") -or ($ServiceName -eq "FDResPub")) -and ($PreviousStatus -eq [ServiceControllerStatus]::Running)

			if ((!$SkipConfiguration -and $ConfigureService) -or $RestartFdp)
			{
				[string] $Question = "Configure '$($Service.DisplayName)' service now?"
				$Accept.HelpMessage = switch ($ServiceName)
				{
					"lmhosts"
					{
						"Required to manage GPO and contact computers on network using NETBIOS name resolution"
						break
					}
					"LanmanWorkstation"
					{
						"Required to manage GPO and contact computers on network using SMB protocol"
						break
					}
					"LanmanServer"
					{
						"Required to manage GPO firewall"
						break
					}
					# Function Discovery Provider host
					"fdPHost"
					{
						"Required for remote firewall administration"
						break
					}
					# Function Discovery Resource Publication
					"FDResPub"
					{
						"Required for remote firewall administration"
						break
					}
					"WinRM"
					{
						"Required for non 'Core' module compatibility, local and remote firewall administration"
						break
					}
					"RemoteRegistry"
					{
						"Required to drill registry both locally an remotely"
						break
					}
					"ssh-agent"
					{
						"Required if remote VSCode debugging trough SSH is desired"
						break
					}
					"sshd"
					{
						"Required if setting VSCode server for remote debugging trough SSH"
						break
					}
					default
					{
						"Start service and set to automatic startup"
					}
				}

				$Choices = @()
				$Choices += $Accept
				$Choices += $Deny

				# Don't prompt to restart service
				if ($RestartFdp -or ($Host.UI.PromptForChoice($Title, $Question, $Choices, $Default) -eq $Default))
				{
					# Configure dependent services first
					foreach ($Required in $Service.ServicesDependedOn)
					{
						# For dependent services show only failures
						$PreviousDependentStartType = $Required.StartType
						# [System.ServiceProcess.ServiceType]
						$ServiceType = Get-Service -Name $Required.Name | Select-Object -ExpandProperty ServiceType

						if (($PreviousDependentStartType -eq [ServiceStartMode]::Boot) -or
							($PreviousDependentStartType -eq [ServiceStartMode]::System))
						{
							# These startup types must not be modified
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring dependent service '$($Required.Name)' skipped because startup type is '$PreviousDependentStartType'"
							continue
						}
						elseif (!(($ServiceType -band [ServiceType]::Win32OwnProcess) -or ($ServiceType -band [ServiceType]::Win32ShareProcess)))
						{
							# Neither clever nor required to modify these services
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring dependent service '$($Required.Name)' skipped because service type is '$ServiceType'"
							continue
						}

						if ($PreviousDependentStartType -ne [ServiceStartMode]::Automatic)
						{
							Set-Service -Name $Required.Name -StartupType Automatic

							# Needed to get service again to get fresh stats
							if ((Get-Service -Name $Required.Name | Select-Object -ExpandProperty StartType) -ne [ServiceStartMode]::Automatic)
							{
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Setting dependent service '$($Required.Name)' to 'Automatic' failed"
							}
							else
							{
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName) ($($Required.Name))' ['$PreviousDependentStartType' -> 'Automatic']"
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting dependent service '$($Required.Name)' to Automatic succeeded"
							}
						}

						$PreviousDependentStatus = $Required.Status
						if ($PreviousDependentStatus -ne [ServiceControllerStatus]::Running)
						{
							if (($PreviousDependentStatus -eq [ServiceControllerStatus]::Paused) -or
								($PreviousDependentStatus -eq [ServiceControllerStatus]::PausePending))
							{
								$Service.Continue()
							}
							else
							{
								$Service.Start()
							}

							$Required.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)

							# Needed to get service again to get fresh stats
							if ((Get-Service -Name $Required.Name | Select-Object -ExpandProperty Status) -ne [ServiceControllerStatus]::Running)
							{
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Starting dependent service '$($Required.Name)' failed, please start manually and try again"
								$Required.Close()
								$Service.Close()

								Write-Error -Category OperationStopped -TargetObject $Required `
									-Message "Unable to proceed, failed to start dependent service"

								return $false
							}
							else
							{
								# Write log for service status change
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName) ($($Required.Name))' ['$PreviousDependentStatus' -> 'Running']"
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting dependent service '$($Required.Name)' succeeded"
							}
						}

						$Required.Close()
					} # Required Services

					# [System.ServiceProcess.ServiceType]
					$ServiceType = $Service | Select-Object -ExpandProperty ServiceType

					# Required services and startup type is checked, start requested service
					if (($PreviousStartType -eq [ServiceStartMode]::Boot) -or
						($PreviousStartType -eq [ServiceStartMode]::System))
					{
						# These startup types must not be modified
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring service '$ServiceName' skipped because startup type is '$PreviousStartType'"
						continue
					}
					elseif (!(($ServiceType -band [ServiceType]::Win32OwnProcess) -or ($ServiceType -band [ServiceType]::Win32ShareProcess)))
					{
						# Neither clever nor required to modify these services
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring service '$ServiceName' skipped because service type is '$ServiceType'"
						continue
					}

					if ($PreviousStartType -ne $StartupType)
					{
						Set-Service -Name $ServiceName -StartupType $StartupType

						# Needed to get service again to get fresh stats
						if ((Get-Service -Name $ServiceName | Select-Object -ExpandProperty StartType) -ne $StartupType)
						{
							Write-Warning -Message "[$($MyInvocation.InvocationName)] Setting service '$ServiceName' to '$StartupType' startup failed"
						}
						else
						{
							# Write log for service status change
							Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName) ($ServiceName)' ['$PreviousStartType' -> '$StartupType']"
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting '$ServiceName' service to '$StartupType' startup succeeded"
						}
					}

					# If fdPHost or FDResPub are already running there is a chance host discovery won't work,
					# this is a known issue in Windows to which solution is to restart those services
					if ($RestartFdp)
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restarting '$ServiceName' to rule out known issue resolving host"

						# Using Stop() Start() would stop dependent services
						Restart-Service -Name $ServiceName -Force
					}
					elseif ($PreviousStatus -ne $Status)
					{
						if ($Status -eq "Running")
						{
							if (($PreviousStatus -eq [ServiceControllerStatus]::Paused) -or
								($PreviousStatus -eq [ServiceControllerStatus]::PausePending))
							{
								$Service.Continue()
							}
							else
							{
								$Service.Start()
							}

							$Service.WaitForStatus($Status, $ServiceTimeout)
						}
						else
						{
							if (($PreviousStatus -eq [ServiceControllerStatus]::Paused) -or
								($PreviousStatus -eq [ServiceControllerStatus]::PausePending))
							{
								$Service.Continue()
								$Service.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
							}

							$Service.Stop()
							$Service.WaitForStatus($Status, $ServiceTimeout)
						}
					}

					# Check if setting up status of the requested service was successful, needed to get service again to get fresh stats
					if ((Get-Service -Name $ServiceName | Select-Object -ExpandProperty Status) -ne $Status)
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Setting '$ServiceName' service to '$Status' status failed, please set service status manually to '$Status' status and try again"

						$Service.Close()
						Write-Error -Category OperationStopped -TargetObject $Service `
							-Message "Unable to proceed, '$ServiceName' service was not set to requested state"

						return $false
					}
					else
					{
						# Write log for service status change
						Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName) ($ServiceName)' ['$PreviousStatus' -> 'Running']"
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting '$ServiceName' service to '$Status' status succeeded"
					}
				}
				else
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Configuring service '$($Service.DisplayName)' has been canceled by the user"
				}
			}
			else
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring '$($Service.DisplayName)' service was skipped, service already in desired state"
			}

			$Service.Close()
		} # foreach ServiceName

		return $true
	}
	end
	{
		# Restore header to default
		$HeaderStack.Pop() | Out-Null
	}
}

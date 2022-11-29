
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Enter one or more services to configure

.EXAMPLE
PS> Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")

Returns True if all requested services are started successfully False otherwise

.EXAMPLE
PS> Initialize-Service "WinRM"
$true if WinRM service was started $false otherwise

.INPUTS
[string[]] One or more service short names to check

.OUTPUTS
[bool]

.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: Optionally set services to automatic startup, most of services are needed only to run code.
[System.ServiceProcess.ServiceController[]]
TODO: RemoteRegistry starts on demand and stops on it's own when not used, no need to start it,
only manual trigger start is needed

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicecontrollerstatus

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicestartmode
#>
function Initialize-Service
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]] $Name
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
		[string] $Title = "Required system service not running"

		# Timeout to start a service
		$ServiceTimeout = "00:00:30"

		# Log file header to use for this script
		$HeaderStack.Push("System services status change")
	}
	process
	{
		foreach ($InputService in $Name)
		{
			# [System.ServiceProcess.ServiceController]
			$Service = Get-Service -Name $InputService -ErrorAction Ignore

			if (!$Service)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Service '$InputService' not found, starting this service was ignored"
				continue
			}

			$ServiceOldStatus = $Service.Status
			if ($ServiceOldStatus -ne [ServiceControllerStatus]::Running)
			{
				[string] $Question = "Start $($Service.DisplayName) service now?"
				$Accept.HelpMessage = switch ($Service.Name)
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
						"Required to drill registry on remote computers"
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

				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -ne $Default)
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Starting service has been canceled by the user"
				}
				else
				{
					# Configure dependent services first
					# TODO: This will also return non service objects, such as drivers which cant be configured
					foreach ($Required in $Service.ServicesDependedOn)
					{
						# For dependent services show only failures
						$PreviousStatus = $Required.StartType
						if ($PreviousStatus -ne [ServiceStartMode]::Automatic)
						{
							Set-Service -Name $Required.Name -StartupType Automatic

							if ($Required.StartType -ne [ServiceStartMode]::Automatic)
							{
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Set dependent service '$($Required.Name)' to Automatic failed"
							}
							else
							{
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName)' ($($Required.Name)) $PreviousStatus -> Automatic"
								Write-Information -Tags $MyInvocation.InvocationName `
									-MessageData "INFO: Set dependent service '$($Required.Name)' to Automatic succeeded"
							}
						}

						$PreviousStatus = $Required.Status
						if ($PreviousStatus -ne [ServiceControllerStatus]::Running)
						{
							$Required.Start()
							$Required.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)

							if ($Required.Status -ne [ServiceControllerStatus]::Running)
							{
								Write-Error -Category OperationStopped -TargetObject $Required `
									-Message "Unable to proceed, dependent services can't be started"
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Start dependent service '$($Required.Name)' failed, please start manually and try again"
								return $false
							}
							else
							{
								# Write log for service status change
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName)' ($($Required.Name)) $PreviousStatus -> Running"
								Write-Information -Tags $MyInvocation.InvocationName `
									-MessageData "INFO: Start dependent service '$($Required.Name)' succeeded"
							}
						}

						$Required.Close()
					} # Required Services

					# If decision is no, or if service is running there is no need to modify startup
					# type, otherwise set startup type after requirements are met
					$PreviousStatus = $Service.StartType
					if ($PreviousStatus -ne [ServiceStartMode]::Automatic)
					{
						Set-Service -Name $Service.Name -StartupType Automatic

						if ($Service.StartType -ne [ServiceStartMode]::Automatic)
						{
							Write-Warning -Message "[$($MyInvocation.InvocationName)] Set service '$($Service.Name)' to Automatic failed"
						}
						else
						{
							# Write log for service status change
							Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName)' ($($Service.Name)) $PreviousStatus -> Automatic"
							Write-Information -Tags $MyInvocation.InvocationName `
								-MessageData "INFO: Set '$($Service.Name)' service to Automatic succeeded"
						}
					}

					# If fdPHost or FDResPub are already running there is a chance host discovery won't work,
					# this is a known issue in Windows to which solution is to restart those services
					if ((($Service.Name -eq "fdPHost") -or ($Service.Name -eq "FDResPub")) -and ($ServiceOldStatus -eq [ServiceControllerStatus]::Running))
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restarting '$($Service.Name)' to rule out known issue resolving remote host"

						$Service.Stop()
						$Service.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)

						$Service.Start()
						$Service.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
					}
					else
					{
						# Required services and startup type is checked, start service
						$Service.Start()
						$Service.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
					}

					if ($Service.Status -ne [ServiceControllerStatus]::Running)
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Starting '$($Service.Name)' service failed, please start manually and try again"
					}
					else
					{
						# Write log for service status change
						Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName)' ($($Service.Name)) $ServiceOldStatus -> Running"
						Write-Information -Tags $MyInvocation.InvocationName `
							-MessageData "INFO: Starting '$($Service.Name)' service succeeded"
					}
				}

				if ($Service.Status -ne [ServiceControllerStatus]::Running)
				{
					Write-Error -Category OperationStopped -TargetObject $Service `
						-Message "Unable to proceed, required services are not started"
					return $false
				}
			} # if service not running

			$Service.Close()
		} # foreach InputService

		return $true
	}
	end
	{
		# Restore header to default
		$HeaderStack.Pop() | Out-Null
	}
}

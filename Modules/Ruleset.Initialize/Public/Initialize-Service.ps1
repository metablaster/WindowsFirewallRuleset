
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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

using namespace System.Management.Automation.Host

<#
.SYNOPSIS
Configure and start specified system services

.DESCRIPTION
Test if required system services are started, if not all services on which target service depends
are started before starting requested service and setting it to automatic startup.
Some services are essential for correct firewall and network functioning,
without essential services project code may result in errors hard to debug

.PARAMETER Name
Enter one or more services to configure

.EXAMPLE
PS> Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")
$true if all input services are started successfully $false otherwise

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
#>
function Initialize-Service
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Initialize-Service.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]] $Name
	)

	begin
	{
		# User prompt default values
		[int32] $Default = 0
		[ChoiceDescription[]] $Choices = @()
		$Accept = [ChoiceDescription]::new("&Yes")
		$Deny = [ChoiceDescription]::new("&No")
		$Deny.HelpMessage = "Skip operation"
		[string] $Title = "Required service not running"
		[bool] $StatusGood = $true

		# Log file header to use for this script
		$HeaderStack.Push("System services status change")
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($InputService in $Name)
		{
			$StatusGood = $true
			$Service = Get-Service -Name $InputService

			$ServiceOldStatus = $Service.Status
			if ($ServiceOldStatus -ne "Running")
			{
				[string] $Question = "Do you want to start $($Service.DisplayName) service now?"
				$Accept.HelpMessage = switch ($Service.Name)
				{
					"lmhosts"
					{
						"Required to manage GPO and contact computers on network using NETBIOS name resolution"
					}
					"LanmanWorkstation"
					{
						"Required to manage GPO and contact computers on network using SMB protocol"
					}
					"LanmanServer"
					{
						"Required to manage GPO firewall"
					}
					"WinRM"
					{
						"Required for non 'Core' module compatibility and remote firewall administration"
					}
					default
					{
						"Start service and set to automatic start"
					}
				}

				$Choices = @()
				$Choices += $Accept
				$Choices += $Deny

				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					# Configure required services first
					$RequiredServices = Get-Service -Name $Service.Name -RequiredServices

					foreach ($Required in $RequiredServices)
					{
						# For dependent services show only failures
						$OldStatus = $Required.StartType
						if ($Required.StartType -ne "Automatic")
						{
							Set-Service -Name $Required.Name -StartupType Automatic

							$Startup = Get-Service -Name $Required.Name | Select-Object -ExpandProperty StartType

							if ($Startup -ne "Automatic")
							{
								Write-Warning -Message "Set dependent service '$($Required.Name)' to Automatic failed"
							}
							else
							{
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName)' ($($Required.Name)) $OldStatus -> Automatic"
								Write-Information -Tags "Project" -MessageData "INFO: Set dependent service '$($Required.Name)' to Automatic succeeded"
							}
						}

						$OldStatus = $Required.Status
						if ($OldStatus -ne "Running")
						{
							Start-Service -Name $Required.Name
							$Status = Get-Service -Name $Required.Name | Select-Object -ExpandProperty Status

							if ($Status -ne "Running")
							{
								Write-Error -Category OperationStopped -TargetObject $Required `
									-Message "Unable to proceed, Dependent services can't be started"
								Write-Warning -Message "Start dependent service '$($Required.Name)' failed, please start manually and try again"
								return $false
							}
							else
							{
								# Write log for service status change
								Write-LogFile -LogName "Services" -Message "'$($Required.DisplayName)' ($($Required.Name)) $OldStatus -> Running"
								Write-Information -Tags "Project" -MessageData "INFO: Start dependent service '$($Required.Name)' succeeded"
							}
						}
					} # Required Services

					# If decision is no, or if service is running there is no need to modify startup type
					# Otherwise set startup type after requirements are met
					$OldStatus = $Service.StartType
					if ($OldStatus -ne "Automatic")
					{
						Set-Service -Name $Service.Name -StartupType Automatic
						$Startup = Get-Service -Name $Service.Name | Select-Object -ExpandProperty StartType

						if ($Startup -ne "Automatic")
						{
							Write-Warning -Message "Set service '$($Service.Name)' to Automatic failed"
						}
						else
						{
							# Write log for service status change
							Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName)' ($($Service.Name)) $OldStatus -> Automatic"
							Write-Information -Tags "Project" -MessageData "INFO: Set '$($Service.Name)' service to Automatic succeeded"
						}
					}

					# Required services and startup is checked, start input service
					# Status was already checked
					Start-Service -Name $Service.Name
					$Status = Get-Service -Name $Service.Name | Select-Object -ExpandProperty Status

					if ($Status -ne "Running")
					{
						$StatusGood = $false
						Write-Warning -Message "Start '$($Service.Name)' service failed, please start manually and try again"
					}
					else
					{
						# Write log for service status change
						Write-LogFile -LogName "Services" -Message "'$($Service.DisplayName)' ($($Service.Name)) $ServiceOldStatus -> Running"
						Write-Information -Tags "Project" -MessageData "INFO: Start '$($Service.Name)' service succeeded"
					}
				}
				else
				{
					# User refused default action
					$StatusGood = $false
				}

				if (!$StatusGood)
				{
					Write-Error -Category OperationStopped -TargetObject $Service `
						-Message "Unable to proceed, required services are not started"
					return $false
				}
			} # if service not running
		} # foreach InputService

		return $true
	}
	end
	{
		# Restore header to default
		$HeaderStack.Pop() | Out-Null
	}
}

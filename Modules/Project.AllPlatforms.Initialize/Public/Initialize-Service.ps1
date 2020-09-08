
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Check if required system services are started
.DESCRIPTION
Test if required system services are started, if not all services on which target service depends
are started before starting requested service and setting it to automatic startup.
Some services are essential for correct firewall and network functioning,
without essential services project code may result in errors hard to debug
.PARAMETER Services
An array of services to start
.EXAMPLE
PS> Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")
$true if all input services are started successfully $false otherwise
.EXAMPLE
PS> Initialize-Service "WinRM"
$true if WinRM service was started $false otherwise
.INPUTS
[string[]] One or more service short names to check
.OUTPUTS
None.
.NOTES
This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

[System.ServiceProcess.ServiceController[]]
#>
function Initialize-Service
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Initialize/Help/en-US/Initialize-Service.md")]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]] $Services
	)

	begin
	{
		# User prompt default values
		[int32] $Default = 0
		[System.Management.Automation.Host.ChoiceDescription[]] $Choices = @()
		$Accept = [System.Management.Automation.Host.ChoiceDescription]::new("&Yes")
		$Deny = [System.Management.Automation.Host.ChoiceDescription]::new("&No")
		$Deny.HelpMessage = "Skip operation"
		[string] $Title = "Required service not running"
		[bool] $StatusGood = $true
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($InputService in $Services)
		{
			$StatusGood = $true
			$Service = Get-Service -Name $InputService

			if ($Service.Status -ne "Running")
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
						"Required for remote firewall administration"
					}
					default
					{
						"Start service and set to automatic start"
					}
				}

				$Choices.Clear()
				$Choices += $Accept
				$Choices += $Deny

				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					$RequiredServices = Get-Service -Name $Service.Name -RequiredServices

					foreach ($Required in $RequiredServices)
					{
						# For dependent services print only failures
						if ($Required.StartType -ne "Automatic")
						{
							Set-Service -Name $Required.Name -StartupType Automatic
							$Startup = Get-Service -Name $Required.Name | Select-Object -ExpandProperty StartupType

							if ($Startup -ne "Automatic")
							{
								Write-Warning -Message "Dependent service $($Required.DisplayName) set to automatic failed"
							}
							else
							{
								Write-Verbose -Message "Setting dependent $($Required.DisplayName) service to autostart succeeded"
							}
						}

						if ($Required.Status -ne "Running")
						{
							Start-Service -Name $Required.Name
							$Status = Get-Service -Name $Required.Name | Select-Object -ExpandProperty Status

							if ($Status -ne "Running")
							{
								Write-Error -Category OperationStopped -TargetObject $Required `
									-Message "Unable to proceed, Dependent services can't be started"
								Write-Information -Tags "User" -MessageData "INFO: Starting dependent service '$($Required.DisplayName)' failed, please start manually and try again"
								return $false
							}
							else
							{
								Write-Verbose -Message "Starting dependent $($Required.DisplayName) service succeeded"
							}
						}
					} # Required Services

					# If decision is no, or if service is running there is no need to modify startup type
					# Otherwise set startup type after requirements are met
					if ($Service.StartType -ne "Automatic")
					{
						Set-Service -Name $Service.Name -StartupType Automatic
						$Startup = Get-Service -Name $Service.Name | Select-Object -ExpandProperty StartupType

						if ($Startup -ne "Automatic")
						{
							Write-Warning -Message "Set service $($Service.DisplayName) to automatic failed"
						}
						else
						{
							Write-Verbose -Message "Setting $($Service.DisplayName) service to autostart succeeded"
						}
					}

					# Required services and startup is checked, start input service
					# Status was already checked
					Start-Service -Name $Service.Name
					$Status = Get-Service -Name $Service.Name | Select-Object -ExpandProperty Status

					if ($Status -eq "Running")
					{
						Write-Information -Tags "User" -MessageData "INFO: Starting $($Service.DisplayName) service succeeded"
					}
					else
					{
						$StatusGood = $false
						Write-Information -Tags "User" -MessageData "INFO: Starting $($Service.DisplayName) service failed, please start manually and try again"
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
}

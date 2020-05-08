
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}
else
{
	# Everything is default except InformationPreference should be enabled
	$InformationPreference = "Continue"
}

<#
.SYNOPSIS
Test and print system requirements required for this project
.DESCRIPTION
Test-SystemRequirements is designed for WindowsFirewallRuleset, it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, NET Framework version and it
check if required system services are started. If not the function will exit executing scripts.
.PARAMETER Check
true or false to check or not to check
.EXAMPLE
Test-SystemRequirements $true
.INPUTS
None. You cannot pipe objects to Test-SystemRequirements
.OUTPUTS
None. Error message is shown if check failed, system info otherwise.
.NOTES
TODO: learn required NET version by scanning scripts (ie. adding .COMPONENT to comments)
TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
#>
function Test-SystemRequirements
{
	[OutputType([System.Void])]
	param (
		[Parameter(Mandatory = $false)]
		[bool] $Check = $SystemCheck
	)

	# disabled when running scripts from SetupFirewall.ps1 script
	if ($Check)
	{
		# print info
		Write-Output ""
		Write-Output "Windows Firewall Ruleset v0.3.0"
		Write-Output "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"
		Write-Output "https://github.com/metablaster/WindowsFirewallRuleset"
		Write-Output ""

		# Check operating system
		$OSPlatform = [System.Environment]::OSVersion.Platform
		$OSMajor = [System.Environment]::OSVersion.Version.Major
		$OSMinor = [System.Environment]::OSVersion.Version.Minor

		if (!($OSPlatform -eq "Win32NT" -and $OSMajor -ge 10))
		{
			Write-Error -Category OperationStopped -TargetObject $OSPlatform `
				-Message "Unable to proceed, minimum required operating system is Win32NT 10.0 to run these scripts"

			Write-Information -Tags "Project" -MessageData "Your operating system is: $OSPlatform $OSMajor.$OSMinor"
			exit
		}

		# Check if in elevated PowerShell
		$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		$local:StatusGood = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

		if (!$StatusGood)
		{
			Write-Error -Category PermissionDenied -TargetObject $Principal `
				-Message "Unable to proceed, please open PowerShell as Administrator"

			exit
		}

		# Check OS is not Home edition
		$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

		if ($OSEdition -like "*Home*")
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, home editions of Windows do not have Local Group Policy"

			exit
		}

		# Check PowerShell edition
		$PowerShellEdition = $PSVersionTable.PSEdition

		if ($PowerShellEdition -eq "Core")
		{
			Write-Warning -Message "Project with 'Core' edition of PowerShell does not yet support remote machines"
			Write-Information -Tags "Project" -MessageData "Your PowerShell edition is: $PowerShellEdition"
		}

		# Check PowerShell version
		$PowerShellMajor = $PSVersionTable.PSVersion | Select-Object -ExpandProperty Major
		$PowerShellMinor = $PSVersionTable.PSVersion | Select-Object -ExpandProperty Minor

		switch ($PowerShellMajor)
		{
			1 { $StatusGood = $false }
			2 { $StatusGood = $false }
			3 { $StatusGood = $false }
			4 { $StatusGood = $false }
			5
			{
				if ($PowerShellMinor -lt 1)
				{
					$StatusGood = $false
				}
			}
		}

		if (!$StatusGood)
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, minimum required PowerShell required to run these scripts is: Desktop 5.1"

			Write-Information -Tags "Project" -MessageData "Your PowerShell version is: $PowerShellEdition $PowerShellMajor.$PowerShellMinor"

			exit
		}

		# NOTE: this check is not required unless in some special cases
		if ($Develop -and $PowerShellEdition -eq "Desktop")
		{
			# Now that OS and PowerShell is OK we can import these modules
			Import-Module -Name $PSScriptRoot\..\Project.Windows.ProgramInfo
			Import-Module -Name $PSScriptRoot\..\Project.Windows.ComputerInfo

			# Check NET Framework version
			# TODO: What if function fails?
			$NETFramework = Get-NetFramework (Get-ComputerName)
			$Version = $NETFramework |
			Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

			[int] $NETMajor, [int] $NETMinor, $NETBuild, $NETRevision = $Version.Split(".")

			switch ($NETMajor)
			{
				1 { $StatusGood = $false }
				2 { $StatusGood = $false }
				3
				{
					if ($NETMinor -lt 5)
					{
						$StatusGood = $false
					}
				}
			}

			if (!$StatusGood)
			{
				Write-Error -Category OperationStopped -TargetObject $Version `
					-Message "Unable to proceed, minimum required NET Framework version to run these scripts is 3.5"
				Write-Information -Tags "Project" -MessageData "Your NET Framework version is: $NETMajor.$NETMinor"
				exit
			}
		}

		# Check required services are started
		$LMHosts = Get-Service -Name lmhosts | Select-Object -ExpandProperty Status
		$WinRM = Get-Service -Name WinRM | Select-Object -ExpandProperty Status
		$Workstation = Get-Service -Name LanmanWorkstation | Select-Object -ExpandProperty Status
		$Server = Get-Service -Name LanmanServer | Select-Object -ExpandProperty Status

		$Choices = "&Yes", "&No"
		$Default = 0
		$Question = "Do you want to start these services now?"

		if ($LMHosts -ne "Running")
		{
			$Title = "TCP/IP NetBIOS Helper service is required but not started"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Start-Service -Name lmhosts
				$LMHosts = Get-Service -Name lmhosts | Select-Object -ExpandProperty Status

				if ($LMHosts -ne "Running")
				{
					$StatusGood = $false
					Write-Output "lmhosts service can not be started, please start it manually and try again."
				}
			}
			else
			{
				$StatusGood = $false
			}
		}

		if (!$StatusGood)
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, required services are not started"

			Write-Information -Tags "Project" -MessageData "TCP/IP NetBIOS Helper service is required but not started"
			exit
		}

		if ($Workstation -ne "Running")
		{
			$Title = "LanmanWorkstation service is required but not started"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Start-Service -Name LanmanWorkstation
				$Workstation = Get-Service -Name LanmanWorkstation | Select-Object -ExpandProperty Status

				if ($Workstation -ne "Running")
				{
					$StatusGood = $false
					Write-Output "LanmanWorkstation service can not be started, please start it manually and try again."
				}
			}
			else
			{
				$StatusGood = $false
			}
		}

		if (!$StatusGood)
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, required services are not started"

			Write-Information -Tags "Project" -MessageData "Workstation service is required but not started"
			exit
		}

		if ($Server -ne "Running")
		{
			$Title = "LanmanServer service is required but not started"
			$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

			if ($Decision -eq $Default)
			{
				Start-Service -Name LanmanServer
				$Server = Get-Service -Name LanmanServer | Select-Object -ExpandProperty Status

				if ($Server -ne "Running")
				{
					$StatusGood = $false
					Write-Output "LanmanServer service can not be started, please start it manually and try again."
				}
			}
			else
			{
				$StatusGood = $false
			}
		}

		if (!$StatusGood)
		{
			Write-Error -Category OperationStopped -TargetObject $OSEdition `
				-Message "Unable to proceed, required services are not started"

			Write-Information -Tags "Project" -MessageData "Server service is required but not started"
			exit
		}

		if ($Develop)
		{
			# NOTE: remote machines need this service, see Enable-PSRemoting cmdlet
			if ($WinRM -ne "Running")
			{
				$Title = "Windows Remote Management service is required but not started"
				$Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, $Default)

				if ($Decision -eq $Default)
				{
					Start-Service -Name WinRM
					$WinRM = Get-Service -Name WinRM | Select-Object -ExpandProperty Status

					if ($WinRM -ne "Running")
					{
						$StatusGood = $false
						Write-Output "WinRM service can not be started, please start it manually and try again."
					}
				}
				else
				{
					$StatusGood = $false
				}
			}

			if (!$StatusGood)
			{
				Write-Error -Category OperationStopped -TargetObject $OSEdition `
					-Message "Unable to proceed, required services are not started"

				Write-Information -Tags "Project" -MessageData "Windows Remote Management service is required but not started"
				exit
			}
		}

		# Check required modules are loaded or present in modules directory
		$Pester = Get-Module -Name Pester -ListAvailable | Select-Object -ExpandProperty Version
		if (!$Pester)
		{
			$StatusGood = $false
		}
		elseif (($Pester | Measure-Object).Count -gt 1)
		{
			$Version = ($Pester | Sort-Object -Descending)[0]
			$StatusGood = $Version.Major -ge 4
		}
		else
		{
			$StatusGood = $Pester.Major -ge 4
		}

		if (!$StatusGood)
		{
			Write-Warning -Message "Pester module version 4.x is required to run some of the tests"
		}

		# Everything OK, print environment status
		Write-Output ""
		Write-Output "System:`t`t $OSPlatform v$OSMajor.$OSMinor"
		Write-Output "PowerShell:`t $PowerShellEdition v$PowerShellMajor.$PowerShellMinor"
		Write-Output ""
	}
}

#
# Function exports
#

Export-ModuleMember -Function Test-SystemRequirements

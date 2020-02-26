
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

	Set-Variable ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

<#
.SYNOPSIS
Test and print system requirements required for this project
.PARAMETER Check
true or false to check or not to check
.EXAMPLE
Test-SystemRequirements $true
.INPUTS
None. You cannot pipe objects to Test-SystemRequirements
.OUTPUTS
error message and abort if check failed, system info otherwise
.NOTES
TODO: learn required NET version by scaning scripts (ie. adding .COMPONENT to comments)
TODO: learn repo dir automaticaly (using git?)
TODO: check required modules (pester)
#>
function Test-SystemRequirements
{
	param (
		# TODO: change bool parameters to switch where possible
		[Parameter(Mandatory = $false)]
		[bool] $Check = $SystemCheck
	)

	# disabled when runing scripts from SetupFirewall.ps1 script
	if ($Check)
	{
		# print info
		Write-Host ""
		Write-Host "Windows Firewall Ruleset v0.3"
		Write-Host "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"
		Write-Host "https://github.com/metablaster/WindowsFirewallRuleset"
		Write-Host ""

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
		$Principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
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

		if ($PowerShellEdition -eq "Desktop")
		{
			Write-Warning -Message "'Desktop' edition of PowerShell should work but not quaranted"
			Write-Information -Tags "Project" -MessageData "Your PowerShell edition is: $PowerShellEdition"
		}
		elseif ($PowerShellEdition -eq "Core")
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
			5 {
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

		if ($PowerShellEdition -eq "Desktop")
		{
			# Now that OS and PowerShell is OK we can import these modules
			Import-Module -Name $PSScriptRoot\..\Project.Windows.ProgramInfo
			Import-Module -Name $PSScriptRoot\..\Project.Windows.ComputerInfo

			# Check NET Framework version
			# TODO: What if function fails?
			$NETFramework = Get-NetFramework (Get-ComputerName)
			$Version = $NETFramework | Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version
			[int] $NETMajor, [int] $NETMinor, $NETBuild, $NETRevision = $Version.Split(".")

			switch ($NETMajor)
			{
				1 { $StatusGood = $false }
				2 { $StatusGood = $false }
				3 {
					if ($NETMinor -lt 5)
					{
						$StatusGood = $false
					}
				}
			}

			if (!$StatusGood)
			{
				Write-Error -Category OperationStopped -TargetObject $Version `
				-Message "Unable to proceed, minimum requried NET Framework version to run these scripts is 3.5"
				Write-Information -Tags "Project" -MessageData "Your NET Framework version is: $NETMajor.$NETMinor"
				exit
			}
		}

		# Check required services are started
		$LMHosts = Get-Service -Name lmhosts | Select-Object -ExpandProperty Status
		$WinRM = Get-Service -Name WinRM | Select-Object -ExpandProperty Status

		$Choices  = "&Yes", "&No"
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
					Write-Host "lmhosts service can not be started, please start it manually and try again."
				}
			}
			else
			{
				$StatusGood = $false
			}
		}

		# If status is not good there is no point to continue
		if ($StatusGood -and $WinRM -ne "Running")
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
					Write-Host "WinRM service can not be started, please start it manually and try again."
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

		# Everything OK, print environment status
		Write-Host ""
		Write-Host "System:`t`t $OSPlatform v$OSMajor.$OSMinor" -ForegroundColor Cyan
		Write-Host "PowerShell:`t $PowerShellEdition v$PowerShellMajor.$PowerShellMinor" -ForegroundColor Cyan
		Write-Host ""
	}
}

#
# Function exports
#

Export-ModuleMember -Function Test-SystemRequirements

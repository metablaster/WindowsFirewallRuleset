
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Get user groups on target computers

.DESCRIPTION
Get a list of all available user groups on target computers

.PARAMETER ComputerNames
One or more computers which to query for user groups

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-UserGroup "ServerPC"

.EXAMPLE
PS> Get-UserGroup @(DESKTOP, LAPTOP) -CIM

.INPUTS
[string[]] One or more computer names

.OUTPUTS
[PSCustomObject] User groups on target computers

.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
#>
function Get-UserGroup
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-UserGroup.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(Position = 0)]
		[string[]] $ComputerNames = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		[PSCustomObject[]] $UserGroups = @()
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Computer in $ComputerNames)
		{
			if ($CIM)
			{
				# TODO: should work on windows, see Get-SqlServerInstance
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $Computer `
						-Message "Querying computers from CIM server for PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

				# Core: -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetComputer $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					$RemoteGroups = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" `
						-OperationTimeoutSec $ConnectionTimeout -ComputerName $Computer |
					Where-Object -Property LocalAccount -EQ "True"

					foreach ($Group in $RemoteGroups)
					{
						$UserGroups += [PSCustomObject]@{
							Group = $Group.Name
							Caption = $Group.Caption
							Computer = $Computer
							SID = $Group.SID
						}
					}

					if ([string]::IsNullOrEmpty($UserGroups))
					{
						Write-Warning -Message "There are no user groups on computer: $Computer"
						continue
					}
				}
			} # if ($CIM)
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				# Querying local machine
				$LocalGroups = Get-LocalGroup
				foreach ($Group in $LocalGroups)
				{
					$UserGroups += [PSCustomObject]@{
						Group = $Group.Name
						Caption = Join-Path -Path $Computer -ChildPath $Group.Name
						Computer = $Computer
						SID = $Group.SID
					}
				}

				if ([string]::IsNullOrEmpty($UserGroups))
				{
					Write-Warning -Message "There are no user groups on computer: $Computer"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Computer `
					-Message "Querying remote computers without CIM switch not implemented"
			} # if ($CIM)
		} # foreach ($Computer in $ComputerNames)

		Write-Output $UserGroups
	} # process
}

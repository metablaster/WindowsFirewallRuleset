
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
Get SID of user groups for given computer

.DESCRIPTION
Get SID's for single or multiple user groups on a target computer

.PARAMETER UserGroups
Array of user groups or single group name

.PARAMETER ComputerName
Computer name which to query for group users

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-GroupSID "USERNAME" -Machine "COMPUTERNAME"

.EXAMPLE
PS> Get-GroupSID @("USERNAME1", "USERNAME2") -CIM

.INPUTS
[string[]] One or more group names

.OUTPUTS
[string] SID's (security identifiers)

.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: plural parameter
#>
function Get-GroupSID
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupSID.md")]
	[OutputType([string])]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string[]] $UserGroups,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Group in $UserGroups)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $ComputerName\$Group"

			if ($CIM)
			{
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $ComputerName `
						-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

				if (Test-TargetComputer $ComputerName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $ComputerName"

					$GroupSID = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -EQ $Group | Select-Object -ExpandProperty SID
				}
				else
				{
					continue
				}
			}
			elseif ($ComputerName -eq [System.Environment]::MachineName)
			{
				$GroupSID = Get-LocalGroup -Name $Group |
				Select-Object -ExpandProperty SID |
				Select-Object -ExpandProperty Value
			}
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
					-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($GroupSID))
			{
				Write-Error -TargetObject $Group -Message "User group '$Group' cannot be resolved to a SID."
			}
			else
			{
				Write-Output -InputObject $GroupSID
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

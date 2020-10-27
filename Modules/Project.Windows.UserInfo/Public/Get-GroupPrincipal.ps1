
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
Get computer accounts for a given user groups on given computers
.PARAMETER UserGroups
User group on local or remote computer
.PARAMETER ComputerNames
One or more computers which to query for group users
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
PS> Get-GroupPrincipal "Users", "Administrators"
.EXAMPLE
PS> Get-GroupPrincipal "Users" -Machine @(DESKTOP, LAPTOP) -CIM
.INPUTS
[string[]] User groups
.OUTPUTS
[PSCustomObject[]] Array of enabled user accounts in specified group
.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: Switch is needed to list all accounts instead of only enabled
TODO: should we handle NT AUTHORITY, BUILTIN and similar?
TODO: plural parameter
#>
function Get-GroupPrincipal
{
	[OutputType([PSCustomObject[]])]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.UserInfo/Help/en-US/Get-GroupPrincipal.md")]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true,
			Position = 0,
			ValueFromPipeline = $true)]
		[string[]] $UserGroups,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string[]] $ComputerNames = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		[PSCustomObject[]] $UserAccounts = @()
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Computer in $ComputerNames)
		{
			if ($CIM)
			{
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $Computer `
						-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

				# Core: -TargetName $Computer -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetComputer $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					foreach ($Group in $UserGroups)
					{
						# Get all users that belong to requested group,
						# this includes non local principal source and non 'user' users
						# it is also missing SID
						$GroupUsers = Get-CimInstance -Class Win32_GroupUser -Namespace "root\cimv2" -ComputerName $Computer |
						Where-Object { $_.GroupComponent.Name -eq $Group } |
						Select-Object -ExpandProperty PartComponent |
						Select-Object -ExpandProperty Name

						# Get only enabled users, these include SID but also non group users
						$EnabledAccounts = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $Computer -Filter "LocalAccount = True" |
						Where-Object -Property Disabled -NE False |
						Select-Object -Property Name, Caption, SID, Domain

						if ([string]::IsNullOrEmpty($EnabledAccounts))
						{
							Write-Warning -Message "User group '$Group' does not have any accounts on computer: $Computer"
							continue
						}

						# Finally compare these 2 results and assemble group users which are active, also includes SID
						foreach ($Account in $EnabledAccounts)
						{
							if ($GroupUsers -contains $Account.Name)
							{
								Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $Account"

								$UserAccounts += [PSCustomObject]@{
									User = $Account.Name
									Account = $Account.Caption
									Computer = $Computer
									SID = $Account.SID
								}
							}
							else
							{
								Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring account: $Account"
							}
						}
					}
				}
			} # if ($CIM)
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				foreach ($Group in $UserGroups)
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing group: '$Group'"

					# Querying local machine
					$GroupUsers = Get-LocalGroupMember -Group $Group | Where-Object {
						$_.ObjectClass -eq "User" -and
						($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
					} | Select-Object -Property Name, SID

					if ([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "User group: '$Group' does not have any accounts on computer: $Computer"
						continue
					}

					foreach ($Account in $GroupUsers)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $($Account.Name)"

						$UserAccounts += [PSCustomObject]@{
							User = Split-Path -Path $Account.Name -Leaf
							Account = $Account.Name
							Computer = $Computer
							SID = $Account.SID
						}
					}
				} # foreach ($Group in $UserGroups)
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Computer `
					-Message "Querying remote computers without CIM switch not implemented"
			}
		} # foreach ($Computer in $ComputerNames)

		Write-Output $UserAccounts
	} # process
}

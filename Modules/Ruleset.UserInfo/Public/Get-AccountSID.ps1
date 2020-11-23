
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
Get SID for giver user account

.DESCRIPTION
Get SID's for single or multiple user names on a target computer

.PARAMETER UserNames
Array of user names

.PARAMETER ComputerName
Target computer on which to perform query

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-AccountSID "USERNAME" -Server "COMPUTERNAME"

.EXAMPLE
PS> Get-AccountSID @("USERNAME1", "USERNAME2") -CIM

.INPUTS
[string[]] One or more user names

.OUTPUTS
[string] SID's (security identifiers)

.NOTES
TODO: CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: plural parameter "UserNames"
#>
function Get-AccountSID
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-AccountSID.md")]
	[OutputType([string])]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true, Position = 0,
			ValueFromPipeline = $true)]
		[string[]] $UserNames,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$PowerShellEdition = $PSVersionTable.PSEdition
		[bool] $SpecialDomain = ![string]::IsNullOrEmpty(
			[array]::Find($KnownDomains, [System.Predicate[string]] { $ComputerName -eq "$($args[0])" }))
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($User in $UserNames)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $ComputerName\$User"

			# TODO: should we query system accounts remotely?
			if ($CIM -and !$SpecialDomain)
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
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying CIM server on $ComputerName"

					$AccountSID = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -EQ $User | Select-Object -ExpandProperty SID
				}
				else
				{
					return
				}
			}
			elseif ($ComputerName -eq [System.Environment]::MachineName -or $SpecialDomain)
			{
				if ($CIM)
				{
					Write-Warning -Message "-CIM switch ignored for $ComputerName"
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $ComputerName\$User"

				try
				{
					# For APPLICATION PACKAGE AUTHORITY we need to omit domain name
					# TODO: this should be inside second try/catch to make omission of domain generic
					if ($SpecialDomain -and [array]::Find($KnownDomains, [System.Predicate[string]] { "APPLICATION PACKAGE AUTHORITY" -eq "$($args[0])" }))
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($User)
						$AccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
					else
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($ComputerName, $User)
						$AccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
				}
				catch
				{
					Write-Error -TargetObject $_.TargetObject -Message "[$($MyInvocation.InvocationName)] Account '$ComputerName\$User' cannot be resolved to a SID`n $_.Exception"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
					-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($AccountSID))
			{
				Write-Error -TargetObject $AccountSID -Message "Account '$ComputerName\$User' cannot be resolved to a SID"
			}
			else
			{
				Write-Output -InputObject $AccountSID
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

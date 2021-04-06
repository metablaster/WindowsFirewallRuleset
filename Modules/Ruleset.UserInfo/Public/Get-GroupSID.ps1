
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

<#
.SYNOPSIS
Get SID of user groups on local or remote computers

.DESCRIPTION
Get SID's for single or multiple user groups on a target computer

.PARAMETER Group
Array of user groups or single group name

.PARAMETER Domain
Computer name which to query for group users

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-GroupSID "USERNAME" -Domain "COMPUTERNAME"

.EXAMPLE
PS> Get-GroupSID @("USERNAME1", "USERNAME2") -CIM

.INPUTS
[string[]] One or more group names

.OUTPUTS
[string] SID's (security identifiers)

.NOTES
None.
#>
function Get-GroupSID
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupSID.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("UserGroup")]
		[string[]] $Group,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	}
	process
	{
		foreach ($UserGroup in $Group)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $Domain\$UserGroup"

			if ($CIM)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

				if (Test-TargetComputer $Domain)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Domain"

					$GroupSID = Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
						-Class Win32_Group -Property Name |
					Where-Object -Property Name -EQ $UserGroup | Select-Object -ExpandProperty SID
				}
				else
				{
					continue
				}
			}
			elseif ($Domain -eq [System.Environment]::MachineName)
			{
				$GroupSID = Get-LocalGroup -Name $UserGroup |
				Select-Object -ExpandProperty SID |
				Select-Object -ExpandProperty Value
			}
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Domain `
					-Message "Querying remote computers without CIM switch not supported"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($GroupSID))
			{
				Write-Error -Category InvalidResult -TargetObject $UserGroup `
					-Message "User group '$UserGroup' cannot be resolved to a SID."
			}
			else
			{
				Write-Output $GroupSID
			}
		} # foreach ($UserGroup in $Group)
	} # process
}

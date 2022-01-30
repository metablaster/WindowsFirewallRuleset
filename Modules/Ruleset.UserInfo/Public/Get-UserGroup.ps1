
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

<#
.SYNOPSIS
Get user groups on target computers

.DESCRIPTION
Get a list of all available user groups on target computers

.PARAMETER Domain
One or more computers which to query for user groups

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-UserGroup "ServerPC"

.EXAMPLE
PS> Get-UserGroup @(DESKTOP, LAPTOP) -CIM

.INPUTS
None. You cannot pipe objects to Get-UserGroup

.OUTPUTS
[PSCustomObject] User groups on target computers

.NOTES
None.
#>
function Get-UserGroup
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-UserGroup.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	}
	process
	{
		foreach ($Computer in $Domain)
		{
			if ($CIM)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

				# Core: -TimeoutSeconds -IPv4
				if (Test-Computer $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					$RemoteGroups = Get-CimInstance -CimSession $CimServer -Namespace "root\cimv2" `
						-Class Win32_Group -Property LocalAccount |
					Where-Object -Property LocalAccount -EQ "True"

					if ([string]::IsNullOrEmpty($RemoteGroups))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] There are no user groups on computer: $Computer"
					}

					foreach ($Group in $RemoteGroups)
					{
						[PSCustomObject]@{
							Domain = $Group.Domain
							Group = $Group.Name
							Principal = $Group.Caption
							SID = $Group.SID
							LocalAccount = $Group.LocalAccount -eq "True"
							PSTypeName = "Ruleset.UserInfo"
						}
					}
				}
			} # if ($CIM)
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				# Querying local machine
				$LocalGroups = Get-LocalGroup

				if ([string]::IsNullOrEmpty($LocalGroups))
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] There are no user groups on computer: $Computer"
				}

				foreach ($Group in $LocalGroups)
				{
					[PSCustomObject]@{
						Domain = $Computer
						Group = $Group.Name
						Principal = Join-Path -Path $Computer -ChildPath $Group.Name
						SID = $Group.SID
						LocalAccount = $Group.PrincipalSource -eq "Local"
						PSTypeName = "Ruleset.UserInfo"
					}
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Computer `
					-Message "Querying remote computers without CIM switch not supported"
			} # if ($CIM)
		} # foreach ($Computer in $Domain)
	} # process
}

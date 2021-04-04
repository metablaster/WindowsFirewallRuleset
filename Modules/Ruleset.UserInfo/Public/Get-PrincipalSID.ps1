
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Get SID for specified user account

.DESCRIPTION
Get SID's for single or multiple user names on a target computer

.PARAMETER User
Array of user names

.PARAMETER Domain
Target computer on which to perform query

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> Get-PrincipalSID "User" -Server "Server01"

.EXAMPLE
PS> Get-PrincipalSID @("USERNAME1", "USERNAME2") -CIM

.INPUTS
[string[]] One or more user names

.OUTPUTS
[string] SID's (security identifiers)

.NOTES
None.
#>
function Get-PrincipalSID
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-PrincipalSID.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("UserName")]
		[string[]] $User,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[bool] $IsKnownDomain = ![string]::IsNullOrEmpty(
			[array]::Find($KnownDomains, [System.Predicate[string]] { $Domain -eq "$($args[0])" }))
	}
	process
	{
		foreach ($UserName in $User)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $Domain\$UserName"

			# TODO: should we query system accounts remotely?
			if ($CIM -and !$IsKnownDomain)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

				if (Test-TargetComputer $Domain)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying CIM server on $Domain"

					$PrincipalSID = Get-CimInstance -CimSession $RemoteCIM -Namespace "root\cimv2" `
						-Class Win32_UserAccount -Property Name |
					Where-Object -Property Name -EQ $UserName | Select-Object -ExpandProperty SID
				}
				else
				{
					return
				}
			}
			elseif ($Domain -eq [System.Environment]::MachineName -or $IsKnownDomain)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for principal: $Domain\$UserName"

				try
				{
					# For APPLICATION PACKAGE AUTHORITY we need to omit domain name
					# TODO: this should be inside second try/catch to make omission of domain generic
					if ($IsKnownDomain -and [array]::Find($KnownDomains, [System.Predicate[string]] { "APPLICATION PACKAGE AUTHORITY" -eq "$($args[0])" }))
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($UserName)
						$PrincipalSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
					else
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($Domain, $UserName)
						$PrincipalSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
				}
				catch
				{
					Write-Error -Category $_.CategoryInfo.Category -TargetObject $NTAccount `
						-Message "[$($MyInvocation.InvocationName)] Principal '$Domain\$UserName' cannot be resolved to a SID`n $($_.Exception.Message)"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Domain `
					-Message "Querying remote computers without CIM switch not supported"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($PrincipalSID))
			{
				Write-Error -Category InvalidResult -TargetObject $PrincipalSID `
					-Message "Principal '$Domain\$UserName' cannot be resolved to a SID"
			}
			else
			{
				Write-Output $PrincipalSID
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

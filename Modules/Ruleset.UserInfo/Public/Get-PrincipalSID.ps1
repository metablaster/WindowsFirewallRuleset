
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
One or more user names

.PARAMETER Domain
Target computer on which to perform query

.PARAMETER CimSession
Specifies the CIM session to use

.EXAMPLE
PS> Get-PrincipalSID "User" -Domain "Server01"

.EXAMPLE
PS> Get-PrincipalSID @("USERNAME1", "USERNAME2")

.EXAMPLE
PS> Get-PrincipalSID "User" -CimSession (New-CimSession)

.INPUTS
[string[]] One or more user names

.OUTPUTS
[PSCustomObject]

.NOTES
None.
#>
function Get-PrincipalSID
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-PrincipalSID.md")]
	[OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("UserName")]
		[string[]] $User,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$CimParams = @{
			Namespace = "root\cimv2"
		}

		if ($PSCmdlet.ParameterSetName -eq "CimSession")
		{
			$Domain = $CimSession.ComputerName
			$CimParams.CimSession = $CimSession
		}
		else
		{
			# Replace localhost and dot with NETBIOS computer name
			if (($Domain -eq "localhost") -or ($Domain -eq "."))
			{
				$Domain = [System.Environment]::MachineName
			}

			$CimParams.ComputerName = $Domain
		}

		[bool] $IsKnownDomain = ![string]::IsNullOrEmpty(
			[array]::Find($KnownDomains, [System.Predicate[string]] { $Domain -eq $args[0] }))
	}
	process
	{
		foreach ($UserName in $User)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $Domain\$UserName"

			if (!$CimSession -and (($Domain -eq [System.Environment]::MachineName) -or $IsKnownDomain))
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
						-Message "Principal '$Domain\$UserName' cannot be resolved to a SID`n $($_.Exception.Message)"
					continue
				}
			}
			# TODO: we should query certain 'system' accounts such as SQL users remotely
			elseif (Test-Computer $Domain)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying CIM server on $Domain"

				$PrincipalSID = Get-CimInstance @CimParams -Class Win32_UserAccount -Property Name, SID |
				Where-Object -Property Name -EQ $UserName | Select-Object -ExpandProperty SID
			}
			else { continue }

			if ([string]::IsNullOrEmpty($PrincipalSID))
			{
				Write-Error -Category InvalidResult -TargetObject $PrincipalSID `
					-Message "Principal '$Domain\$UserName' cannot be resolved to a SID"
			}
			else
			{
				[PSCustomObject]@{
					Domain = $Domain
					User = $UserName
					Principal = "$Domain\$UserName"
					SID = $PrincipalSID
					PSTypeName = "Ruleset.Userinfo.Principal"
				}
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

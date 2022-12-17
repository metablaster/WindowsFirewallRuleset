
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
Get SID of user groups on local or remote computers

.DESCRIPTION
Get SID's for single or multiple user groups on a target computer

.PARAMETER Group
Array of user groups or single group name

.PARAMETER Domain
Computer name which to query for group users

.PARAMETER CimSession
Specifies the CIM session to use

.EXAMPLE
PS> Get-GroupSID "USERNAME" -Domain "COMPUTERNAME"

.EXAMPLE
PS> Get-GroupSID @("USERNAME1", "USERNAME2")

.EXAMPLE
PS> Get-GroupSID "USERNAME" -CimSession (New-CimSession)

.INPUTS
[string[]] One or more group names

.OUTPUTS
[PSCustomObject]

.NOTES
None.
#>
function Get-GroupSID
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupSID.md")]
	[OutputType("Ruleset.UserInfo.Group")]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("UserGroup")]
		[string[]] $Group,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[hashtable] $CimParams = @{
			Namespace = "root\cimv2"
		}

		if ($PSCmdlet.ParameterSetName -eq "CimSession")
		{
			$Domain = $CimSession.ComputerName
			$CimParams.CimSession = $CimSession
		}
		else
		{
			$Domain = Format-ComputerName $Domain
			$CimParams.ComputerName = $Domain
		}
	}
	process
	{
		foreach ($UserGroup in $Group)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $Domain\$UserGroup"

			if (($PSCmdlet.ParameterSetName -eq "Domain") -and ($Domain -eq [System.Environment]::MachineName))
			{
				$GroupSID = Get-LocalGroup -Name $UserGroup |
				Select-Object -ExpandProperty SID |
				Select-Object -ExpandProperty Value
			}
			elseif (Test-Computer $Domain)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Domain"

				$GroupSID = Get-CimInstance @CimParams -Class Win32_Group -Property Name, SID |
				Where-Object -Property Name -EQ $UserGroup | Select-Object -ExpandProperty SID
			}
			else { continue }

			if ([string]::IsNullOrEmpty($GroupSID))
			{
				Write-Error -Category InvalidResult -TargetObject $UserGroup `
					-Message "User group '$UserGroup' cannot be resolved to a SID"
			}
			else
			{
				[PSCustomObject]@{
					Domain = $Domain
					Group = $UserGroup
					SID = $GroupSID
					PSTypeName = "Ruleset.UserInfo.Group"
				}
			}
		} # foreach ($UserGroup in $Group)
	} # process
}

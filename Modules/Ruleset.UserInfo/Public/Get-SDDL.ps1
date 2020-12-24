
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
Generate SDDL string of multiple usernames or/and groups on a given domain

.DESCRIPTION
Get SDDL string single or multiple user names and/or user groups on a single target computer

.PARAMETER User
Array of users for which to generate SDDL string

.PARAMETER Group
Array of user groups for which to generate SDDL string

.PARAMETER Domain
Single domain or computer such as remote computer name or builtin computer domain

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.EXAMPLE
PS> [string[]] $Users = "User"
PS> [string] $Server = COMPUTERNAME
PS> [string[]] $Groups = "Users", "Administrators"

PS> $UsersSDDL1 = Get-SDDL -User $Users -Group $Groups
PS> $UsersSDDL2 = Get-SDDL -User $Users -Machine $Server
PS> $UsersSDDL3 = Get-SDDL -Group $Groups

.EXAMPLE
PS> $NewSDDL = Get-SDDL -Domain "NT AUTHORITY" -User "System"

.INPUTS
None. You cannot pipe objects to Get-SDDL

.OUTPUTS
[string] SDDL for given accounts or/and group for given domain

.NOTES
None.
#>
function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-SDDL.md")]
	[OutputType([string])]
	param (
		[Alias("UserName")]
		[Parameter(Mandatory = $true, ParameterSetName = "User")]
		[Parameter(Mandatory = $false, ParameterSetName = "Group")]
		[string[]] $User,

		[Alias("UserGroup")]
		[Parameter(Mandatory = $true, ParameterSetName = "Group")]
		[string[]] $Group,

		[Alias("ComputerName", "CN")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($UserName in $User)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for account: $Domain\$UserName"

		$SID = Get-PrincipalSID $UserName -Domain $Domain -CIM:$CIM
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	foreach ($UserGroup in $Group)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for group: $Domain\$UserGroup"

		$SID = Get-GroupSID $UserGroup -Domain $Domain -CIM:$CIM
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	if ($SDDL.Length -lt 3)
	{
		Write-Error -TargetObject $SDDL -Message "Failed to assemble SDDL"
	}
	else
	{
		return $SDDL
	}
}


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
Generate SDDL string

.DESCRIPTION
Get SDDL string for single or multiple user names and/or user groups, file system or registry
locations on a single target computer

.PARAMETER User
One or more users for which to generate SDDL string

.PARAMETER Group
One or more user groups for which to generate SDDL string

.PARAMETER LiteralPath
One or multiple file system or registry locations from which to obtain SDDL

.PARAMETER Domain
Single domain or computer such as remote computer name or builtin computer domain

.PARAMETER CIM
Whether to contact CIM server (required for remote computers)

.PARAMETER Merge
If specified combines resultant SDDL strings into one

.EXAMPLE
PS> [string[]] $Users = "User"
PS> [string] $Server = COMPUTERNAME
PS> [string[]] $Groups = "Users", "Administrators"

PS> $UsersSDDL1 = Get-SDDL -User $Users -Group $Groups
PS> $UsersSDDL2 = Get-SDDL -User $Users -Domain $Server
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

		[Parameter(Mandatory = $true, ParameterSetName = "Path")]
		[string[]] $LiteralPath,

		[Alias("ComputerName", "CN")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM,

		[Parameter()]
		[switch] $Merge
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	if ($LiteralPath)
	{
		if ($CIM)
		{
			Write-Error -Category NotImplemented -TargetObject $TargetPath `
				-Message "Getting SDDL for path location from remote computers not implemented"
			return
		}

		foreach ($PathItem in $LiteralPath)
		{
			$TargetPath = Resolve-Path -Path $PathItem -ErrorAction Ignore

			if (!$TargetPath)
			{
				Write-Error -Category ObjectNotFound -TargetObject $PathItem -Message "The path does not exist: $PathItem"
				continue
			}

			$ACL = Get-Acl $TargetPath
			if ($ACL)
			{
				if ($Merge)
				{
					$SDDL += $ACL.Sddl
				}
				else
				{
					Write-Output $ACL.Sddl
				}
			}
			else
			{
				Write-Warning -Message "The path contains no principals: $TargetPath"
				continue
			}
		}
	}
	else
	{
		foreach ($UserName in $User)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user principal SDDL: $Domain\$UserName"

			$SID = Get-PrincipalSID $UserName -Domain $Domain -CIM:$CIM
			if ($SID)
			{
				$NewSDDL = "(A;;CC;;;{0})" -f $SID
				if ($Merge)
				{
					$SDDL += $NewSDDL
				}
				else
				{
					Write-Output $NewSDDL
				}
			}
		}

		foreach ($UserGroup in $Group)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting group principal SDDL: $Domain\$UserGroup"

			$SID = Get-GroupSID $UserGroup -Domain $Domain -CIM:$CIM
			if ($SID)
			{
				$NewSDDL = "(A;;CC;;;{0})" -f $SID
				if ($Merge)
				{
					$SDDL += $NewSDDL
				}
				else
				{
					Write-Output $NewSDDL
				}
			}
		}
	}

	if ($Merge)
	{
		if ($SDDL.Length -lt 3)
		{
			Write-Error -TargetObject $SDDL -Message "Failed to assemble SDDL"
		}
		else
		{
			return $SDDL
		}
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Get SDDL string of a user, group or from path

.DESCRIPTION
Get SDDL string for single or multiple user names and/or user groups, file system or registry
locations on a single target computer

.PARAMETER User
One or more users for which to obtain SDDL string

.PARAMETER Group
One or more user groups for which to obtain SDDL string

.PARAMETER Domain
Single domain or computer such as remote computer name or builtin computer domain

.PARAMETER CimSession
Specifies the CIM session to use

.PARAMETER Merge
If specified, combines resultant SDDL strings into one

.EXAMPLE
PS> Get-SDDL -User USERNAME -Domain COMPUTERNAME

.EXAMPLE
PS> Get-SDDL -Group @("Users", "Administrators") -Merge

.EXAMPLE
PS> Get-SDDL -Domain "NT AUTHORITY" -User "System"

.INPUTS
None. You cannot pipe objects to Get-SDDL

.OUTPUTS
[string]

.NOTES
TODO: Mandatory parameter is impossible to make
#>
function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-SDDL.md")]
	[OutputType([string])]
	param (
		[Parameter()]
		[Alias("UserName")]
		[string[]] $User,

		[Parameter()]
		[Alias("UserGroup")]
		[string[]] $Group,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession,

		[Parameter()]
		[switch] $Merge
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if (($null -eq $User) -and ($null -eq $Group))
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Please specify either User or Group"
		return
	}

	[hashtable] $ConnectParams = @{}
	if ($PSCmdlet.ParameterSetName -eq "CimSession")
	{
		$Domain = $CimSession.ComputerName
		$ConnectParams.CimSession = $CimSession
	}
	else
	{
		$Domain = Format-ComputerName $Domain
		$ConnectParams.Domain = $Domain
	}

	# MSDN: Glossary:
	# SDDL: Security Descriptor Definition Language
	# ACE: Access Control Entry (Describes what access rights a security principal has to the secured object)
	# SID: Security IDentifier (Identifies a user or group)
	# DACL: Discretionary Access Control List (ACEs in DACL identify the users and groups that are assigned or denied access permissions on an object)
	# SACL: System Access Control List (ACEs in a SACL determine what types of access is logged in the Security Event Log)
	# ACL: Access Control List (Base name for DACL and SACL, DACL and SACL are ACL's)

	# https://docs.microsoft.com/en-us/windows/win32/secauthz/ace-strings
	# MSDN: SDDL uses ACE strings in the DACL and SACL, each ACE is enclosed in parentheses.
	# The fields of each ACE are separated by semicolons.
	# ace_type;ace_flags;rights;object_guid;inherit_object_guid;account_sid;(resource_attribute)

	# https://docs.microsoft.com/en-us/windows/win32/secauthz/security-descriptor-definition-language
	# MSDN: The four main components of SDDL are:
	# owner SID 			(O:sid)			A SID string that identifies the object's owner
	# primary group SID 	(G:sid)			A SID string that identifies the object's primary group.
	# DACL flags 			(D:flags) (ACE 1)..(ACE n)
	# SACL flags 			(S:flags) (ACE 1)..(ACE n)

	<# MSDN: The DACL flags can be a concatenation of zero or more of the following strings:
	"P"					SE_DACL_PROTECTED flag is set.
	"AR"				SE_DACL_AUTO_INHERIT_REQ flag is set.
	"AI"				SE_DACL_AUTO_INHERITED flag is set.
	"NO_ACCESS_CONTROL"	ACL is null.

	MSDN: The SACL flags string uses the same control bit strings as the dacl_flags string.
	DACL and SACL flags control bits that relate to automatic inheritance of ACE
	ACE: A string that describes an ACE in the security descriptor's DACL or SACL
	#>

	[string] $DACL = "D:"
	foreach ($UserName in $User)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user principal SDDL: $Domain\$UserName"
		$SID = (Get-PrincipalSID $UserName @ConnectParams).SID

		if ($SID)
		{
			# https://docs.microsoft.com/en-us/windows-hardware/drivers/kernel/access-mask
			# https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-addaccessallowedace
			# MSDN: To simplify specifying all access rights that correspond to a general notion such as reading or writing,
			# the system provides generic access rights.
			# The system maps a generic access right to the appropriate set of specific access rights for the object.
			# The meaning of each generic access right is specific to that type of object.

			# MSDN: ace_type
			# "A"	ACCESS_ALLOWED_ACE_TYPE		The access is granted to a specified security identifier (SID)

			# MSDN: rights (Generic access rights)
			# "GA"	GENERIC_ALL			The caller can perform all normal operations on the object.
			# "GR"	GENERIC_READ		The caller can perform normal read operations on the object.
			# "GW"	GENERIC_WRITE		The caller can perform normal write operations on the object.
			# "GX"	GENERIC_EXECUTE		The caller can execute the object.
			# TODO: generic access rights wont work, ex. GA
			$ACE = "(A;;CC;;;$SID)"

			if ($Merge)
			{
				$DACL += $ACE
			}
			else
			{
				Write-Output ($DACL + $ACE)
			}
		}
	}

	foreach ($UserGroup in $Group)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting group principal SDDL: $Domain\$UserGroup"
		$SID = (Get-GroupSID $UserGroup @ConnectParams).SID

		if ($SID)
		{
			$ACE = "(A;;CC;;;$SID)"

			if ($Merge)
			{
				$DACL += $ACE
			}
			else
			{
				Write-Output ($DACL + $ACE)
			}
		}
	}

	if ($Merge)
	{
		if ($DACL.Length -lt 3)
		{
			Write-Error -Category InvalidResult -TargetObject $DACL -Message "Failed to assemble SDDL"
		}
		else
		{
			Write-Output $DACL
		}
	}
}

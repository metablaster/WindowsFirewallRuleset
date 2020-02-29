<#
.SYNOPSIS
get SID for giver user name
.PARAMETER UserName
username string
.EXAMPLE
Get-UserSID("TestUser")
.INPUTS
None. You cannot pipe objects to Get-UserSID
.OUTPUTS
System.String SID (security identifier)
.NOTES
TODO: implement queriying computers on network
#>
function Get-UserSID
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $UserName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for user: $UserName"
		$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($UserName)
		return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()
	}
	catch
	{
		Write-Warning -Message "User '$UserName' cannot be resolved to a SID."
	}
}

<#
.SYNOPSIS
get SID for giver computer account
.PARAMETER UserAccount
computer account string
.EXAMPLE
Get-AccountSID("COMPUTERNAME\USERNAME")
.INPUTS
None. You cannot pipe objects to Get-AccountSID
.OUTPUTS
System.String SID (security identifier)
.NOTES
TODO: implement queriying computers on network
#>
function Get-AccountSID
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $UserAccount
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $Domain = ($UserAccount.split("\"))[0]
	[string] $User = ($UserAccount.split("\"))[1]

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $UserAccount"
		$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($Domain, $User)
		return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()
	}
	catch
	{
		Write-Warning -Message "Get-AccountSID: Account '$UserAccount' cannot be resolved to a SID."
	}
}

<#
.SYNOPSIS
get SDDL of specified local user name or multiple users names
.PARAMETER UserNames
String array of user names
.EXAMPLE
Get-UserSDDL user1, user2
.INPUTS
None. You cannot pipe objects to Get-UserSDDL
.OUTPUTS
System.String SDDL for given usernames
.NOTES
TODO: implement queriying computers on network
#>
function Get-UserSDDL
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $UserNames
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($User in $UserNames)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for user: $User"

		try
		{
			$SID = Get-UserSID $User
		}
		catch
		{
			Write-Warning -Message "User '$User' not found"
			continue
		}

		$SDDL += "(A;;CC;;;{0})" -f $SID
	}

	return $SDDL
}

<#
.SYNOPSIS
get SDDL of multiple computer accounts, in form of: COMPUTERNAME\USERNAME
.PARAMETER UserAccounts
String array of computer accounts
.EXAMPLE
Get-AccountSDDL @("NT AUTHORITY\SYSTEM", "MY_DESKTOP\MY_USERNAME")
.INPUTS
None. You cannot pipe objects to Get-AccountSDDL
.OUTPUTS
System.String SDDL string for given accounts
.NOTES
TODO: implement queriying computers on network
#>
function Get-AccountSDDL
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $UserAccounts
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($Account in $UserAccounts)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for account: $Account"

		try
		{
			$SID = Get-AccountSID $Account
		}
		catch
		{
			Write-Warning -Message "User account '$UserAccount' not found"
			continue
		}

		$SDDL += "(A;;CC;;;{0})" -f $SID
	}

	return $SDDL
}

<#
.SYNOPSIS
get computer accounts for a giver user group
.PARAMETER UserGroup
User group on local computer
.EXAMPLE
Get-UserAccounts("Administrators")
.INPUTS
None. You cannot pipe objects to Get-UserAccounts
.OUTPUTS
System.String[] Array of enabled user accounts in specified group, in form of COMPUTERNAME\USERNAME
.NOTES
TODO: implement queriying computers on network
TODO: should be renamed into Get-GroupPrincipals
#>
function Get-UserAccounts
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string] $UserGroup
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user accounts for group: $UserGroup"

	$GroupUsers = Get-LocalGroupMember -Group $UserGroup |
	Where-Object { $_.PrincipalSource -eq "Local" -and $_.ObjectClass -eq "User" } |
	Select-Object -ExpandProperty Name

	if ([string]::IsNullOrEmpty($GroupUsers))
	{
		Write-Warning -Message "Failed to get UserAccounts for group: $UserGroup"
	}

	return $GroupUsers
}

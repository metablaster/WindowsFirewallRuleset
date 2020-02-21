
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

# TODO: write function to query system users

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
TODO: should be renamed into Get-GroupUsers
#>
function Get-UserAccounts
{
	param(
		[Parameter(Mandatory = $true)]
		[ValidateLength(1, 100)]
		[string] $UserGroup
	)

	$GroupUsers = Get-LocalGroupMember -Group $UserGroup |
	Where-Object { $_.PrincipalSource -eq "Local" -and $_.ObjectClass -eq "User" } |
	Select-Object -ExpandProperty Name

	if([string]::IsNullOrEmpty($GroupUsers))
	{
		Set-Warning "Get-UserAccounts: Failed to get UserAccounts for group '$UserGroup'"
	}

	return $GroupUsers
}

<#
.SYNOPSIS
Strip computer names out of computer acounts
.PARAMETER UserAccounts
String array of user accounts in form of: COMPUTERNAME\USERNAME
.EXAMPLE
Get-UserNames(@("DESKTOP_PC\USERNAME", "LAPTOP\USERNAME"))
.INPUTS
None. You cannot pipe objects to Get-UserNames
.OUTPUTS
System.String[] Array of usernames in form of: USERNAME
.NOTES
TODO: implement queriying computers on network
#>
function Get-UserNames
{
	param(
		[Parameter(Mandatory = $true)]
		[ValidateCount(1, 1000)]
		[ValidateLength(1, 100)]
		[string[]] $UserAccounts
	)

	[string[]] $UserNames = @()
	foreach($Account in $UserAccounts)
	{
		$UserNames += $Account.split("\")[1]
	}

	return $UserNames
}

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
	param (
		[Parameter(Mandatory = $true)]
		[ValidateLength(1, 100)]
		[string] $UserName
	)

	try
	{
		$NTAccount = New-Object System.Security.Principal.NTAccount($UserName)
		return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()
	}
	catch
	{
		Set-Warning "Get-UserSID: User '$UserName' cannot be resolved to a SID."
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
	param (
		[Parameter(Mandatory = $true)]
		[ValidateLength(1, 100)]
		[string] $UserAccount
	)

	[string] $Domain = ($UserAccount.split("\"))[0]
	[string] $User = ($UserAccount.split("\"))[1]

	try
	{
		$NTAccount = New-Object System.Security.Principal.NTAccount($Domain, $User)
		return ($NTAccount.Translate([System.Security.Principal.SecurityIdentifier])).ToString()
	}
	catch
	{
		Set-Warning "Get-AccountSID: Account '$UserAccount' cannot be resolved to a SID."
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
	param (
		[Parameter(Mandatory = $true)]
		[ValidateCount(1, 1000)]
		[ValidateLength(1, 100)]
		[string[]] $UserNames
	)

	[string] $SDDL = "D:"

	foreach($User in $UserNames)
	{
		try
		{
			$SID = Get-UserSID($User)
		}
		catch
		{
			Set-Warning "Get-UserSDDL: User '$User' not found"
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
	param (
		[Parameter(Mandatory = $true)]
		[ValidateCount(1, 1000)]
		[ValidateLength(1, 100)]
		[string[]] $UserAccounts
	)

	[string] $SDDL = "D:"

	foreach ($Account in $UserAccounts)
	{
		try
		{
			$SID = Get-AccountSID $Account
		}
		catch
		{
			Set-Warning "Get-AccountSDDL: User account $UserAccount not found"
			continue
		}

		$SDDL += "(A;;CC;;;{0})" -f $SID

	}

	return $SDDL
}

#
# Module variables
#

# TODO: add more groups, guests, everyone etc; we should make use of groups instead of SDDL for existing users probably?
# but then individual users can't be removed by admin, on the other side there are rules which need all users regardless such as
# browser updater for edge-chromium and extension users for problem services.
# TODO: global configuration variables (in a separate script) should also include to set "USERS" instead of single user
if (!(Get-Variable -Name CheckInitUserInfo -Scope Global -ErrorAction Ignore))
{
	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckInitUserInfo -Scope Global -Option Constant -Value $null

	# Get list of user account in form of COMPUTERNAME\USERNAME
	New-Variable -Name UserAccounts -Scope Global -Option Constant -Value (Get-UserAccounts "Users")
	New-Variable -Name AdminAccounts -Scope Global -Option Constant -Value (Get-UserAccounts "Administrators")

	# Get list of user names in form of USERNAME
	New-Variable -Name UserNames -Scope Global -Option Constant -Value (Get-UserNames $UserAccounts)
	New-Variable -Name AdminNames -Scope Global -Option Constant -Value (Get-UserNames $AdminAccounts)

	# Generate SDDL string for accounts
	New-Variable -Name UserAccountsSDDL -Scope Global -Option Constant -Value (Get-AccountSDDL $UserAccounts)
	New-Variable -Name AdminAccountsSDDL -Scope Global -Option Constant -Value (Get-AccountSDDL $AdminAccounts)

	# System users (define variables as needed)
	New-Variable -Name NT_AUTHORITY_System -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-18)"
	New-Variable -Name NT_AUTHORITY_LocalService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-19)"
	New-Variable -Name NT_AUTHORITY_NetworkService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-20)"
	New-Variable -Name NT_AUTHORITY_UserModeDrivers -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
}

#
# Function exports
#

Export-ModuleMember -Function Get-UserAccounts
Export-ModuleMember -Function Get-UserNames
Export-ModuleMember -Function Get-UserSID
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function Get-UserSDDL
Export-ModuleMember -Function Get-AccountSDDL

#
# Variable exports
#
Export-ModuleMember -Variable CheckInitUserInfo

Export-ModuleMember -Variable UserAccounts
Export-ModuleMember -Variable AdminAccounts
Export-ModuleMember -Variable UserNames
Export-ModuleMember -Variable AdminNames
Export-ModuleMember -Variable UserAccountsSDDL
Export-ModuleMember -Variable AdminAccountsSDDL

Export-ModuleMember -Variable NT_AUTHORITY_System
Export-ModuleMember -Variable NT_AUTHORITY_LocalService
Export-ModuleMember -Variable NT_AUTHORITY_NetworkService
Export-ModuleMember -Variable NT_AUTHORITY_UserModeDrivers

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	$ThisModule = $MyInvocation.MyCommand.Name -replace ".{5}$"

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

#
# System users SDDL strings
#

# "D:(A;;CC;;;S-1-5-0)" # Unknown
# $NT_AUTHORITY_DialUp = "D:(A;;CC;;;S-1-5-1)"
# $NT_AUTHORITY_Network = "D:(A;;CC;;;S-1-5-2)"
# $NT_AUTHORITY_Batch = "D:(A;;CC;;;S-1-5-3)"
# $NT_AUTHORITY_Interactive = "D:(A;;CC;;;S-1-5-4)"
# "D:(A;;CC;;;S-1-5-5)" # Unknown
# $NT_AUTHORITY_Service = "D:(A;;CC;;;S-1-5-6)"
# $NT_AUTHORITY_AnonymousLogon = "D:(A;;CC;;;S-1-5-7)"
# $NT_AUTHORITY_Proxy = "D:(A;;CC;;;S-1-5-8)"
# $NT_AUTHORITY_EnterpriseDomainControlers = "D:(A;;CC;;;S-1-5-9)"
# $NT_AUTHORITY_Self = "D:(A;;CC;;;S-1-5-10)"
# $NT_AUTHORITY_AuthenticatedUsers = "D:(A;;CC;;;S-1-5-11)"
# $NT_AUTHORITY_Restricted = "D:(A;;CC;;;S-1-5-12)"
# $NT_AUTHORITY_TerminalServerUser = "D:(A;;CC;;;S-1-5-13)"
# $NT_AUTHORITY_RemoteInteractiveLogon = "D:(A;;CC;;;S-1-5-14)"
# $NT_AUTHORITY_ThisOrganization = "D:(A;;CC;;;S-1-5-15)"
# "D:(A;;CC;;;S-1-5-16)" # Unknown
# $NT_AUTHORITY_Iusr = "D:(A;;CC;;;S-1-5-17)"
# $NT_AUTHORITY_System = "D:(A;;CC;;;S-1-5-18)"
# $NT_AUTHORITY_LocalService = "D:(A;;CC;;;S-1-5-19)"
# $NT_AUTHORITY_NetworkService = "D:(A;;CC;;;S-1-5-20)"
# "D:(A;;CC;;;S-1-5-21)" ENTERPRISE_READONLY_DOMAIN_CONTROLLERS (S-1-5-21-<root domain>-498)
# $NT_AUTHORITY_EnterpriseReadOnlyDomainControlersBeta = "D:(A;;CC;;;S-1-5-22)"
# "D:(A;;CC;;;S-1-5-23)" # Unknown

# Application packages
# $APPLICATION_PACKAGE_AUTHORITY_AllApplicationPackages = "D:(A;;CC;;;S-1-15-2-1)"
# $APPLICATION_PACKAGE_AUTHORITY_AllRestrictedApplicationPackages = "D:(A;;CC;;;S-1-15-2-2)"
# "D:(A;;CC;;;S-1-15-2-3)" #Unknown

# Other System Users
# $NT_AUTHORITY_UserModeDrivers = "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"

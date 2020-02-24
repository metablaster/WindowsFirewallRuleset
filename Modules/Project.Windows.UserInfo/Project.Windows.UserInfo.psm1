
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

Set-StrictMode -Version Latest

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

# Includes
. $PSScriptRoot\External\ConvertFrom-SID.ps1

# TODO: write function to query system users
# TODO: get a user account that is connected to a Microsoft account. see Get-LocalUser docs.

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

	if([string]::IsNullOrEmpty($GroupUsers))
	{
		Write-Warning -Message "Failed to get UserAccounts for group: $UserGroup"
	}

	return $GroupUsers
}

<#
.SYNOPSIS
Strip computer names out of computer acounts
.PARAMETER UserAccounts
String array of user accounts in form of: COMPUTERNAME\USERNAME
.EXAMPLE
ConvertFrom-UserAccounts @("DESKTOP_PC\USERNAME", "LAPTOP\USERNAME")
.INPUTS
None. You cannot pipe objects to ConvertFrom-UserAccounts
.OUTPUTS
System.String[] Array of usernames in form of: USERNAME
.NOTES
TODO: implement queriying computers on network
#>
function ConvertFrom-UserAccounts
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string[]] $UserAccounts
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string[]] $UserNames = @()
	foreach($Account in $UserAccounts)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user names for account: $Account"
		$UserNames += $Account.split("\")[1]
	}

	return $UserNames
}

<#
.SYNOPSIS
get computer accounts for a giver user groups on given computers
.PARAMETER UserGroup
User group on local or remote computer
.PARAMETER ComputerNames
One or more computers which to querry for group users, default is localhost
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
.EXAMPLE
Get-GroupUsers "Users", "Administrators"
.EXAMPLE
Get-GroupUsers "Users" -Machine COMPUTERNAME -CIM
.INPUTS
System.String User group
.OUTPUTS
System.Management.Automation.PSCustomObject of enabled user accounts in specified group
.NOTES
CIM switch is not supported on PowerShell Core
#>
function Get-GroupUsers
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Group", "Groups")]
		[Parameter(Mandatory = $true,
		Position = 0,
		ValueFromPipeline = $true)]
		[string[]] $UserGroups,

		[Alias("Computer", "Machine", "Computers", "Machines")]
		[Parameter()]
		[string[]] $ComputerNames = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$UserAccounts = @()
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Computer in $ComputerNames)
		{
			if ($CIM)
			{
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $Computer `
					-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

				# Core: -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-Connection -ComputerName $Computer -Count $ConnectionCount -Quiet)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					foreach ($UserGroup in $UserGroups)
					{
						# Get all users that belong to requrested group,
						# this includes non local principal source and non 'user' users
						# it is also missing SID
						$GroupUsers = Get-CimInstance -Class Win32_GroupUser -Namespace "root\cimv2" -ComputerName $Computer |
						Where-Object { $_.GroupComponent.Name -eq $UserGroup } |
						Select-Object -ExpandProperty PartComponent |
						Select-Object -ExpandProperty Name

						# Get only enabled users, these include SID but also non group users
						$EnabledAccounts = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -Filter "LocalAccount = True" -ComputerName $Computer |
						Where-Object -Property Disabled -ne False |
						Select-Object -Property Name, Caption, SID, Domain

						if([string]::IsNullOrEmpty($EnabledAccounts))
						{
							Write-Warning -Message "User group '$UserGroup' does not have any accounts on computer: $Computer"
							continue
						}

						# Finally compare these 2 results and assemble group users which are active, also includes SID
						foreach ($Account in $EnabledAccounts)
						{
							if ($GroupUsers -contains $Account)
							{
								Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $Account"

								$UserAccounts += New-Object -TypeName PSObject -Property @{
									User = Split-Path -Path $Account -Leaf
									Account = $Account
									Computer = $Computer
									SID = $Account.SID
								}
							}
							else
							{
								Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring account: $Account"
							}
						}
					}
				}
				else
				{
					Write-Error -Category ConnectionError -TargetObject $ComputerName `
					-Message "Unable to contact computer: $ComputerName"
				}
			}
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				foreach ($UserGroup in $UserGroups)
				{
					# Querying local machine
					$GroupUsers = Get-LocalGroupMember -Group $UserGroup |
					Where-Object { $_.PrincipalSource -eq "Local" -and $_.ObjectClass -eq "User" } |
					Select-Object -Property Name, SID

					if([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "User group '$UserGroup' does not have any accounts on computer: $Computer"
						continue
					}

					foreach ($Account in $GroupUsers)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $($Account.Name)"

						$UserAccounts += New-Object -TypeName PSObject -Property @{
							User = Split-Path -Path $Account.Name -Leaf
							Account = $Account.Name
							Computer = $Computer
							SID = $Account.SID
						}
					}
				}
			}
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
				-Message "Querying remote computers without CIM switch not implemented"
			}
		}

		return $UserAccounts
	}
}

<#
.SYNOPSIS
get SID for giver computer account
.PARAMETER RefSDDL
Reference to SDDL into which to merge new SDDL
.PARAMETER NewSDDL
New SDDL string which to add to reference SDDL
.EXAMPLE
$RefSDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)
$NewSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
Merge-SDDL ([ref] $RefSDDL) $NewSDDL
.INPUTS
None. You cannot pipe objects to Get-AccountSID
.OUTPUTS
System.String SDDL string
#>
function Merge-SDDL
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ref] $RefSDDL,

		[Parameter(Mandatory = $true)]
		[string] $NewSDDL
	)

	$RefSDDL.Value += $NewSDDL.Substring(2)
}

<#
.SYNOPSIS
Generate SDDL string of multiple usernames or/and groups on given domain
.PARAMETER Domain
System.String single domain such as remote computer name
.PARAMETER Users
System.String[] array of users for which to generate SDDL string
.PARAMETER Groups
System.String[] array of user groups for which to generate SDDL string
.EXAMPLE
[string[]] $Users = "haxor"
[string] $Server = COMPUTERNAME
[string[]] $Groups = @("Users", "Administrators")

$UsersSDDL1 = Get-SDDL -Users $Users -Groups $Groups
$UsersSDDL2 = Get-SDDL -Users $Users -Machine $Server
$UsersSDDL3 = Get-SDDL -Groups $Groups
.EXAMPLE
$NewSDDL = Get-SDDL -Domain "NT AUTHORITY" -Users "System"
.INPUTS
None. You cannot pipe objects to Get-AccountSDDL
.OUTPUTS
System.String SDDL string for given accounts or/and group for given domain
.NOTES
TODO: implement queriying computers on network
#>
function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Computer", "Machine")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true, ParameterSetName="Account")]
		[Parameter(Mandatory = $false, ParameterSetName="Group")]
		[string[]] $Users,

		[Alias("UserGroup", "UserGroups", "Group")]
		[Parameter(Mandatory = $true, ParameterSetName="Group")]
		[string[]] $Groups
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($User in $Users)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for account: $Domain\$User"

		try
		{
			$SID = Get-AccountSID $Domain $User
		}
		catch
		{
			Write-Warning -Message "Failed to translate user account '$UserAccount' to SDDL"
			continue
		}

		$SDDL += "(A;;CC;;;{0})" -f $SID

	}

	foreach ($Group in $Groups)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for group: $Group"

		try
		{
			$SID = Get-GroupSID $Group
		}
		catch
		{
			Write-Warning -Message "Failed to translate user group '$Group' to SDDL"
			continue
		}

		$SDDL += "(A;;CC;;;{0})" -f $SID

	}

	return $SDDL
}

<#
.SYNOPSIS
Get SID of user group for given computer
.PARAMETER UserGroup
User group string
.EXAMPLE
Get-GroupSID "COMPUTERNAME" "USERNAME"
.EXAMPLE
Get-GroupSID "USERNAME"
.INPUTS
None. You cannot pipe objects to Get-AccountSID
.OUTPUTS
System.String SID (security identifier)
.NOTES
TODO: implement queriying computers on network
#>
function Get-GroupSID
{
	[CmdletBinding()]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true)]
		[string] $UserGroup
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for user group: $UserGroup"

	return Get-LocalGroup -Name $UserGroup | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
}

<#
.SYNOPSIS
Get SID for giver computer account
.PARAMETER UserAccount
computer account string
.EXAMPLE
Get-AccountSID "COMPUTERNAME" "USERNAME"
.EXAMPLE
Get-AccountSID "USERNAME"
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
		[Alias("Computer", "Machine")]
		[Parameter(Mandatory = $false)]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true)]
		[string] $User
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $Domain\$User"
		$NTAccount = New-Object System.Security.Principal.NTAccount($Domain, $User)
		return $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
	}
	catch
	{
		Write-Error -TargetObject $_.TargetObject -Message "[$($MyInvocation.InvocationName)] Account '$Domain\$User' cannot be resolved to a SID."
	}
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
	New-Variable -Name UserNames -Scope Global -Option Constant -Value (ConvertFrom-UserAccounts $UserAccounts)
	New-Variable -Name AdminNames -Scope Global -Option Constant -Value (ConvertFrom-UserAccounts $AdminAccounts)

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
Export-ModuleMember -Function ConvertFrom-UserAccounts
Export-ModuleMember -Function Get-UserSID
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function Get-UserSDDL
Export-ModuleMember -Function Get-AccountSDDL
Export-ModuleMember -Function ConvertFrom-SID
Export-ModuleMember -Function Get-GroupUsers

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
# System users SDDL strings
#

# [System.Security.Principal.WellKnownSidType]::NetworkSid
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

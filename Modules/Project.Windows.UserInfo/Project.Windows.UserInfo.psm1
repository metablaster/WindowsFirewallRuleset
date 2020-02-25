
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

# TODO: get a user account that is connected to a Microsoft account. see Get-LocalUser docs.

<#
.SYNOPSIS
Strip computer names out of computer acounts
.PARAMETER UserAccounts
String array of user accounts in form of: COMPUTERNAME\USERNAME
.EXAMPLE
$UserAccounts = Get-GroupUsers "Users", "Administrators"
$UserNames = ConvertFrom-UserAccounts ($UserAccounts | Select-Object -ExpandProperty Account)
.INPUTS
None. You cannot pipe objects to ConvertFrom-UserAccounts
.OUTPUTS
System.String[] Array of usernames in form of: USERNAME
#>
function ConvertFrom-UserAccount
{
	[CmdletBinding()]
	param(
		[Alias("Account")]
		[Parameter(Mandatory = $true)]
		[string[]] $UserAccounts
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string[]] $UserNames = @()
	foreach($Account in $UserAccounts)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user name for account: $Account"
		$UserNames += $Account.split("\")[1]
	}

	return $UserNames
}

<#
.SYNOPSIS
Get computer accounts for a given user groups on given computers
.PARAMETER Groups
User group on local or remote computer
.PARAMETER Computers
One or more computers which to querry for group users
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
.EXAMPLE
Get-GroupUsers @("Users", "Administrators")
.EXAMPLE
Get-GroupUsers "Users" -Machines @(DESKTOP, LAPTOP) -CIM
.INPUTS
System.String[] User groups
.OUTPUTS
PSCustomObject of enabled user accounts in specified group
.NOTES
CIM switch is not supported on PowerShell Core
Switch to list all accounts
#>
function Get-GroupUsers
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true,
		Position = 0,
		ValueFromPipeline = $true)]
		[string[]] $UserGroups,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
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

				# Core: -TargetName $Computer -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetMachine $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					foreach ($Group in $UserGroups)
					{
						# Get all users that belong to requrested group,
						# this includes non local principal source and non 'user' users
						# it is also missing SID
						$GroupUsers = Get-CimInstance -Class Win32_GroupUser -Namespace "root\cimv2" -ComputerName $Computer |
						Where-Object { $_.GroupComponent.Name -eq $Group } |
						Select-Object -ExpandProperty PartComponent |
						Select-Object -ExpandProperty Name

						# Get only enabled users, these include SID but also non group users
						$EnabledAccounts = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $Computer -Filter "LocalAccount = True" |
						Where-Object -Property Disabled -ne False |
						Select-Object -Property Name, Caption, SID, Domain

						if([string]::IsNullOrEmpty($EnabledAccounts))
						{
							Write-Warning -Message "User group '$Group' does not have any accounts on computer: $Computer"
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
					Write-Error -Category ConnectionError -TargetObject $Computer `
					-Message "Unable to contact computer: $Computer"
				}
			}
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				foreach ($Group in $UserGroups)
				{
					# Querying local machine
					$GroupUsers = Get-LocalGroupMember -Group $Group |
					Where-Object { $_.PrincipalSource -eq "Local" -and $_.ObjectClass -eq "User" } |
					Select-Object -Property Name, SID

					if([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "User group '$Group' does not have any accounts on computer: $Computer"
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
				Write-Error -Category NotImplemented -TargetObject $Computer `
				-Message "Querying remote computers without CIM switch not implemented"
			}
		}

		return $UserAccounts
	}
}

<#
.SYNOPSIS
Get user groups on target computers
.PARAMETER Computers
One or more computers which to querry for user groups
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
.EXAMPLE
Get-UserGroups "ServerPC"
.EXAMPLE
Get-UserGroups @(DESKTOP, LAPTOP) -CIM
.INPUTS
System.String[] User groups
.OUTPUTS
PSCustomObject of enabled user accounts in specified group
.NOTES
CIM switch is not supported on PowerShell Core
Switch to list all accounts
#>
function Get-UserGroups
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(Position = 0)]
		[string[]] $ComputerNames = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$UserGroups =@()
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
				if (Test-TargetMachine $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					$RemoteGroups = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" -ComputerName $Computer |
					Where-Object -Property LocalAccount -eq "True"

					foreach ($Group in $RemoteGroups)
					{
						$UserGroups += New-Object -TypeName PSObject -Property @{
							Group = $Group.Name
							Caption = $Group.Caption
							Computer = $Computer
							SID = $Group.SID
						}
					}

					if([string]::IsNullOrEmpty($UserGroups))
					{
						Write-Warning -Message "There are no user groups on computer: $Computer"
						continue
					}
				}
				else
				{
					Write-Error -Category ConnectionError -TargetObject $Computer `
					-Message "Unable to contact computer: $Computer"
				}
			} # if ($CIM)
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				# Querying local machine
				$LocalGroups = Get-LocalGroup
				foreach ($Group in $LocalGroups)
				{
					$UserGroups += New-Object -TypeName PSObject -Property @{
						Group = $Group.Name
						Caption = Join-Path -Path $Computer -ChildPath $Group.Name
						Computer = $Computer
						SID = $Group.SID
					}
				}

				if([string]::IsNullOrEmpty($UserGroups))
				{
					Write-Warning -Message "There are no user groups on computer: $Computer"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Computer `
				-Message "Querying remote computers without CIM switch not implemented"
			} # if ($CIM)
		} # foreach ($Computer in $ComputerNames)

		return $UserGroups
	}
}

<#
.SYNOPSIS
Merge 2 SDDL strings into one
.PARAMETER RefSDDL
Reference to SDDL into which to merge new SDDL
.PARAMETER NewSDDL
New SDDL string which to add to reference SDDL
.EXAMPLE
$RefSDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)
$NewSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
Merge-SDDL ([ref] $RefSDDL) $NewSDDL
.INPUTS
None. You cannot pipe objects to Merge-SDDL
.OUTPUTS
System.String SDDL string
.NOTES
Validate input using regex
Process an array of SDDL's
Pipeline input
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
Generate SDDL string of multiple usernames or/and groups on a given domain
.PARAMETER Computer
System.String single domain such as remote computer name
.PARAMETER Users
System.String[] array of users for which to generate SDDL string
.PARAMETER Groups
System.String[] array of user groups for which to generate SDDL string
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
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
None. You cannot pipe objects to Get-SDDL
.OUTPUTS
System.String SDDL string for given accounts or/and group for given domain
#>
function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true, ParameterSetName="User")]
		[Parameter(Mandatory = $false, ParameterSetName="Group")]
		[string[]] $UserNames,

		[Alias("Group")]
		[Parameter(Mandatory = $true, ParameterSetName="Group")]
		[string[]] $UserGroups,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(Mandatory = $false)]
		[string] $ComputerName = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $SDDL = "D:"

	foreach ($User in $UserNames)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for account: $ComputerName\$User"

		$SID = Get-AccountSID $User -Domain $ComputerName -CIM:$CIM
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	foreach ($Group in $UserGroups)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SDDL for group: $ComputerName\$Group"

		$SID = Get-GroupSID $Group -Domain $ComputerName -CIM:$CIM
		if ($SID)
		{
			$SDDL += "(A;;CC;;;{0})" -f $SID
		}
	}

	if($SDDL.Length -lt 3)
	{
		Write-Error -TargetObject $SDDL -Message "Failed to assemble SDDL"
	}
	else
	{
		return $SDDL
	}
}

<#
.SYNOPSIS
Get SID of user groups for given computer
.PARAMETER Groups
System.String[] Array of user groups
.PARAMETER Computer
System.String computer name which to query for group users
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
.EXAMPLE
Get-GroupSID "USERNAME" -Machine "COMPUTERNAME"
.EXAMPLE
Get-GroupSID @("USERNAME1", "USERNAME2") -CIM
.INPUTS
System.String[] array of group names
.OUTPUTS
Multiple System.String SID's (security identifier)
#>
function Get-GroupSID
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("Group")]
		[Parameter(Mandatory = $true,
		Position = 0,
		ValueFromPipeline = $true)]
		[string[]] $UserGroups,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Group in $UserGroups)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $ComputerName\$Group"

			if ($CIM)
			{
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $ComputerName `
					-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

				# Core: -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetMachine $ComputerName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $ComputerName"

					$GroupSID = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -eq $Group | Select-Object -ExpandProperty SID
				}
				else
				{
					Write-Error -Category ConnectionError -TargetObject $ComputerName `
					-Message "Unable to contact computer: $ComputerName"
					continue
				}
			}
			elseif ($ComputerName -eq [System.Environment]::MachineName)
			{
				$GroupSID = Get-LocalGroup -Name $Group | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
			}
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
				-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if([string]::IsNullOrEmpty($GroupSID))
			{
				Write-Error -TargetObject $Group -Message "User group '$Group' cannot be resolved to a SID."
			}
			else
			{
				Write-Output -InputObject $GroupSID
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

<#
.SYNOPSIS
Get SID for giver computer account
.PARAMETER Users
System.String[] array of user accounts
.PARAMETER Computer
Target computer on which to perform query
.PARAMETER CIM
Whether to contact CIM server (requred for remote computers)
.EXAMPLE
Get-AccountSID "USERNAME" -Server "COMPUTERNAME"
.EXAMPLE
Get-AccountSID @("USERNAME1", "USERNAME2") -CIM
.INPUTS
System.String[] array of user accounts
.OUTPUTS
Multiple System.String SID's (security identifier)
.NOTES
TODO: USER MODE DRIVERS SID not found
#>
function Get-AccountSID
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true,
		Position = 0,
		ValueFromPipeline = $true)]
		[string[]] $UserNames,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $CIM
	)

	begin
	{
		$PowerShellEdition = $PSVersionTable.PSEdition
		[bool] $SpecialDomain = ![System.String]::IsNullOrEmpty(
			[array]::Find($SpecialDomains, [System.Predicate[string]]{ $ComputerName -eq "$($args[0])" }))
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($User in $UserNames)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $ComputerName\$User"

			# TODO: should we query system accounts remotely?
			if ($CIM -and !$SpecialDomain)
			{
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $ComputerName `
					-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

				# Core: -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetMachine $ComputerName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying CIM server on $ComputerName"

					$AccountSID = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -eq $User | Select-Object -ExpandProperty SID
				}
				else
				{
					Write-Error -Category ConnectionError -TargetObject $ComputerName `
					-Message "Unable to contact computer: $ComputerName"
					return
				}
			}
			elseif ($ComputerName -eq [System.Environment]::MachineName -or $SpecialDomain)
			{
				if ($CIM)
				{
					Write-Warning -Message "-CIM switch ignored for $ComputerName"
				}

				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $ComputerName\$User"

					$NTAccount = New-Object System.Security.Principal.NTAccount($ComputerName, $User)
					$AccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
				}
				catch
				{
					Write-Error -TargetObject $_.TargetObject -Message "[$($MyInvocation.InvocationName)] Account '$ComputerName\$User' cannot be resolved to a SID"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
				-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if([string]::IsNullOrEmpty($AccountSID))
			{
				Write-Error -TargetObject $AccountSID -Message "Account '$ComputerName\$User' cannot be resolved to a SID"
			}
			else
			{
				Write-Output -InputObject $AccountSID
			}
		} # foreach ($Group in $UserGroups)
	} # process
}

#
# Module variables
#

# Must be before constants
New-Variable -Name SpecialDomains -Scope Script -Option Constant -Value @(
	"NT AUTHORITY"
	"APPLICATION_PACKAGE_AUTHORITY"
	)

# TODO: global configuration variables (in a separate script) should also include to set "USERS" instead of single user
if (!(Get-Variable -Name CheckInitUserInfo -Scope Global -ErrorAction Ignore))
{
	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckInitUserInfo -Scope Global -Option Constant -Value $null

	# TODO: should not be used
	# Generate SDDL string for most common groups
	New-Variable -Name UsersGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Users" -Computer $PolicyStore)
	New-Variable -Name AdministratorsGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Administrators" -Computer $PolicyStore)

	# TODO: replace with function calls
	# Generate SDDL string for most common system users
	New-Variable -Name NT_AUTHORITY_System -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-18)"
	New-Variable -Name NT_AUTHORITY_LocalService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-19)"
	New-Variable -Name NT_AUTHORITY_NetworkService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-20)"
	New-Variable -Name NT_AUTHORITY_UserModeDrivers -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
}

# Get list of user accounts in form of COMPUTERNAME\USERNAME
# New-Variable -Name UserAccounts -Scope Script -Option Constant -Value (Get-GroupUsers "Users" -Computer $PolicyStore)
# New-Variable -Name AdminAccounts -Scope Script -Option Constant -Value (Get-GroupUsers "Administrators" -Computer $PolicyStore)

#
# Function exports
#

Export-ModuleMember -Function ConvertFrom-UserAccounts
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function ConvertFrom-SID
Export-ModuleMember -Function Get-GroupUsers
Export-ModuleMember -Function Get-GroupSID
Export-ModuleMember -Function Get-SDDL
Export-ModuleMember -Function Merge-SDDL
Export-ModuleMember -Function Get-UserGroups

#
# Variable exports
#
Export-ModuleMember -Variable CheckInitUserInfo

# Export-ModuleMember -Variable UserAccounts
# Export-ModuleMember -Variable AdminAccounts
Export-ModuleMember -Variable UsersGroupSDDL
Export-ModuleMember -Variable AdministratorsGroupSDDL

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


<# naming convention for common variables, parameters and aliases
type variable, parameter, alias - type[] ArrayVariable, ArrayParameters, alias

UserName / UserNames
UserGroup / UserGroups / Group
UserAccount / UserAccounts / Account

GroupUser / GroupUsers

ComputerName / ComputerNames / Computer, Server, Machine, Host


AccountSID / AccountsSID
GroupSID / GroupsSID

AccountSDDL/ AccountsSDDL
GroupSDDL / GroupsSDDL


SHOULD NOT BE USED:

UserSID / UsersSID
UserSDDL / UsersSDDL

FOR GLOBAL/SCRIPT VARIABLES:
<group_name>GroupSDDL
<user_account>AccountSDDL

SHOULD NOT BE USED IN GLOBAL/SCRIPT scopes
<user_name>UserSID
#>
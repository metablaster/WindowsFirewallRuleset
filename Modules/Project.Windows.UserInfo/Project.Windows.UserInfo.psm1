
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
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true

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

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}
else
{
	# Everything is default except InformationPreference should be enabled
	$InformationPreference = "Continue"
}

# TODO: get a user account that is connected to a Microsoft account. see Get-LocalUser docs.

<#
.SYNOPSIS
Strip computer names out of computer accounts
.DESCRIPTION
ConvertFrom-UserAccount is a helper method to reduce typing common code
related to splitting up user accounts
.PARAMETER UserAccounts
Array of user accounts in form of: COMPUTERNAME\USERNAME
.EXAMPLE
ConvertFrom-UserAccounts COMPUTERNAME\USERNAME
.EXAMPLE
ConvertFrom-UserAccounts SERVER\USER, COMPUTER\USER, SERVER2\USER2
.INPUTS
None. You cannot pipe objects to ConvertFrom-UserAccounts
.OUTPUTS
[string[]] array of usernames in form of: USERNAME
.NOTES
None.
#>
function ConvertFrom-UserAccount
{
	[OutputType([System.String[]])]
	[CmdletBinding()]
	param(
		[Alias("Account")]
		[Parameter(Mandatory = $true)]
		[string[]] $UserAccounts
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string[]] $UserNames = @()
	foreach ($Account in $UserAccounts)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting user name for account: $Account"
		$UserNames += $Account.split("\")[1]
	}

	return $UserNames
}

<#
.SYNOPSIS
Get computer accounts for a given user groups on given computers
.PARAMETER UserGroups
User group on local or remote computer
.PARAMETER ComputerNames
One or more computers which to query for group users
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
Get-GroupPrincipal "Users", "Administrators"
.EXAMPLE
Get-GroupPrincipal "Users" -Machine @(DESKTOP, LAPTOP) -CIM
.INPUTS
[string[]] User groups
.OUTPUTS
[PSCustomObject[]] Array of enabled user accounts in specified group
.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: Switch is needed to list all accounts instead of only enabled
TODO: should we handle NT AUTHORITY, BUILTIN and similar?
#>
function Get-GroupPrincipal
{
	[OutputType([PSCustomObject[]])]
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
		[PSCustomObject[]] $UserAccounts = @()
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
				if (Test-TargetComputer $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					foreach ($Group in $UserGroups)
					{
						# Get all users that belong to requested group,
						# this includes non local principal source and non 'user' users
						# it is also missing SID
						$GroupUsers = Get-CimInstance -Class Win32_GroupUser -Namespace "root\cimv2" -ComputerName $Computer |
						Where-Object { $_.GroupComponent.Name -eq $Group } |
						Select-Object -ExpandProperty PartComponent |
						Select-Object -ExpandProperty Name

						# Get only enabled users, these include SID but also non group users
						$EnabledAccounts = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $Computer -Filter "LocalAccount = True" |
						Where-Object -Property Disabled -NE False |
						Select-Object -Property Name, Caption, SID, Domain

						if ([string]::IsNullOrEmpty($EnabledAccounts))
						{
							Write-Warning -Message "User group '$Group' does not have any accounts on computer: $Computer"
							continue
						}

						# Finally compare these 2 results and assemble group users which are active, also includes SID
						foreach ($Account in $EnabledAccounts)
						{
							if ($GroupUsers -contains $Account.Name)
							{
								Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $Account"

								$UserAccounts += [PSCustomObject]@{
									User = $Account.Name
									Account = $Account.Caption
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
			} # if ($CIM)
			elseif ($Computer -eq [System.Environment]::MachineName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				foreach ($Group in $UserGroups)
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing group: '$Group'"

					# Querying local machine
					$GroupUsers = Get-LocalGroupMember -Group $Group |
					Where-Object { $_.PrincipalSource -eq "Local" -and $_.ObjectClass -eq "User" } |
					Select-Object -Property Name, SID

					if ([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "User group: '$Group' does not have any accounts on computer: $Computer"
						continue
					}

					foreach ($Account in $GroupUsers)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $($Account.Name)"

						$UserAccounts += [PSCustomObject]@{
							User = Split-Path -Path $Account.Name -Leaf
							Account = $Account.Name
							Computer = $Computer
							SID = $Account.SID
						}
					}
				} # foreach ($Group in $UserGroups)
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $Computer `
					-Message "Querying remote computers without CIM switch not implemented"
			}
		} # foreach ($Computer in $ComputerNames)

		Write-Output $UserAccounts
	} # process
}

<#
.SYNOPSIS
Get user groups on target computers
.DESCRIPTION
Get a list of all available user groups on target computers
.PARAMETER ComputerNames
One or more computers which to query for user groups
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
Get-UserGroup "ServerPC"
.EXAMPLE
Get-UserGroup @(DESKTOP, LAPTOP) -CIM
.INPUTS
[string[]] array of computer names
.OUTPUTS
[PSCustomObject[]] array of user groups on target computers
.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
#>
function Get-UserGroup
{
	[OutputType([PSCustomObject[]])]
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
		[PSCustomObject[]] $UserGroups = @()
		$PowerShellEdition = $PSVersionTable.PSEdition
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Computer in $ComputerNames)
		{
			if ($CIM)
			{
				# TODO: should work on windows, see Get-SQLInstance
				if ($PowerShellEdition -ne "Desktop")
				{
					Write-Error -Category InvalidArgument -TargetObject $Computer `
						-Message "Querying computers via CIM server with PowerShell '$PowerShellEdition' not implemented"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Computer"

				# Core: -TimeoutSeconds $ConnectionTimeout -IPv4
				if (Test-TargetComputer $Computer)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $Computer"

					$RemoteGroups = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" -ComputerName $Computer |
					Where-Object -Property LocalAccount -EQ "True"

					foreach ($Group in $RemoteGroups)
					{
						$UserGroups += [PSCustomObject]@{
							Group = $Group.Name
							Caption = $Group.Caption
							Computer = $Computer
							SID = $Group.SID
						}
					}

					if ([string]::IsNullOrEmpty($UserGroups))
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
					$UserGroups += [PSCustomObject]@{
						Group = $Group.Name
						Caption = Join-Path -Path $Computer -ChildPath $Group.Name
						Computer = $Computer
						SID = $Group.SID
					}
				}

				if ([string]::IsNullOrEmpty($UserGroups))
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

		Write-Output $UserGroups
	} # process
}

<#
.SYNOPSIS
Merge 2 SDDL strings into one
.DESCRIPTION
This function helps to merge 2 SDDL strings into one
.PARAMETER RefSDDL
Reference to SDDL into which to merge new SDDL
.PARAMETER NewSDDL
New SDDL string which to merge with reference SDDL
.EXAMPLE
$RefSDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)
$NewSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
Merge-SDDL ([ref] $RefSDDL) $NewSDDL
.INPUTS
None. You cannot pipe objects to Merge-SDDL
.OUTPUTS
None. Referenced SDDL is expanded with new one
.NOTES
TODO: Validate input using regex
TODO: Process an array of SDDL's
TODO: Pipeline input
#>
function Merge-SDDL
{
	[OutputType([System.Void])]
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
.DESCRIPTION
Get SDDL string single or multiple user names and/or user groups on a single target computer
.PARAMETER ComputerName
Single domain or computer such as remote computer name or builtin computer domain
.PARAMETER UserNames
Array of users for which to generate SDDL string
.PARAMETER UserGroups
Array of user groups for which to generate SDDL string
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
[string[]] $Users = "haxor"
[string] $Server = COMPUTERNAME
[string[]] $Groups = "Users", "Administrators"

$UsersSDDL1 = Get-SDDL -User $Users -Group $Groups
$UsersSDDL2 = Get-SDDL -User $Users -Machine $Server
$UsersSDDL3 = Get-SDDL -Group $Groups
.EXAMPLE
$NewSDDL = Get-SDDL -Domain "NT AUTHORITY" -User "System"
.INPUTS
None. You cannot pipe objects to Get-SDDL
.OUTPUTS
[string] SDDL for given accounts or/and group for given domain
.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
#>
function Get-SDDL
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Alias("User")]
		[Parameter(Mandatory = $true, ParameterSetName = "User")]
		[Parameter(Mandatory = $false, ParameterSetName = "Group")]
		[string[]] $UserNames,

		[Alias("Group")]
		[Parameter(Mandatory = $true, ParameterSetName = "Group")]
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

	if ($SDDL.Length -lt 3)
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
.DESCRIPTION
Get SID's for single or multiple user groups on a target computer
.PARAMETER UserGroups
Array of user groups or single group name
.PARAMETER ComputerName
Computer name which to query for group users
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
Get-GroupSID "USERNAME" -Machine "COMPUTERNAME"
.EXAMPLE
Get-GroupSID @("USERNAME1", "USERNAME2") -CIM
.INPUTS
[string[]] array of group names
.OUTPUTS
[string] SID's (security identifiers)
.NOTES
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
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

				if (Test-TargetComputer $ComputerName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $ComputerName"

					$GroupSID = Get-CimInstance -Class Win32_Group -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -EQ $Group | Select-Object -ExpandProperty SID
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
				$GroupSID = Get-LocalGroup -Name $Group |
				Select-Object -ExpandProperty SID |
				Select-Object -ExpandProperty Value
			}
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
					-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($GroupSID))
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
Get SID for giver user account
.DESCRIPTION
Get SID's for single or multiple user names on a target computer
.PARAMETER UserNames
Array of user names
.PARAMETER ComputerName
Target computer on which to perform query
.PARAMETER CIM
Whether to contact CIM server (required for remote computers)
.EXAMPLE
Get-AccountSID "USERNAME" -Server "COMPUTERNAME"
.EXAMPLE
Get-AccountSID @("USERNAME1", "USERNAME2") -CIM
.INPUTS
[string[]] array of user names
.OUTPUTS
[string] SID's (security identifiers)
.NOTES
TODO: USER MODE DRIVERS SID not found
CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
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
			[array]::Find($SpecialDomains, [System.Predicate[string]] { $ComputerName -eq "$($args[0])" }))
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

				if (Test-TargetComputer $ComputerName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying CIM server on $ComputerName"

					$AccountSID = Get-CimInstance -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $ComputerName |
					Where-Object -Property Name -EQ $User | Select-Object -ExpandProperty SID
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

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting SID for account: $ComputerName\$User"

				try
				{
					# For APPLICATION PACKAGE AUTHORITY we need to omit domain name
					# TODO: this should be inside second try/catch to make omission of domain generic
					if ($SpecialDomain -and [array]::Find($SpecialDomains, [System.Predicate[string]] { "APPLICATION PACKAGE AUTHORITY" -eq "$($args[0])" }))
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($User)
						$AccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
					else
					{
						$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($ComputerName, $User)
						$AccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString()
					}
				}
				catch
				{
					Write-Error -TargetObject $_.TargetObject -Message "[$($MyInvocation.InvocationName)] Account '$ComputerName\$User' cannot be resolved to a SID`n $_.Exception"
					continue
				}
			} # if ($CIM)
			else
			{
				Write-Error -Category NotImplemented -TargetObject $ComputerName `
					-Message "Querying remote computers without CIM switch not implemented"
				return
			} # if ($CIM)

			if ([string]::IsNullOrEmpty($AccountSID))
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

<#
.SYNOPSIS
Convert SID to user or computer account name
.DESCRIPTION
Convert SID to user or computer account name, in case of pseudo and built in accounts
only relevant login name is returned, not full reference name.
In all other cases result if full account name in form of COMPUTERNAME\USERNAME
.PARAMETER SID
One or more SIDs to convert
.PARAMETER ComputerNames
One or more computers to check if SID is not known, default is localhost
.EXAMPLE
ConvertFrom-SID S-1-5-21-2139171146-395215898-1246945465-2359
.EXAMPLE
'^S-1-5-32-580' | ConvertFrom-SID
.INPUTS
[string[]] One or multiple SID's
.OUTPUTS
[PSCustomObject[]] composed of SID information
.NOTES
SID conversion for well known SIDs and display names from following links:
1. http://support.microsoft.com/kb/243330
2. https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
3. https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers

To avoid confusion pseudo accounts ("Local Service" in below example) can be represented as:
1. SID (S-1-5-19)
2. Name (NT AUTHORITY)
3. Reference Name (NT AUTHORITY\Local Service)
4. Display Name (Local Service)

On the other side built in accounts ("Administrator" in below example) can be represented as:
1. SID (S-1-5-21-500)
2. Name (Administrator)
3. Reference Name (BUILTIN\Administrator)
4. Display Name (Administrator)

This is important to understand because MSDN site (links in comment) just says "Name",
but we can't just use given "Name" value to refer to user when defining rules because it's
not valid for multiple reasons such as:
1. there are duplicate names, which SID do you want if "Name" is duplicate?
2. Some "names" are not login usernames or accounts, but we need either username or account
3. Some "names" are NULL, such as capability SID's
See also: https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers

To solve the problem "Name" must be replaced with "Display Name", most "Name" values are OK,
but those which are not are replaced with "Display Name" in below 'WellKnownSIDs' variable.

TODO: Need to implement switch parameters for UPN and NETBIOS name format in addition to display name, see:
https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
TODO: do we need to have consistent output ie. exactly DOMAIN\USER?, see test results,
probably not for pseudo accounts but for built in accounts it makes sense
# TODO: need to implement CIM switch
#>
function ConvertFrom-SID
{
	# TODO: test pipeline with multiple computers and SID's
	[OutputType([PSCustomObject[]])]
	[CmdletBinding(PositionalBinding = $false)]
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidatePattern('^S-1-\d[\d+-]+\d$')]
		[string[]] $SID,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string[]] $ComputerNames = [System.Environment]::MachineName
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[PSCustomObject[]] $Result = @()

		# loop through provided SIDs
		foreach ($InputSID in $SID)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing SID: $InputSID"

			# Assume it's well known SID
			[string] $SidType = "Unknown"

			# Well known SIDs value/name map
			[string] $LoginName = switch -regex ($InputSID)
			{
				# All versions of Windows
				'^S-1-0$' { "Null Authority" }
				'^S-1-0-0$' { "Nobody" }
				'^S-1-1$' { "World Authority" }
				'^S-1-1-0$' { "Everyone" }
				'^S-1-2$' { "Local Authority" }
				'^S-1-2-0$' { "Local" }
				# Windows Server 2008 and later
				'^S-1-2-1$' { "Console Logon" }
				# All versions of Windows
				'^S-1-3$' { "Creator Authority" }
				# All versions of Windows
				'^S-1-3-0$' { "Creator Owner" }
				'^S-1-3-1$' { "Creator Group" }
				# Windows Server 2003 and later
				'^S-1-3-2$' { "Creator Owner Server" }
				'^S-1-3-3$' { "Creator Group Server" }
				# All versions of Windows
				'^S-1-3-4$' { "Owner Rights" }
				# All versions of Windows
				'^S-1-4$' { "Non-unique Authority" }
				'^S-1-5$' { "NT Authority" } # NOTE: An identifier authority.
				# All versions of Windows
				'^S-1-5-1$' { "Dialup" }
				'^S-1-5-2$' { "Network" }
				'^S-1-5-3$' { "Batch" }
				'^S-1-5-4$' { "Interactive" }
				# TODO: A logon session. The X and Y values for these SIDs are different for each session.
				# S-1-5-5-X-Y
				'^S-1-5-6$' { "Service" }
				'^S-1-5-7$' { "Anonymous" }
				# Windows Server 2003 and later
				'^S-1-5-8$' { "Proxy" }
				# All versions of Windows
				'^S-1-5-9$' { "Enterprise Domain Controllers" }
				'^S-1-5-10$' { "Principal Self" }
				'^S-1-5-11$' { "Authenticated Users" }
				'^S-1-5-12$' { "Restricted Code" }
				'^S-1-5-13$' { "Terminal Server Users" }
				'^S-1-5-14$' { "Remote Interactive Logon" }
				# Windows Server 2003 and later
				# TODO: "This Organization" duplicate
				# NOTE: A group that includes all users from the same organization.
				'^S-1-5-15$' { "This Organization" }
				# All versions of Windows
				# NOTE: An account that is used by the default Internet Information Services (IIS) user.
				'^S-1-5-17$' { "This Organization" } # TODO: IUSR passes
				'^S-1-5-18$' { "System" } # Changed from "Local System"
				'^S-1-5-19$' { "Local Service" } # Changed from "NT Authority"
				'^S-1-5-20$' { "Network Service" } # Changed from "NT Authority"
				# TODO: Unknown system and name
				'^S-1-5-33$' { "WRITE_RESTRICTED_CODE" }
				'^S-1-18-1$' { "AUTHENTICATION_AUTHORITY_ASSERTED_IDENTITY" }
				'^S-1-18-2$' { "SERVICE_ASSERTED_IDENTITY" }
				'^S-1-18-3$' { "FRESH_PUBLIC_KEY_IDENTITY" }
				'^S-1-18-4$' { "KEY_TRUST_IDENTITY" }
				'^S-1-18-5$' { "KEY_PROPERTY_MFA" }
				'^S-1-18-6$' { "KEY_PROPERTY_ATTESTATION" }
				# All versions of Windows
				# NOTE: SID's in form of S-1-5-21-domain-xxx are "Domain" accounts/groups
				# The <root-domain>, <domain> and <machine> identifiers all represent the three sub-authority values
				'^S-1-5-21-\d+-\d+-\d+-500$' { "Administrator" }
				'^S-1-5-21-\d+-\d+-\d+-501$' { "Guest" }
				'^S-1-5-21-\d+-\d+-\d+-502$' { "KRBTGT" }
				'^S-1-5-21-\d+-\d+-\d+-512$' { "Domain Admins" }
				'^S-1-5-21-\d+-\d+-\d+-513$' { "Domain Users" }
				'^S-1-5-21-\d+-\d+-\d+-514$' { "Domain Guests" }
				'^S-1-5-21-\d+-\d+-\d+-515$' { "Domain Computers" }
				'^S-1-5-21-\d+-\d+-\d+-516$' { "Domain Controllers" }
				'^S-1-5-21-\d+-\d+-\d+-517$' { "Cert Publishers" }
				'^S-1-5-21-\d+-\d+-\d+-518$' { "Schema Admins" }
				'^S-1-5-21-\d+-\d+-\d+-519$' { "Enterprise Admins" }
				'^S-1-5-21-\d+-\d+-\d+-520$' { "Group Policy Creator Owners" }
				'^S-1-5-21-\d+-\d+-\d+-526$' { "Key Admins" }
				'^S-1-5-21-\d+-\d+-\d+-527$' { "Enterprise Key Admins" }
				'^S-1-5-21-\d+-\d+-\d+-553$' { "RAS and IAS Servers" }
				# Domains - Windows Server 2008 and later
				'^S-1-5-21-\d+-\d+-\d+-498$' { "Enterprise Read-only Domain Controllers" }
				'^S-1-5-21-\d+-\d+-\d+-521$' { "Read-only Domain Controllers" }
				'^S-1-5-21-\d+-\d+-\d+-571$' { "Allowed RODC Password Replication Group" }
				'^S-1-5-21-\d+-\d+-\d+-572$' { "Denied RODC Password Replication Group" }
				# Windows Server 2012 and later
				'^S-1-5-21-\d+-\d+-\d+-522$' { "Cloneable Domain Controllers" }
				# TODO: Unknown system and name
				'^S-1-5-21-\d+-\d+-\d+-525$' { "PROTECTED_USERS" }
				# All versions of Windows
				# NOTE: SID's that start with S-1-5-32 are BUILTIN\
				'^S-1-5-32-544$' { "Administrators" }
				'^S-1-5-32-545$' { "Users" }
				'^S-1-5-32-546$' { "Guests" }
				'^S-1-5-32-547$' { "Power Users" }
				'^S-1-5-32-548$' { "Account Operators" }
				'^S-1-5-32-549$' { "Server Operators" }
				'^S-1-5-32-550$' { "Print Operators" }
				'^S-1-5-32-551$' { "Backup Operators" }
				'^S-1-5-32-552$' { "Replicators" }
				'^S-1-5-32-582$' { "Storage Replica Administrators" }
				# Windows Server 2003 and later
				# From all of the below 5-32 accounts the "BUILTIN\" was removed
				'^S-1-5-32-554$' { "Pre-Windows 2000 Compatible Access" }
				'^S-1-5-32-555$' { "Remote Desktop Users" }
				'^S-1-5-32-556$' { "Network Configuration Operators" }
				'^S-1-5-32-557$' { "Incoming Forest Trust Builders" }
				'^S-1-5-32-558$' { "Performance Monitor Users" }
				'^S-1-5-32-559$' { "Performance Log Users" }
				'^S-1-5-32-560$' { "Windows Authorization Access Group" }
				'^S-1-5-32-561$' { "Terminal Server License Servers" }
				'^S-1-5-32-562$' { "Distributed COM Users" }
				# Windows Server 2008 and later
				'^S-1-5-32-569$' { "Cryptographic Operators" }
				'^S-1-5-32-573$' { "Event Log Readers" }
				'^S-1-5-32-574$' { "Certificate Service DCOM Access" }
				# Windows Server 2012 and later
				'^S-1-5-32-575$' { "RDS Remote Access Servers" }
				'^S-1-5-32-576$' { "RDS Endpoint Servers" }
				'^S-1-5-32-577$' { "RDS Management Servers" }
				'^S-1-5-32-578$' { "Hyper-V Administrators" }
				'^S-1-5-32-579$' { "Access Control Assistance Operators" }
				'^S-1-5-32-580$' { "Remote Management Users" }
				# TODO: Unknown system and name
				'^S-1-5-32-568$' { "IIS_IUSRS" }
				# All versions of Windows
				'^S-1-5-64-10$' { "NTLM Authentication" }
				'^S-1-5-64-14$' { "SChannel Authentication" }
				'^S-1-5-64-21$' { "Digest Authority" }
				# TODO: Unknown system
				# NOTE: Name learned by testing object search
				'^S-1-5-65-1$' { "This Organization Certificate" } # THIS_ORGANIZATION_CERTIFICATE
				# All versions of Windows
				'^S-1-5-80$' { "NT Service" }
				# Windows Server 2008, Windows Vista and later
				# NOTE: Added in Windows Vista and Windows Server 2008
				'^S-1-5-80-0$' { "All Services" }
				# Windows Server 2008 and later
				'^S-1-5-83-0$' { "Virtual Machines" } # Removed "NT VIRTUAL MACHINE\"
				'^S-1-5-90-0$' { "Windows Manager Group" } # Removed "Windows Manager\""
				# TODO: Unknown system and name
				'^S-1-5-84-0-0-0-0-0$' { "USER_MODE_DRIVERS" }
				'^S-1-5-113$' { "Local account" }
				'^S-1-5-114$' { "Local account and member of Administrators group" }
				'^S-1-5-1000$' { "OTHER_ORGANIZATION" }
				# Windows Server 2008 and later
				'^S-1-16-0$' { "Untrusted Mandatory Level" }
				'^S-1-16-4096$' { "Low Mandatory Level" }
				'^S-1-16-8192$' { "Medium Mandatory Level" }
				'^S-1-16-8448$' { "Medium Plus Mandatory Level" }
				'^S-1-16-12288$' { "High Mandatory Level" }
				'^S-1-16-16384$' { "System Mandatory Level" }
				'^S-1-16-20480$' { "Protected Process Mandatory Level" }
				'^S-1-16-28672$' { "Secure Process Mandatory Level" }
				# TODO: Unknown system and name
				'^S-1-5-21-0-0-0-496$' { "COMPOUNDED_AUTHENTICATION" }
				'^S-1-5-21-0-0-0-497$' { "CLAIMS_VALID" }
				# Following SID is for application packages from second link
				'^S-1-15-2-1$' { "All Application Packages" } # APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES
				# Following SID is for application packages that is not listed on well known SID's
				'^S-1-15-2-2$' { "All Restricted Application Packages" } # APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES
				# TODO: Following is a list for store apps from firewall GUI
				# APPLICATION PACKAGE AUTHORITY\Your Internet connection
				# APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections
				# APPLICATION PACKAGE AUTHORITY\Your home or work networks
				# APPLICATION PACKAGE AUTHORITY\Your pictures library
				# APPLICATION PACKAGE AUTHORITY\Your music library
				# APPLICATION PACKAGE AUTHORITY\Your videos library
				# APPLICATION PACKAGE AUTHORITY\Your documents library
				# APPLICATION PACKAGE AUTHORITY\Your Windows credentials
				# APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card
				# APPLICATION PACKAGE AUTHORITY\Removable storage
				# TODO: More capability categories must exist (not listed on well known SID's list), see also:
				# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SecurityManager\CapabilityClasses\AllCachedCapabilities\capabilityClass_*
				# TODO: following SID's are not listed on well known SID list, verification needed:
				# TrustedInstaller
				# '^S-1-5-22' = "Enterprise Read-Only Domain Controllers Beta"
				default
				{
					[string] $ResultName = ""

					switch -regex ($InputSID)
					{
						'^S-1-15-2-\d+-\d+-\d+-\d+-\d+-\d+-\d+$'
						{
							$SidType = "Store App"

							# Check SID on all target computers until match
							# TODO: could this result is incomplete information if multiple computers match?
							:computer foreach ($Computer in $ComputerNames)
							{
								if (!(Test-TargetComputer $Computer))
								{
									Write-Error -Category ConnectionError -TargetObject $Computer -Message "Unable to contact computer: '$Computer'"
									continue
								}

								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking store app SID on computer: '$Computer'"

								# Find to which store app this SID belongs
								$Groups = Get-UserGroup -ComputerNames $Computer | Select-Object -ExpandProperty Group
								# NOTE: ignore warnings to reduce spam
								$Users = Get-GroupPrincipal -ComputerNames $Computer -UserGroups $Groups -WA SilentlyContinue |
								Select-Object -ExpandProperty User

								foreach ($User in $Users)
								{
									Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing username: '$User'"

									# TODO: instead of many for loops probably create hash table or array for match
									$StoreApps = Get-UserApps -ComputerName $Computer -UserName $User
									$StoreApps += Get-SystemApps -ComputerName $Computer

									foreach ($App in $StoreApps)
									{
										Write-Debug -Message "Processing app: '$App'"

										# TODO: Get-AppSID should retrieve remote computer information see implementation
										# NOTE: ignore warnings and info to reduce spam
										if ($(Get-AppSID -UserName $User -AppName $App.PackageFamilyName -WA SilentlyContinue -INFA SilentlyContinue) -eq $InputSID)
										{
											$ResultName = $App.Name
											# TODO: we probably also need to save target computer where this SID is valid
											Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is known store app SID for computer: '$Computer'"
											break computer
										}
									}
								}

								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is unknown store app SID for computer: '$Computer'"
							} # foreach computer

							if ([System.String]::IsNullOrEmpty($ResultName))
							{
								Write-Warning -Message "Input SID is unknown store app SID"
							}
						}
						'^S-1-15-3-\d+[\d+-]\d+$'
						{
							$SidType = "Capability"
							Write-Warning -Message "Translating capability SID's not implemented"

							# TODO: Display what capability SID has, for more info look into registry and see:
							# https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers#capability-sids
							Write-Warning -Message "Input SID: '$InputSID' is capability SID"
						}
						default
						{
							# Check SID on all target computers until match
							# TODO: could this result is incomplete information if multiple computers match?
							:computer foreach ($Computer in $ComputerNames)
							{
								if (!(Test-TargetComputer $Computer))
								{
									Write-Error -Category ConnectionError -TargetObject $Computer -Message "Unable to contact computer: '$Computer'"
									continue
								}

								try # to translate the SID to an account on target computer
								{
									Write-Verbose -Message "[$($MyInvocation.InvocationName)] Translating SID on computer: '$Computer'"

									# TODO: this needs remote execution
									$ObjectSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier($InputSID)
									$ResultName = $ObjectSID.Translate([System.Security.Principal.NTAccount]).Value

									# NTAccount represents a user or group account
									$SidType = "NTAccount"
									Write-Verbose -Message "[$($MyInvocation.InvocationName)] Computer: '$Computer' recognizes input SID as NTAccount SID"
									break computer
								}
								catch
								{
									Write-Verbose -Message "[$($MyInvocation.InvocationName)] Computer: '$Computer' does not recognize SID: '$SID'"
								}
							} # foreach computer

							if ([System.String]::IsNullOrEmpty($ResultName))
							{
								if ($InputSID -match '^S-1-5-21-\d+-\d+-\d+-\d+$')
								{
									$SidType = "Domain"
									Write-Warning -Message "Input SID is unknown domain or NTAccount SID"
								}
								else
								{
									$SidType = "Unknown"
									# TODO: check if invalid format or just not found
									# NOTE: regex matches do not check length of a SID which could help identify problem
									Write-Warning -Message "$InputSID is not a valid SID or could not be identified"
								}
							}
						} # default
					} # switch unknown

					# If not found, at least maybe SID type was learned
					$ResultName
				} # default
			} # switch well known

			# Finally figure out the type of a SID for well known SID, done here to avoid code bloat
			# TODO: there are more categorizations
			if ((![System.String]::IsNullOrEmpty($LoginName)) -and ($SidType -eq "Unknown"))
			{
				# Check if well known SID is domain SID
				if ($InputSID -match '^S-1-5-21')
				{
					$SidType = "Well Known Domain"
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is well known domain SID"
				}
				elseif ($InputSID -match '^S-1-15-2-[1-2]$')
				{
					$SidType = "Package Authority"
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is package authority SID"
				}
				else
				{
					$SidType = "Well known"
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is well known SID"
				}
			}

			# Add to result object
			# TODO: we should also save system edition, authority, domain etc.
			$Result += [PSCustomObject]@{
				Type = $SidType
				Name = $LoginName
				SID = $InputSID
			}
		} # foreach SID

		Write-Output $Result
	} # process
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initialize module constant variable: SpecialDomains"
# Must be before constants
# TODO: there must be a better more conventional name for this
# TODO: We need to handle more cases, these 3 are known to work for now
New-Variable -Name SpecialDomains -Scope Script -Option Constant -Value @(
	"NT AUTHORITY"
	"APPLICATION PACKAGE AUTHORITY"
	"BUILTIN"
)

# TODO: global configuration variables (in a separate script)?
if (!(Get-Variable -Name CheckInitUserInfo -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: CheckInitUserInfo"
	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUserInfo -Scope Global -Option Constant -Value $null

	# TODO: should not be used
	# Generate SDDL string for most common groups
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: UsersGroupSDDL"
	New-Variable -Name UsersGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Users" -Computer $PolicyStore)
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: AdministratorsGroupSDDL"
	New-Variable -Name AdministratorsGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Administrators" -Computer $PolicyStore)

	# TODO: replace with function calls
	# Generate SDDL string for most common system users
	Write-Debug -Message "[$ThisModule] Initialize global constant variables: NT AUTHORITY\..."
	New-Variable -Name NT_AUTHORITY_System -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-18)"
	New-Variable -Name NT_AUTHORITY_LocalService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-19)"
	New-Variable -Name NT_AUTHORITY_NetworkService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-20)"
	New-Variable -Name NT_AUTHORITY_UserModeDrivers -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
}

#
# Function exports
#

Export-ModuleMember -Function ConvertFrom-UserAccount
Export-ModuleMember -Function Get-AccountSID
Export-ModuleMember -Function Get-GroupPrincipal
Export-ModuleMember -Function Get-GroupSID
Export-ModuleMember -Function Get-SDDL
Export-ModuleMember -Function Merge-SDDL
Export-ModuleMember -Function Get-UserGroup

#
# External function exports
#

Export-ModuleMember -Function ConvertFrom-SID

#
# Variable exports
#

Export-ModuleMember -Variable CheckInitUserInfo

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
# $NT_AUTHORITY_EnterpriseDomainControllers = "D:(A;;CC;;;S-1-5-9)"
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
# $NT_AUTHORITY_EnterpriseReadOnlyDomainControllersBeta = "D:(A;;CC;;;S-1-5-22)"
# "D:(A;;CC;;;S-1-5-23)" # Unknown

# Application packages
# $APPLICATION_PACKAGE_AUTHORITY_AllApplicationPackages = "D:(A;;CC;;;S-1-15-2-1)"
# $APPLICATION_PACKAGE_AUTHORITY_AllRestrictedApplicationPackages = "D:(A;;CC;;;S-1-15-2-2)"
# "D:(A;;CC;;;S-1-15-2-3)" # Unknown

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

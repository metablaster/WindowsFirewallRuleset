
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2016 Warren Frame
Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Convert SID to user or computer account name
.DESCRIPTION
Convert SID to user or computer account name, in case of pseudo and built in accounts
only relevant login name is returned, not full reference name.
In all other cases result if full account name in form of COMPUTERNAME\USERNAME
.PARAMETER SIDArray
One or more SIDs to convert
.EXAMPLE
ConvertFrom-SID S-1-5-21-2139171146-395215898-1246945465-2359
.EXAMPLE
'S-1-5-32-580' | ConvertFrom-SID
.INPUTS
[string[]] One or multiple SID's
.OUTPUTS
PSObject composed of SID and user or account
.NOTES
SID conversion for well known SIDs from http://support.microsoft.com/kb/243330
Original code link: https://github.com/RamblingCookieMonster/PowerShell
Added more SID's from https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
Got some display names from https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers

TODO: do we need to have consistent output ie. exactly DOMAIN\USER?, see test results,
probably not for pseudo accounts but for built in accounts it makes sense
TODO: Need to implement switch for UPN name format in addition to NETBIOS, see:
https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats

Changes by metablaster year 2020:
1. add verbose and debug output
2. remove try and empty catch by setting better approach
3. rename parameter
4. format code style to project defaults and added few more comments
5. removed unnecessary parentheses
6. renamed some well known SID names and added comment why
7. added more SID/name pairs
8. handle capability and store app SID's
#>
function ConvertFrom-SID
{
	# TODO: test pipeline position
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]] $SIDArray,

		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter(ValueFromPipeline = $true)]
		[string[]] $ComputerNames = [System.Environment]::MachineName
	)

	begin
	{
		# Well known SIDs value/name map
		# NOTE: To avoid confusion pseudo accounts ("Local Service" in below example) can be represented as:
		#
		# 1. SID (S-1-5-19)
		# 2. Name (NT AUTHORITY)
		# 3. Reference Name (NT AUTHORITY\Local Service)
		# 4. Display Name (Local Service)
		#
		# NOTE: On the other side built in accounts ("Administrator" in below example) can be represented as:
		#
		# 1. SID (S-1-5-21-500)
		# 2. Name (Administrator)
		# 3. Reference Name (BUILTIN\Administrator)
		# 4. Display Name (Administrator)
		#
		# This is important to understand because MSDN site (link in comment) just says "Name",
		# but we can't just use given "Name" value to refer to user when defining rules because it's
		# not valid for multiple reasons such as:
		# 1. there are duplicate names, which SID do you want if "Name" is duplicate?
		# 2. Some "names" are not login usernames or accounts, but we need either username or account
		# 3. Some "names" are NULL, such as capability SID's
		# See also: https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers
		#
		# To solve the problem "Name" must be replaced with "Display Name", most "Name" values are OK,
		# but those which are not are replaced with "Display Name" in below 'WellKnownSIDs' variable.
		#
		# TODO: script scope variable?
		$WellKnownSIDs = @{
			# All versions of Windows
			'S-1-0' = 'Null Authority'
			'S-1-0-0' = 'Nobody'
			'S-1-1' = 'World Authority'
			'S-1-1-0' = 'Everyone'
			'S-1-2' = 'Local Authority'
			'S-1-2-0' = 'Local'
			# Windows Server 2008 and later
			'S-1-2-1' = 'Console Logon'
			# All versions of Windows
			'S-1-3' = 'Creator Authority'
			# All versions of Windows
			'S-1-3-0' = 'Creator Owner'
			'S-1-3-1' = 'Creator Group'
			# Windows Server 2003 and later
			'S-1-3-2' = 'Creator Owner Server'
			'S-1-3-3' = 'Creator Group Server'
			# All versions of Windows
			'S-1-3-4' = 'Owner Rights'
			# All versions of Windows
			'S-1-4' = 'Non-unique Authority'
			'S-1-5' = 'NT Authority' # NOTE: An identifier authority.
			# All versions of Windows
			'S-1-5-1' = 'Dialup'
			'S-1-5-2' = 'Network'
			'S-1-5-3' = 'Batch'
			'S-1-5-4' = 'Interactive'
			# TODO: A logon session. The X and Y values for these SIDs are different for each session.
			# S-1-5-5-X-Y
			'S-1-5-6' = 'Service'
			'S-1-5-7' = 'Anonymous'
			# Windows Server 2003 and later
			'S-1-5-8' = 'Proxy'
			# All versions of Windows
			'S-1-5-9' = 'Enterprise Domain Controllers'
			'S-1-5-10' = 'Principal Self'
			'S-1-5-11' = 'Authenticated Users'
			'S-1-5-12' = 'Restricted Code'
			'S-1-5-13' = 'Terminal Server Users'
			'S-1-5-14' = 'Remote Interactive Logon'
			# Windows Server 2003 and later
			# TODO: "This Organization" duplicate
			# NOTE: A group that includes all users from the same organization.
			'S-1-5-15' = 'This Organization'
			# All versions of Windows
			# NOTE: An account that is used by the default Internet Information Services (IIS) user.
			'S-1-5-17' = 'This Organization' # TODO: IUSR passes
			'S-1-5-18' = 'System' # Changed from "Local System"
			'S-1-5-19' = 'Local Service' # Changed from "NT Authority"
			'S-1-5-20' = 'Network Service' # Changed from "NT Authority"
			# TODO: Unknown system and name
			'S-1-5-33' = 'WRITE_RESTRICTED_CODE'
			'S-1-18-1' = 'AUTHENTICATION_AUTHORITY_ASSERTED_IDENTITY'
			'S-1-18-2' = 'SERVICE_ASSERTED_IDENTITY'
			'S-1-18-3' = 'FRESH_PUBLIC_KEY_IDENTITY'
			'S-1-18-4' = 'KEY_TRUST_IDENTITY'
			'S-1-18-5' = 'KEY_PROPERTY_MFA'
			'S-1-18-6' = 'KEY_PROPERTY_ATTESTATION'
			# All versions of Windows
			# NOTE: SID's in form of S-1-5-21-domain-xxx are "Domain" accounts/groups
			'S-1-5-21-500' = 'Administrator'
			'S-1-5-21-501' = 'Guest'
			'S-1-5-21-502' = 'KRBTGT'
			'S-1-5-21-512' = 'Domain Admins'
			'S-1-5-21-513' = 'Domain Users'
			'S-1-5-21-514' = 'Domain Guests'
			'S-1-5-21-515' = 'Domain Computers'
			'S-1-5-21-516' = 'Domain Controllers'
			'S-1-5-21-517' = 'Cert Publishers'
			'S-1-5-21-518' = 'Schema Admins'
			'S-1-5-21-519' = 'Enterprise Admins'
			'S-1-5-21-520' = 'Group Policy Creator Owners'
			'S-1-5-21-526' = 'Key Admins'
			'S-1-5-21-527' = 'Enterprise Key Admins'
			'S-1-5-21-553' = 'RAS and IAS Servers'
			# Domains - Windows Server 2008 and later
			'S-1-5-21-498' = 'Enterprise Read-only Domain Controllers'
			'S-1-5-21-521' = 'Read-only Domain Controllers'
			'S-1-5-21-571' = 'Allowed RODC Password Replication Group'
			'S-1-5-21-572' = 'Denied RODC Password Replication Group'
			# Windows Server 2012 and later
			'S-1-5-21-522' = 'Cloneable Domain Controllers'
			# TODO: Unknown system and name
			'S-1-5-21-525' = 'PROTECTED_USERS'
			# All versions of Windows
			# NOTE: SID's that start with S-1-5-32 are BUILTIN\
			'S-1-5-32-544' = 'Administrators'
			'S-1-5-32-545' = 'Users'
			'S-1-5-32-546' = 'Guests'
			'S-1-5-32-547' = 'Power Users'
			'S-1-5-32-548' = 'Account Operators'
			'S-1-5-32-549' = 'Server Operators'
			'S-1-5-32-550' = 'Print Operators'
			'S-1-5-32-551' = 'Backup Operators'
			'S-1-5-32-552' = 'Replicators'
			'S-1-5-32-582' = 'Storage Replica Administrators'
			# Windows Server 2003 and later
			# From all of the below 5-32 accounts the "BUILTIN\" was removed
			'S-1-5-32-554' = 'Pre-Windows 2000 Compatible Access'
			'S-1-5-32-555' = 'Remote Desktop Users'
			'S-1-5-32-556' = 'Network Configuration Operators'
			'S-1-5-32-557' = 'Incoming Forest Trust Builders'
			'S-1-5-32-558' = 'Performance Monitor Users'
			'S-1-5-32-559' = 'Performance Log Users'
			'S-1-5-32-560' = 'Windows Authorization Access Group'
			'S-1-5-32-561' = 'Terminal Server License Servers'
			'S-1-5-32-562' = 'Distributed COM Users'
			# Windows Server 2008 and later
			'S-1-5-32-569' = 'Cryptographic Operators'
			'S-1-5-32-573' = 'Event Log Readers'
			'S-1-5-32-574' = 'Certificate Service DCOM Access'
			# Windows Server 2012 and later
			'S-1-5-32-575' = 'RDS Remote Access Servers'
			'S-1-5-32-576' = 'RDS Endpoint Servers'
			'S-1-5-32-577' = 'RDS Management Servers'
			'S-1-5-32-578' = 'Hyper-V Administrators'
			'S-1-5-32-579' = 'Access Control Assistance Operators'
			'S-1-5-32-580' = 'Remote Management Users'
			# TODO: Unknown system and name
			'S-1-5-32-568' = 'IIS_IUSRS'
			# All versions of Windows
			'S-1-5-64-10' = 'NTLM Authentication'
			'S-1-5-64-14' = 'SChannel Authentication'
			'S-1-5-64-21' = 'Digest Authority'
			# TODO: Unknown system
			# NOTE: Name learned by testing object search
			'S-1-5-65-1' = 'This Organization Certificate' # THIS_ORGANIZATION_CERTIFICATE
			# All versions of Windows
			'S-1-5-80' = 'NT Service'
			# Windows Server 2008, Windows Vista and later
			# NOTE: Added in Windows Vista and Windows Server 2008
			'S-1-5-80-0' = 'All Services'
			# Windows Server 2008 and later
			'S-1-5-83-0' = 'Virtual Machines' # Removed "NT VIRTUAL MACHINE\"
			'S-1-5-90-0' = 'Windows Manager Group' # Removed "Windows Manager\""
			# TODO: Unknown system and name
			'S-1-5-84-0-0-0-0-0' = 'USER_MODE_DRIVERS'
			'S-1-5-113' = 'Local account'
			'S-1-5-114' = 'Local account and member of Administrators group'
			'S-1-5-1000' = 'OTHER_ORGANIZATION'
			# Windows Server 2008 and later
			'S-1-16-0' = 'Untrusted Mandatory Level'
			'S-1-16-4096' = 'Low Mandatory Level'
			'S-1-16-8192' = 'Medium Mandatory Level'
			'S-1-16-8448' = 'Medium Plus Mandatory Level'
			'S-1-16-12288' = 'High Mandatory Level'
			'S-1-16-16384' = 'System Mandatory Level'
			'S-1-16-20480' = 'Protected Process Mandatory Level'
			'S-1-16-28672' = 'Secure Process Mandatory Level'
			# TODO: Unknown system and name
			'S-1-5-21-0-0-0-496' = 'COMPOUNDED_AUTHENTICATION'
			'S-1-5-21-0-0-0-497' = 'CLAIMS_VALID'
			# Following SID is for application packages from second link
			'S-1-15-2-1' = 'All Application Packages' # APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES
			# Following SID is for application packages that is not listed on well known SID's
			'S-1-15-2-2' = 'All Restricted Application Packages' # APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES
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
			# 'S-1-5-22' = "Enterprise Read-Only Domain Controllers Beta"
		}
	}

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		[PSCustomObject[]] $Result = @()
		# loop through provided SIDs
		foreach ($SID in $SIDArray)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing: $SID"

			# Make a copy since modified SID may not be used
			$FullSID = $SID

			# Store SID type as part of result
			[string] $SidType = "Unknown"

			# Check for domain contextual SID's
			$IsDomain = $false

			# Check if SID represents store app authority SID
			$IsPackageAuthority = $false

			# Check if SID represent store app
			$IsStoreApp = $false

			# Check if SID is Capability SID
			$IsCapability = $false

			# The count of characters
			if ($SID.Length -gt 8)
			{
				# New string keeping only first 8 characters
				if ($SID.Remove(8) -eq "S-1-5-21")
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is domain SID"

					$IsDomain = $true
					$SidType = "WellKnown"

					# The substring starts at a specified character position and continues to the end of the string.
					$Suffix = $SID.Substring($SID.Length - 4) # ie. 1003

					# Get rid of 'domain' number, keep only SID value and suffix, this is done
					# to search WellKnownSIDs variable with array[] operator
					$SID = $SID.Remove(8) + $Suffix
				}
				elseif ($SID.Length -eq 10 -and (($SID -eq "S-1-15-2-1") -or ($SID -eq "S-1-15-2-2")))
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is APPLICATION PACKAGE AUTHORITY"

					$SidType = "StoreApp"
					$IsPackageAuthority = $true
				}
				elseif (($SID.Length -gt 20) -and ($SID.Remove(9) -eq "S-1-15-2-"))
				{
					# TODO: need exact length of store app SID's
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is store app SID"

					$SidType = "StoreApp"
					$IsStoreApp = $true
				}
				elseif (($SID.Length -gt 9) -and ($SID.Remove(9) -eq "S-1-15-3-"))
				{
					# TODO: Display what capability SID has, for more info look into registry and see:
					# https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers#capability-sids
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is capability SID"

					$SidType = "Capability"
					$IsCapability = $true
				}
				else
				{
					# In all other cases the FullSID is either on the list of well known SID's
					# Otherwise it's capability SID or just plain wrong which will fail
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is not domain SID"
				}
			}

			# Map name to well known sid. If this fails, use .NET to get the account
			[string] $Name = $WellKnownSIDs[$SID]

			if ($Name)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is well known SID"
			}
			else
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input SID is not well known SID"

				if ($IsStoreApp)
				{
					# TODO: contact computer, Get-AppSID should retrieve remote computer see implementation
					# Find to which store app this SID belongs
					$Groups = Get-UserGroup -ComputerNames $ComputerNames | Select-Object -ExpandProperty Group
					$Users = Get-GroupPrincipal -ComputerNames $ComputerNames -UserGroups $Groups |
					Select-Object -ExpandProperty User

					# $Name = "INVALID_NAME" # TODO: $null

					:found foreach ($User in $Users)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing username: '$User'"

						$UserApps = Get-UserApps -UserName $User

						foreach ($UserApp in $UserApps)
						{
							Write-Debug -Message "Checking SID match for store app: '$UserApp'"

							if ($(Get-AppSID $User $UserApp.PackageFamilyName) -eq $SID)
							{
								Write-Verbose -Message "SID found for username '$User' and store app: '$($UserApp.Name)'"
								$Name = $UserApp.Name
								break found
							}
						}
					}

					if ([System.String]::IsNullOrEmpty($Name))
					{
						Write-Warning -Message "No known store app has sid: '$SID'"
					}
				}
				elseif ($IsCapability)
				{
					Write-Warning -Message "Capability SID's are nameless: '$SID'"
				}
				elseif ($IsPackageAuthority)
				{
				}
				else
				{
					if ($IsDomain)
					{
						# else it's already FullSID
						$SID = $FullSID
					}

					# try to translate the SID to an account
					try
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Translating SID: $SID"

						# TODO: this may not work for remote computers, needs testing
						$SIDObject = New-Object -TypeName System.Security.Principal.SecurityIdentifier($SID)
						$Name = $SIDObject.Translate([System.Security.Principal.NTAccount]).Value
						$SidType = "NTAccount"
					}
					catch
					{
						Write-Warning -Message "$SID is not a valid SID or could not be identified"
					}
				}
			}

			# Add to results
			$Result += [PSCustomObject]@{
				SidType = $SidType
				Name = $Name
				SID = $FullSID
			}
		}

		return $Result
	}
}

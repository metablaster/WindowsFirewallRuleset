
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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

.PARAMETER SID
One or more SIDs to convert

.PARAMETER ComputerNames
One or more computers to check if SID is not known, default is localhost

.EXAMPLE
PS> ConvertFrom-SID S-1-5-21-2139171146-395215898-1246945465-2359

.EXAMPLE
PS> '^S-1-5-32-580' | ConvertFrom-SID

.INPUTS
[System.String[]] One or multiple SID's

.OUTPUTS
[PSCustomObject[]] composed of SID information

.NOTES
SID conversion for well known SIDs and display names from following links:
1. http://support.microsoft.com/kb/243330
2. https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
3. https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers

To avoid confusion pseudo accounts ("Local Service" in the example below) can be represented as:
1. SID (S-1-5-19)
2. Name (NT AUTHORITY)
3. Reference Name (NT AUTHORITY\Local Service)
4. Display Name (Local Service)

On the other side built in accounts ("Administrator" in the example below) can be represented as:
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
but those which are not are replaced with "Display Name" in the 'WellKnownSIDs' variable below.

TODO: Need to implement switch parameters for UPN and NETBIOS name format in addition to display name, see:
https://docs.microsoft.com/en-us/windows/win32/secauthn/user-name-formats
TODO: do we need to have consistent output ie. exactly DOMAIN\USER?, see test results,
probably not for pseudo accounts but for built in accounts it makes sense
TODO: need to implement CIM switch
#>
function ConvertFrom-SID
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.UserInfo/Help/en-US/ConvertFrom-SID.md")]
	# TODO: test pipeline with multiple computers and SID's
	[OutputType([PSCustomObject[]])]
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
				# NOTE: A logon session. The X and Y values for these SIDs are different for each session.
				# NOTE: X-Y omitted (S-1-5-5-X-Y)
				# TODO: Name not valid, only approximate info given
				'^S-1-5-5-\d+-\d+$' { "UNKNOWN-LOGON-SESSION" }
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
				# NOTE: A group that includes all users from the same organization.
				'^S-1-5-15$' { "This Organization" }
				# All versions of Windows
				# NOTE: An account that is used by the default Internet Information Services (IIS) user.
				'^S-1-5-17$' { "IUSR" } # NT AUTHORITY\IUSR (Name learned with PsGetsid64)
				'^S-1-5-18$' { "System" } # Changed from "Local System"
				'^S-1-5-19$' { "Local Service" } # Changed from "NT Authority"
				'^S-1-5-20$' { "Network Service" } # Changed from "NT Authority"
				# TODO: Unknown system (Names learned with PsGetsid64)
				'^S-1-5-33$' { "WRITE RESTRICTED" } # NT AUTHORITY\WRITE RESTRICTED (WRITE_RESTRICTED_CODE)
				'^S-1-18-1$' { "Authentication authority asserted identity" } # AUTHENTICATION_AUTHORITY_ASSERTED_IDENTITY
				'^S-1-18-2$' { "Service asserted identity" } # SERVICE_ASSERTED_IDENTITY
				'^S-1-18-3$' { "Fresh public key identity" } # FRESH_PUBLIC_KEY_IDENTITY
				'^S-1-18-4$' { "Key trust identity" } # KEY_TRUST_IDENTITY
				'^S-1-18-5$' { "Key property multi-factor authentication" } # KEY_PROPERTY_MFA
				'^S-1-18-6$' { "Key property attestation" } # KEY_PROPERTY_ATTESTATION
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
				# TODO: Unknown system
				'^S-1-5-32-568$' { "IIS_IUSRS" } # Name confirmed with PsGetsid64
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
				# TODO: unknown system for NT SERVICE\TrustedInstaller
				# NOTE: following SID is not listed on well known SID list: (SID confirmed with PsGetsid64)
				# NOTE: for NT SERVICE reference name is required, just display name won't be found
				'^S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464$' { "NT SERVICE\TrustedInstaller" }
				# Windows Server 2008 and later
				'^S-1-5-83-0$' { "Virtual Machines" } # Removed "NT VIRTUAL MACHINE\"
				'^S-1-5-90-0$' { "Windows Manager Group" } # Removed "Windows Manager\""
				# TODO: Unknown system (Name confirmed with PsGetsid64)
				'^S-1-5-84-0-0-0-0-0$' { "USER MODE DRIVERS" } # NT AUTHORITY\USER MODE DRIVERS (USER_MODE_DRIVERS)
				'^S-1-5-113$' { "Local account" } # NT AUTHORITY\Local account
				'^S-1-5-114$' { "Local account and member of Administrators group" } # NT AUTHORITY\Local account and member of Administrators group
				'^S-1-5-1000$' { "Other Organization" } # NT AUTHORITY\Other Organization (OTHER_ORGANIZATION)
				# Windows Server 2008 and later
				'^S-1-16-0$' { "Untrusted Mandatory Level" }
				'^S-1-16-4096$' { "Low Mandatory Level" }
				'^S-1-16-8192$' { "Medium Mandatory Level" }
				'^S-1-16-8448$' { "Medium Plus Mandatory Level" }
				'^S-1-16-12288$' { "High Mandatory Level" }
				'^S-1-16-16384$' { "System Mandatory Level" }
				'^S-1-16-20480$' { "Protected Process Mandatory Level" }
				'^S-1-16-28672$' { "Secure Process Mandatory Level" }
				# TODO: Unknown system (Name confirmed with PsGetsid64)
				'^S-1-5-21-0-0-0-496$' { "Compound Identity Present" } # NT AUTHORITY\Compound Identity Present (COMPOUNDED_AUTHENTICATION)
				'^S-1-5-21-0-0-0-497$' { "Claims Valid" } # NT AUTHORITY\Claims Valid (CLAIMS_VALID)
				# Following SID is for application packages from second link
				'^S-1-15-2-1$' { "All Application Packages" } # APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES
				# Following SID is for application packages that is not listed on well known SID's
				'^S-1-15-2-2$' { "All Restricted Application Packages" } # APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES
				# Following list is mentioned in firewall GUI (SID's learned with PsGetsid64)
				# From all of the below S-1-15-3- accounts the "APPLICATION PACKAGE AUTHORITY\" was removed
				'^S-1-15-3-1$' { "Your Internet connection" }
				'^S-1-15-3-2$' { "Your Internet connection, including incoming connections from the Internet" }
				'^S-1-15-3-3$' { "Your home or work networks" }
				'^S-1-15-3-4$' { "Your pictures library" }
				'^S-1-15-3-5$' { "Your videos library" }
				'^S-1-15-3-6$' { "Your music library" }
				'^S-1-15-3-7$' { "Your documents library" }
				'^S-1-15-3-8$' { "Your Windows credentials" }
				'^S-1-15-3-9$' { "Software and hardware certificates or a smart card" }
				'^S-1-15-3-10$' { "Removable storage" }
				'^S-1-15-3-11$' { "Your Appointments" }
				'^S-1-15-3-12$' { "Your Contacts" }
				# TODO: More capability categories must exist (not listed on well known SID's list), see also:
				# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SecurityManager\CapabilityClasses\AllCachedCapabilities\capabilityClass_*
				# NOTE: following SID is not listed on well known SID list: (Name confirmed with PsGetsid64)
				'^S-1-5-22' { "Enterprise Read-Only Domain Controllers Beta" } # NT AUTHORITY\ENTERPRISE READ-ONLY DOMAIN CONTROLLERS BETA
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

							if ([string]::IsNullOrEmpty($ResultName))
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

							if ([string]::IsNullOrEmpty($ResultName))
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
									# NOTE: regex matches don't check length of a SID which could help identify problem
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
			if ((![string]::IsNullOrEmpty($LoginName)) -and ($SidType -eq "Unknown"))
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

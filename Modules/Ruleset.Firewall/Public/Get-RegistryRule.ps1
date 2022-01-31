
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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

using namespace System.Text.RegularExpressions

<#
.SYNOPSIS
Gets firewall rules directly from registry

.DESCRIPTION
Get-RegistryRule gets firewall rules by drilling registry and parsing registry values.
This method to retrieve rules results is very fast export compared to conventional way.

.PARAMETER Domain
Computer name from which rules are to be retrieved

.PARAMETER Local
Retrive rules from persistent store (control panel firewall)

.PARAMETER GroupPolicy
Retrive rules from local group policy store (GPO firewall)

.PARAMETER DisplayName
Specifies that only matching firewall rules of the indicated display name are retrieved
Wildcard characters are accepted.

.PARAMETER DisplayGroup
Specifies that only matching firewall rules of the indicated group association are retrieved
Wildcard characters are accepted.

.PARAMETER Direction
Specifies that matching firewall rules of the indicated direction are retrieved

.PARAMETER Action
Specifies that matching firewall rules of the indicated action are retrieved

.PARAMETER Enabled
Specifies that matching firewall rules of the indicated state are retrieved

.EXAMPLE
PS> Get-RegistryRule -GroupPolicy

.EXAMPLE
PS> Get-RegistryRule -Action Block -Enabled False

.EXAMPLE
PS> Get-RegistryRule -Direction Outbound -DisplayName "Edge-Chromium HTTPS"

.INPUTS
None. You cannot pipe objects to Get-RegistryRule

.OUTPUTS
[PSCustomObject]

.NOTES
TODO: Getting rules from persistent store (-Local switch) needs testing.
TODO: Design, Parameters -Local and -GroupPolicy must be converted to -PolicyStore? what about -Domain then?
Not implementing more parameters because only those here are always present in registry in all rules.
ParameterSetName = "NotAllowingEmptyString" is there because $DisplayName if not specified casts to
empty string due to [string] declaration, which is the same thing as specifying -DisplayName "",
we deny both with dummy parameter set name and setting default parameter set name to something else.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Get-RegistryRule.md

.LINK
https://stackoverflow.com/questions/53246271/get-netfirewallruleget-netfirewallportfilter-are-too-slow

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpfas/2efe0b76-7b4a-41ff-9050-1023f8196d16

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fasp/8c008258-166d-46d4-9090-f2ffaa01be4b
#>
function Get-RegistryRule
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Ruleset.Firewall/Help/en-US/Get-RegistryRule.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $Local,

		[Parameter()]
		[switch] $GroupPolicy,

		[Parameter(Mandatory = $true, ParameterSetName = "NotAllowingEmptyString")]
		[SupportsWildcards()]
		[string] $DisplayName,

		[Parameter()]
		[SupportsWildcards()]
		[string] $DisplayGroup = "*",

		[Parameter()]
		[ValidateSet("Inbound", "Outbound")]
		[string] $Direction,

		[Parameter()]
		[ValidateSet("Allow", "Block")]
		[string] $Action,

		[Parameter()]
		[ValidateSet("True", "False")]
		[string] $Enabled
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-Computer $Domain)
	{
		# If no switches are set the script defaults to GPO store
		if (!$Local -and !$GroupPolicy) { $GroupPolicy = $true }

		$HKLM = @()
		# NOTE: If group policy firewall is not configured this registry key won't exist
		if ($GroupPolicy) { $HKLM += "Software\Policies\Microsoft\WindowsFirewall\FirewallRules" }
		if ($Local) { $HKLM += "System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" }

		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)
		}
		catch
		{
			if ($RemoteKey)
			{
				$RemoteKey.Dispose()
			}

			Write-Error -ErrorRecord $_
			return
		}

		$ParseAddressKeyword = {
			param ([string] $EntryValue)

			switch ($EntryValue)
			{
				"IntErnet" { "Internet"; break }
				"IntrAnet" { "Intranet"; break }
				"RmtIntrAnet" { "IntranetRemoteAccess"; break }
				"Ply2Renders" { "PlayToDevice"; break }
				default { $EntryValue }
			}
		}

		$ParsePortKeyword = {
			param ([string] $EntryValue)

			switch ($EntryValue)
			{
				"RPC-EPMap" { "RPCEPMap"; break }
				"Ply2Disc" { "PlayToDiscovery"; break }
				# NOTE: "IPTLSOut" and "IPTLSIn" keywords are here for consistency reason, these should be
				# ignored for parsing because keyword is duplicate, it's combined with IPHTTPS(Out\In) keyword
				"IPTLSOut" { "IPHTTPSOut"; break }
				"IPTLSIn" { "IPHTTPSIn"; break }
				default { $EntryValue }
			}
		}

		# Filter out which rules to process
		if (![string]::IsNullOrEmpty($DisplayName))
		{
			$RegexDisplayName = ConvertFrom-Wildcard -Pattern $DisplayName -SkipAnchor
		}

		# Include empty string for rules without display group
		if ([string]::IsNullOrEmpty($DisplayGroup))
		{
			$RegexDisplayGroup = ""
		}
		else
		{
			$RegexDisplayGroup = ConvertFrom-Wildcard -Pattern $DisplayGroup -SkipAnchor
		}

		if (![string]::IsNullOrEmpty($Direction))
		{
			if ($Direction -eq "Outbound") { $RegexDirection = "Out" }
			else { $RegexDirection = "In" }
		}

		if (![string]::IsNullOrEmpty($Action))
		{
			$RegexAction = $Action
		}

		if (![string]::IsNullOrEmpty($Enabled))
		{
			if ($Enabled -eq "True") { $RegexEnabled = "TRUE" }
			else { $RegexEnabled = "FALSE" }
		}

		foreach ($HKLMRootKey in $HKLM)
		{
			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:\$HKLMRootKey"
				$RootKey = $RemoteKey.OpenSubkey($HKLMRootKey, $RegistryPermission, $RegistryRights)

				if (!$RootKey)
				{
					throw [System.Data.ObjectNotFoundException]::new("Following registry key does not exist: $HKLMRootKey")
				}
			}
			catch
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to open registry root key: HKLM:\$HKLMRootKey"
				continue
			}

			# Determine if this is a local or a group policy rule and display this in the hashtable
			if ($HKLMRootKey -match "^System\\CurrentControlSet")
			{
				$PolicyStoreSource = "PersistentStore"
				$PolicyStoreSourceType = "Local"
			}
			else
			{
				$PolicyStoreSource = $Domain
				$PolicyStoreSourceType = "GroupPolicy"
			}

			# Counter for progress
			[int32] $RuleCount = 0
			[array] $RuleValueNames = $RootKey.GetValueNames()

			foreach ($RuleName in $RuleValueNames)
			{
				# Quickly check if current rule matches function parameters
				$RuleValue = $RootKey.GetValue($RuleName)

				if (![string]::IsNullOrEmpty($DisplayName))
				{
					if (![regex]::Match($RuleValue, "\|Name=$RegexDisplayName\|", [RegexOptions]::Multiline).Success)
					{
						continue
					}
				}

				if (![regex]::Match($RuleValue, "\|EmbedCtxt=$RegexDisplayGroup\|", [RegexOptions]::Multiline).Success)
				{
					continue
				}

				if (![string]::IsNullOrEmpty($Direction))
				{
					if (![regex]::Match($RuleValue, "\|Dir=$RegexDirection\|", [RegexOptions]::Multiline).Success)
					{
						continue
					}
				}

				if (![string]::IsNullOrEmpty($Action))
				{
					if (![regex]::Match($RuleValue, "\|Action=$RegexAction\|", [RegexOptions]::Multiline).Success)
					{
						continue
					}
				}

				if (![string]::IsNullOrEmpty($Enabled))
				{
					if (![regex]::Match($RuleValue, "\|Active=$RegexEnabled\|", [RegexOptions]::Multiline).Success)
					{
						continue
					}
				}

				Write-Progress -Activity "Getting rules from registry" -CurrentOperation $RuleName `
					-PercentComplete (++$RuleCount / $RuleValueNames.Length * 100) `
					-SecondsRemaining (($RuleValueNames.Length - $RuleCount + 1) / 10 * 60)

				# Prepare hashtable
				$HashProps = [ordered]@{
					Name = $RuleName # registry value name
					DisplayName = $null # Name
					Group = $null # EmbedCtxt (borrowed from DisplayGroup)
					DisplayGroup = $null # EmbedCtxt
					Action = $null
					Enabled = $null # Active
					Direction = $null # Dir
					Profile = $null
					Protocol = $null
					LPort = $null
					RPort = $null
					LPort2_10 = $null
					RPort2_10 = $null
					LocalPort = $null
					RemotePort = $null
					ICMP4 = $null
					ICMP6 = $null
					IcmpType = $null
					LA4 = $null
					LA6 = $null
					RA4 = $null
					RA6 = $null
					RA42 = $null
					RA62 = $null
					LocalAddress = $null
					RemoteAddress = $null
					Service = $null # Svc
					Program = $null # App
					InterfaceType = $null # IFType
					InterfaceAlias = $null # IF
					Edge = $null
					Defer = $null
					EdgeTraversalPolicy = $null
					LocalUser = $null # LUAuth
					LocalUserBase64 = $null # LUAuth2_24
					RemoteUser = $null # RUAuth
					Owner = $null # LUOwn
					Package = $null # AppPkgId
					LooseSourceMapping = $null # LSM
					LocalOnlyMapping = $null # LOM
					Platform = $null
					Platform2 = $null
					RuleVersion = (($RootKey.GetValue($RuleName).ToString() -split '\|')[0]).TrimStart("v") # <BLANK>
					Domain = $Domain
					PolicyStoreSource = $PolicyStoreSource
					PolicyStoreSourceType = $PolicyStoreSourceType
					Description = $null # Desc
					TTK = $null
					TTK2_22 = $null
					TTK2_27 = $null
					TTK2_28 = $null
					LPort2_20 = $null
					Security = $null
					Security2 = $null
					Security2_9 = $null
					SkipVer = $null
					PCross = $null
					AuthByPassOut = $null
					NNm = $null
					SecurityRealmId = $null
				}

				# Iterate through the value of the registry rule, ex:
				# v2.30|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|RPort=22|RPort=80|RPort=443|RA42=IntErnet|
				# IFType=Lan|IFType=Wireless|App=%SystemRoot%\System32\backgroundTaskHost.exe|Name=Background task host|
				# Desc=Sample description|EmbedCtxt=Windows System|Platform=2:10:0|Platform2=GTEQ|
				foreach ($Entry in ($RootKey.GetValue($RuleName) -split '\|'))
				{
					# Split current name value pair
					$EntryString = $Entry.ToString()

					if ($EntryString.Contains("="))
					{
						$EntryName = ($Entry -split '=')[0]
						$EntryValue = ($Entry -split "=")[1]
					}
					elseif ([string]::IsNullOrEmpty($EntryString))
					{
						# Empty value
						continue
					}
					else
					{
						# ex. version string, which is already handled
						continue
					}

					switch ($EntryName)
					{
						# This token represents the wszName field of the FW_RULE structure
						# A pointer to a Unicode string that provides a friendly name for the rule
						"Name"
						{
							# HACK: Similarly as for "EmbedCtxt" below, should be implemented here
							if ($EntryValue.StartsWith("@"))
							{
								Write-Verbose -Message "Translating rule name, source string to localized string, not implemented"
							}

							$HashProps.DisplayName = $EntryValue
							break
						}
						# It specifies a group name for this rule
						"EmbedCtxt"
						{
							# TODO: This is not universal, it may start with and be just anything
							if ($EntryValue.StartsWith("@"))
							{
								$FriendlyGroupName = Get-NetFirewallRule -PolicyStore SystemDefaults |
								Sort-Object -Unique Group |
								Where-Object -Property Group -EQ $EntryValue |
								Select-Object -ExpandProperty DisplayGroup

								if ([string]::IsNullOrEmpty($FriendlyGroupName))
								{
									Write-Warning -Message "[$($MyInvocation.InvocationName)] Translating rule group, source string to localized string failed"
								}
								else
								{
									Write-Verbose -Message "[$($MyInvocation.InvocationName)] Translating rule group, source string to localized string"
									$HashProps.Group = $FriendlyGroupName
									$HashProps.DisplayGroup = $FriendlyGroupName
									break
								}
							}

							# NOTE: EmbedCtxt is DisplayGroup, setting Group here by the way
							# because we want to set it to something
							$HashProps.Group = $EntryValue
							$HashProps.DisplayGroup = $EntryValue
							break
						}
						"Action" { $HashProps.Action = $EntryValue; break }
						# This token represents the FW_RULE_FLAGS_ACTIVE flag
						"Active"
						{
							# NOTE: New-NetFirewallRule, the type of this parameter is not boolean,
							# therefore $true and $false variables are not acceptable values here.
							# Use "True" and "False" text strings instead.
							if ($EntryValue -eq "TRUE") { $HashProps.Enabled = "True" }
							else { $HashProps.Enabled = "False" }
							break
						}
						# This token value represents the Direction field
						"Dir"
						{
							if ($EntryValue -eq "Out") { $HashProps.Direction = "Outbound" }
							else { $HashProps.Direction = "Inbound" }
							break
						}
						"Profile" { [array] $HashProps.Profile += $EntryValue; break }
						"Protocol"
						{
							$HashProps.Protocol = ConvertFrom-Protocol $EntryValue -FirewallCompatible
							break
						}
						# This token value represents the LocalPorts
						# Applies to non range port numbers, ex. 443 or 53, 80, 443 and keywords
						"LPort"
						{
							[array] $HashProps.LPort += $EntryValue
							[array] $HashProps.LocalPort += & $ParsePortKeyword $EntryValue
							break
						}
						# This token value represents the RemotePorts field of the FW_RULE structure.
						# As such defined, RemotePorts is of type FW_PORTS, which contains a Ports field of type FW_PORT_RANGE_LIST
						# Applies to non range port numbers, ex. 443 or 53, 80, 443 and keywords
						"RPort"
						{
							[array] $HashProps.RPort += $EntryValue
							[array] $HashProps.RemotePort += & $ParsePortKeyword $EntryValue
							break
						}
						# This token value represents the LocalPorts
						# applies to port ranges ex. 443-555 or 27331-27400, 3543-3566 and keywords IPTLSOut, IPHTTPSOut
						"LPort2_10"
						{
							[array] $HashProps.LPort2_10 += $EntryValue

							# NOTE: "IPTLSIn" is ignored because IPHTTPSIn is already set
							if ($EntryValue -ne "IPTLSIn")
							{
								[array] $HashProps.LocalPort += & $ParsePortKeyword $EntryValue
							}
							break
						}
						# This token value represents the RemotePorts and keywords IPTLSOut, IPHTTPSOut
						# applies to port ranges ex. 443-555 or 27331-27400, 3543-3566
						"RPort2_10"
						{
							[array] $HashProps.RPort2_10 += $EntryValue

							# NOTE: "IPTLSOut" is ignored because IPHTTPSOut is already set
							if ($EntryValue -ne "IPTLSOut")
							{
								[array] $HashProps.RemotePort += & $ParsePortKeyword $EntryValue
							}
							break
						}
						# This token value represents the V4TypeCodeList field
						"ICMP4"
						{
							[array] $HashProps.ICMP4 += $EntryValue
							# Icmp type only, without code, is saved as type:*
							[array] $HashProps.IcmpType += $EntryValue.ToString().TrimEnd(":*")
							break
						}
						# This token value represents the V6TypeCodeList
						"ICMP6"
						{
							[array] $HashProps.ICMP6 += $EntryValue
							# Icmp type only, without code, is saved as type:*
							[array] $HashProps.IcmpType += $EntryValue.ToString().TrimEnd(":*")
							break
						}
						# This token value represents the LocalAddress field of the FW_RULE structure, specifically the v4 fields
						# Applies to local IPv4 addresses, all forms
						"LA4"
						{
							[array] $HashProps.LA4 += $EntryValue
							[array] $HashProps.LocalAddress += $EntryValue
							break
						}
						# This token value represents the LocalAddress field of the FW_RULE structure, specifically the v6 fields
						# Applies to local IPv6 addresses, all forms
						"LA6"
						{
							[array] $HashProps.LA6 += $EntryValue
							[array] $HashProps.LocalAddress += $EntryValue
							break
						}
						# This token value represents the RemoteAddress field of the FW_RULE structure, specifically the v4 fields
						# Applies to remote IPv4 addresses, all forms and multiple keywords, both restricted and non restricted
						"RA4"
						{
							[array] $HashProps.RA4 += $EntryValue
							[array] $HashProps.RemoteAddress += & $ParseAddressKeyword $EntryValue
							break
						}
						# This token value represents the RemoteAddress field of the FW_RULE structure, specifically the v6 fields
						# Applies to remote IPv6 addresses, all forms and multiple keywords, both restricted and non restricted
						"RA6"
						{
							[array] $HashProps.RA6 += $EntryValue
							[array] $HashProps.RemoteAddress += & $ParseAddressKeyword $EntryValue
							break
						}
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						# Applies to remote address single keywords only, both restricted and non restricted
						"RA42"
						{
							$HashProps.RA42 = $EntryValue
							[array] $HashProps.RemoteAddress += & $ParseAddressKeyword $EntryValue
							break
						}
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						# Applies to remote address single keywords only, both restricted and non restricted
						"RA62"
						{
							$HashProps.RA62 = $EntryValue
							[array] $HashProps.RemoteAddress += & $ParseAddressKeyword $EntryValue
							break
						}
						# This token represents the wszLocalService
						"Svc" { $HashProps.Service = $EntryValue; break }
						# This token represents the wszLocalApplication field of the FW_RULE structure
						"App" { $HashProps.Program = $EntryValue; break }
						# This token represents the dwLocalInterfaceType field of the FW_RULE structure.
						"IFType"
						{
							if ($EntryValue -eq "Lan") { [array] $HashProps.InterfaceType += "Wired" }
							else { [array] $HashProps.InterfaceType += $EntryValue }
							break
						}
						# This token represents an entry in the LocalInterfaceIds field of the FW_RULE structure.
						# FW_RULE: A condition that specifies the list of specific network interfaces used by the traffic that the rule matches.
						# A LocalInterfaceIds field with no interface GUID specified means that the rule applies to all interfaces; that is, the condition is not applied.
						"IF"
						{
							# ex. 531FA355-3436-43F9-BF16-8B38C31B2739
							$Adapter = Get-NetAdapter | Where-Object { $_.InterfaceGuid -eq $EntryValue }

							if ($Adapter)
							{
								[array] $HashProps.InterfaceAlias += $Adapter.InterfaceAlias
							}
							else
							{
								[array] $HashProps.InterfaceAlias += $EntryValue
							}
							break
						}
						# This token represents the FW_RULE_FLAGS_ROUTEABLE_ADDRS_TRAVERSE flag
						# If Direction is FW_DIR_OUT, wFlags MUST NOT contain a FW_RULE_FLAGS_ROUTEABLE_ADDRS_TRAVERSE
						"Edge"
						{
							if ($EntryValue -eq "TRUE") { $HashProps.Edge = $true }
							else { $HashProps.Edge = $false }
							break
						}
						#  This token represents the contents of the wFlags field of the FW_RULE structure on the position defined by the
						# FW_RULE_FLAGS_ROUTEABLE_ADDRS_TRAVERSE_APP and FW_RULE_FLAGS_ROUTEABLE_ADDRS_TRAVERSE_USER flag
						"Defer" { $HashProps.Defer = $EntryValue; break }
						# This token represents the wszLocalUserAuthorizationList field of the FW_RULE structure
						# ex. D:(D;;CC;;;S-1-15-3-4)
						"LUAuth" { $HashProps.LocalUser = $EntryValue; break }
						# This token value represents the base64 encoded content of wszLocalUserAuthorizationList and
						# it also adds the FW_RULE_FLAGS_LUA_CONDITIONAL_ACE flag on the wFlags field of the FW_RULE2_24 structure
						"LUAuth2_24" { $HashProps.LocalUserBase64 = $EntryValue; break }
						# This token represents the wszRemoteUserAuthorizationList field of the FW_RULE structure
						"RUAuth" { $HashProps.RemoteUser = $EntryValue; break }
						#  This token represents the wszLocalUserOwner field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format. The SID specifies the security principal that owns the rule.
						# ex. S-1-5-21-2594679847-4063407168-2096078110-1010
						"LUOwn" { $HashProps.Owner = $EntryValue; break }
						# This token represents the wszPackageId field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format ([MS-DTYP] section 2.4.2.1).
						# It is a condition that specifies the application SID of the process that uses the traffic that the rule matches.
						# A null in this field means that the rule applies to all processes in the host.
						# ex. S-1-15-2-1985198343-3186790915-4047221937-1969271670-3792558349-1325541827-400269725
						"AppPkgId" { $HashProps.Package = $EntryValue; break }
						# This token represents the FW_RULE_FLAGS_LOOSE_SOURCE_MAPPED flag
						"LSM"
						{
							# NOTE: Will be set to Ply2Disc when local UDP port is set to PlayToDiscovery
							if (($EntryValue -eq "TRUE") -or ($EntryValue -eq "Ply2Disc"))
							{
								$HashProps.LooseSourceMapping = $true
							}
							else
							{
								# Rule entry not set, "FALSE" is never set
								$HashProps.LooseSourceMapping = $false
							}
							break
						}
						# This token represents the FW_RULE_FLAGS_LOCAL_ONLY_MAPPED flag
						"LOM"
						{
							if ($EntryValue -eq "TRUE") { $HashProps.LocalOnlyMapping = $true }
							else { $HashProps.LocalOnlyMapping = $false } # Rule entry not set, "FALSE" is never set
							break
						}
						# This token value represents the PlatformValidityList field of the FW_RULE structure
						# First number 2 = VER_PLATFORM_WIN32_NT which means the operating system is Windows NT, ex.
						# Windows 7, Windows Server 2008, Windows Vista, Windows Server 2003, Windows XP, or Windows 2000.
						# Next 2 digits are Major.Minor
						# HACK: Specifying -Platform with New-NetFirewallRule does not save platform into registry
						"Platform"
						{
							# Convert "2:10:0" to "10.0"
							[regex] $Regex = "\d+:\d+$"

							if ($Regex.Match($EntryValue).Success)
							{
								$RegexResult = [regex]::Replace($Regex.Match($EntryValue).Value, ":", ".")
							}
							else
							{
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to parse Platform value"
								$RegexResult = $EntryValue
							}

							[array] $HashProps.Platform += $RegexResult
							break
						}
						# This token represents the operator to use on the last entry of the PlatformValidityList field of the FW_RULE structure
						# FW_OS_PLATFORM_OP_GTEQ: The operating system MUST be greater than or equal to the one specified.
						# Conclusion: in registry a value "GTEQ" means we should apply + to last entry in Platform array
						"Platform2" { $HashProps.Platform2 = $EntryValue; break }
						#  This token represents the wszDescription
						"Desc" { $HashProps.Description = $EntryValue; break }
						# TODO: Tokens which follow are of unknown purpose
						# This token value represents the dwTrustTupleKeywords field of the FW_RULE structure
						"TTK" { $HashProps.TTK = $EntryValue; break }
						# This token value represents the dwTrustTupleKeywords field of the FW_RULE structure
						"TTK2_22" { $HashProps.TTK2_22 = $EntryValue; break }
						# This token value represents the dwTrustTupleKeywords field of the FW_RULE structure
						"TTK2_27" { $HashProps.TTK2_27 = $EntryValue; break }
						# This token value represents the dwTrustTupleKeywords field of the FW_RULE structure
						"TTK2_28" { $HashProps.TTK2_28 = $EntryValue; break }
						# This token value represents the LocalPorts field of the FW_RULE structure, specifically the wPortKeywords field
						"LPort2_20" { $HashProps.LPort2_20 = $EntryValue; break }
						# This token value represents specific flags in the wFlags field of the FW_RULE structure
						# The IFSECURE-VAL grammar rule represents a flag of such field.
						# This token MUST appear at most once in a rule string
						"Security" { $HashProps.Security = $EntryValue; break }
						# This token value represents specific flags in the wFlags field of the FW_RULE structure
						# The IFSECURE-VAL grammar rule represents a flag of such field.
						# This token MUST appear at most once in a rule string
						"Security2" { $HashProps.Security2 = $EntryValue; break }
						# This token value represents specific flags in the wFlags field of the FW_RULE structure
						# The IFSECURE-VAL grammar rule represents a flag of such field.
						# This token MUST appear at most once in a rule string
						"Security2_9" { $HashProps.Security2_9 = $EntryValue; break }
						# The VERSION grammar rule following this token represents the highest inherent version of the
						# Firewall and Advanced Security components that can ignore this rule string completely
						"SkipVer" { $HashProps.SkipVer = $EntryValue; break }
						# This token represents the FW_RULE_FLAGS_ALLOW_PROFILE_CROSSING flag
						"PCross" { $HashProps.PCross = $EntryValue; break }
						# This token represents the FW_RULE_FLAGS_AUTHENTICATE_BYPASS_OUTBOUND flag
						"AuthByPassOut" { $HashProps.AuthByPassOut = $EntryValue; break }
						# This token value represents the OnNetworkNames field of the FW_RULE2_24 structure
						"NNm" { $HashProps.NNm = $EntryValue; break }
						# This token represents the wszSecurityRealmId field of the FW_RULE2_24 structure
						"SecurityRealmId" { $HashProps.SecurityRealmId = $EntryValue; break }
						default
						{
							Write-Error -Category NotImplemented -TargetObject $EntryName `
								-Message "Parsing not implemented for $EntryName"
						}
					}
				} # foreach rule value

				# Postprocessing
				if ($HashProps.Direction -eq "Inbound")
				{
					if ($HashProps.Defer -eq "App") { $HashProps.EdgeTraversalPolicy = "DeferToApp" }
					elseif ($HashProps.Defer -eq "User") { $HashProps.EdgeTraversalPolicy = "DeferToUser" }
					elseif ($HashProps.Edge -eq $true) { $HashProps.EdgeTraversalPolicy = "Allow" }
					else { $HashProps.EdgeTraversalPolicy = "Block" }
				}
				else
				{
					$HashProps.EdgeTraversalPolicy = "Block"
				}

				# TODO: It's unclear in what order are multiple platform numbers stored in registry,
				# we are assuming they are stored in ascending order.
				# Unable to test this because New-NetFirewallRule allows specifying single platform number only
				if (($null -ne $HashProps.Platform) -and ($HashProps.Platform2 -eq "GTEQ"))
				{
					# Add '+' sign to last platform entry if Platform2 indicates "grater than equal" operator
					$Index = ([array] $HashProps.Platform).Length - 1
					([array] $HashProps.Platform)[$Index] += "+"
				}

				# Create output object using the properties defined in the hashtable
				New-Object -TypeName PSCustomObject -Property $HashProps
			} # foreach registry rule
		}
	}
}

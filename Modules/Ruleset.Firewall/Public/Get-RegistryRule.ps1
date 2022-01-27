
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

<#
.SYNOPSIS
Gets firewall rules directly from registry

.DESCRIPTION
Get-RegistryRule gets firewall rules by drilling registry

.PARAMETER Domain
Target computer name from which rules are to be queried

.PARAMETER Local
Retrive rules from persistent store (control panel firewall)

.PARAMETER GPO
Retrive rules from GPO store (GPO firewall)

.EXAMPLE
PS> Get-RegistryRule

.INPUTS
None. You cannot pipe objects to Get-RegistryRule

.OUTPUTS
[PSCustomObject]

.NOTES
None.

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
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Ruleset.Firewall/Help/en-US/Get-RegistryRule.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $Local,

		[Parameter()]
		[switch] $GPO,

		[Parameter()]
		[SupportsWildcards()]
		[string] $DisplayGroup,

		[Parameter()]
		[SupportsWildcards()]
		[string] $DisplayName,

		[Parameter()]
		[string] $Direction
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-Computer $Domain)
	{
		# If no switches are set the script defaults to GPO store
		if (!$Local -and !$Gpo) { $GPO = $true }

		$HKLM = @()
		if ($GPO) { $HKLM += "Software\Policies\Microsoft\WindowsFirewall\FirewallRules" }
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
				Write-Warning -Message "Failed to open registry root key: HKLM:\$HKLMRootKey"
				continue
			}

			foreach ($RuleName in $RootKey.GetValueNames())
			{
				# Prepare hashtable
				$HashProps = [ordered]@{
					Name = $null # Name
					DisplayName = $null
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
					ICMP4 = $null
					ICMP6 = $null
					InterfaceType = $null # IFType
					InterfaceAlias = $null # IF
					Edge = $null
					Defer = $null
					EdgeTraversalPolicy = $null
					LocalUser = $null # LUAuth
					LocalUserBase64 = $null # LUAuth2_24
					Owner = $null # LUOwn
					ApplicationPackage = $null # AppPkgId
					LooseSourceMapping = $null # LSM
					LocalOnlyMapping = $null # LOM
					Platform = $null # Platform
					Platform2 = $null
					RuleVersion = $null # <BLANK>
					TTK2_27 = $null
					LPort2_20 = $null
					Description = $null # Desc
				}

				# Determine if this is a local or a group policy rule and display this in the hashtable
				$HashProps.PolicyStoreSourceType = "GPO"
				if ($HKLMRootKey -match "^System\\CurrentControlSet")
				{
					$HashProps.PolicyStoreSourceType = "Local"
				}
				else
				{
					$HashProps.PolicyStoreSourceType = "GPO"
				}

				$HashProps.Name = $RuleName
				$HashProps.RuleVersion = (($RootKey.GetValue($RuleName) -split '\|')[0]).ToString().TrimStart("v")

				# Iterate through the rest of value of the registry rule
				foreach ($RuleValue in ($RootKey.GetValue($RuleName) -split '\|'))
				{
					# Current name value pair
					$EntryName = ""
					$EntryValue = ""
					$RawValue = $RuleValue.ToString()

					if ($RawValue.Contains("="))
					{
						$EntryName = ($RuleValue -split '=')[0]
						$EntryValue = ($RuleValue -split "=")[1]
					}
					else
					{
						if ([string]::IsNullOrEmpty($RawValue))
						{
							# Empty value
							continue
						}
						else
						{
							# ex. version string, which is already handled
							continue
						}
					}

					switch ($EntryName)
					{
						# This token represents the wszName field of the FW_RULE structure
						# A pointer to a Unicode string that provides a friendly name for the rule
						"Name" { $HashProps.DisplayName = $EntryValue; break }
						# It specifies a group name for this rule
						"EmbedCtxt" { $HashProps.DisplayGroup = $EntryValue; break }
						"Action" { $HashProps.Action = $EntryValue; break }
						# This token represents the FW_RULE_FLAGS_ACTIVE flag
						"Active"
						{
							if ($EntryValue -eq "TRUE") { $HashProps.Enabled = $true }
							else { $HashProps.Enabled = $false }
							break
						}
						# This token value represents the Direction field
						"Dir"
						{
							if ($EntryValue -eq "Out") { $HashProps.Direction = "Outbound" }
							else { $HashProps.Direction = "Inbound" }
							break
						}
						"Profile" { $HashProps.Profile = $EntryValue }
						"Protocol"
						{
							$HashProps.Protocol = ConvertFrom-Protocol $EntryValue
							break
						}
						# This token value represents the LocalPorts
						# Applies to non range port numbers, ex. 443 or 53, 80, 443 and keywords
						"LPort"
						{
							[array] $HashProps.LPort += $EntryValue
							[array] $HashProps.LocalPort += $EntryValue
							break
						}
						# This token value represents the RemotePorts field of the FW_RULE structure.
						# As such defined, RemotePorts is of type FW_PORTS, which contains a Ports field of type FW_PORT_RANGE_LIST
						# Applies to non range port numbers, ex. 443 or 53, 80, 443 and keywords
						"RPort"
						{
							[array] $HashProps.RPort += $EntryValue
							[array] $HashProps.RemotePort += $EntryValue
							break
						}
						# This token value represents the LocalPorts
						# applies to port ranges ex. 443-555 or 27331-27400, 3543-3566
						"LPort2_10"
						{
							[array] $HashProps.LPort2_10 += $EntryValue
							[array] $HashProps.LocalPort += $EntryValue
							break
						}
						# This token value represents the RemotePorts
						# applies to port ranges ex. 443-555 or 27331-27400, 3543-3566
						"RPort2_10"
						{
							[array] $HashProps.RPort2_10 += $EntryValue
							[array] $HashProps.RemotePort += $EntryValue
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
						# Applies to remote IPv4 addresses, all forms
						"RA4"
						{
							[array] $HashProps.RA4 += $EntryValue
							[array] $HashProps.RemoteAddress += $EntryValue
							break
						}
						# This token value represents the RemoteAddress field of the FW_RULE structure, specifically the v6 fields
						# Applies to remote IPv6 addresses, all forms
						"RA6"
						{
							[array] $HashProps.RA6 += $EntryValue
							[array] $HashProps.RemoteAddress += $EntryValue
							break
						}
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						# Applies to remote address keywords, both restricted and non restricted
						"RA42"
						{
							[array] $HashProps.RA42 += $EntryValue
							[array] $HashProps.RemoteAddress += $EntryValue
							break
						}
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						# Applies to remote address keywords, both restricted and non restricted
						"RA62"
						{
							[array] $HashProps.RA62 += $EntryValue
							[array] $HashProps.RemoteAddress += $EntryValue
							break
						}
						# This token represents the wszLocalService
						"Svc" { $HashProps.Service = $EntryValue; break }
						# This token represents the wszLocalApplication field of the FW_RULE structure
						"App" { $HashProps.Program = $EntryValue; break }
						# This token value represents the V4TypeCodeList field
						"ICMP4" { $HashProps.ICMP4 = $EntryValue; break }
						# This token value represents the V6TypeCodeList
						"ICMP6" { $HashProps.ICMP6 = $EntryValue; break }
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
								$HashProps.InterfaceAlias = $Adapter.InterfaceAlias
							}
							else
							{
								$HashProps.InterfaceAlias = $EntryValue
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
						"Defer" { $HashProps.Defer = $EntryValue }
						# This token represents the wszLocalUserAuthorizationList field of the FW_RULE structure
						"LUAuth"
						{
							$FromSDDL = ConvertFrom-SDDL $EntryValue -Force
							$HashProps.LocalUser = $FromSDDL.Principal
							break
						}
						# This token value represents the base64 encoded content of wszLocalUserAuthorizationList and
						# it also adds the FW_RULE_FLAGS_LUA_CONDITIONAL_ACE flag on the wFlags field of the FW_RULE2_24 structure
						"LUAuth2_24" { $HashProps.LocalUserBase64 = $EntryValue; break }
						#  This token represents the wszLocalUserOwner field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format. The SID specifies the security principal that owns the rule.
						# ex. S-1-5-21-2594679847-4063407168-2096078110-1010
						"LUOwn"
						{
							if ($EntryValue -ne "Any")
							{
								$HashProps.Owner = (ConvertFrom-SID $EntryValue).Name
							}
							else
							{
								$HashProps.Owner = $EntryValue
							}
							break
						}
						# This token represents the wszPackageId field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format ([MS-DTYP] section 2.4.2.1).
						# It is a condition that specifies the application SID of the process that uses the traffic that the rule matches.
						# A null in this field means that the rule applies to all processes in the host.
						# ex. S-1-15-2-1985198343-3186790915-4047221937-1969271670-3792558349-1325541827-400269725
						"AppPkgId"
						{
							if ($EntryValue -eq "*")
							{
								$HashProps.ApplicationPackage = "*"
							}
							elseif ($EntryValue -ne "Any")
							{
								# NOTE: Not converting SID here because it takes too long
								$HashProps.ApplicationPackage = $EntryValue
							}
							else
							{
								$HashProps.ApplicationPackage = $EntryValue
							}
							break
						}
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
								# Field is blank
								$HashProps.LooseSourceMapping = $false
							}
							break
						}
						# This token represents the FW_RULE_FLAGS_LOCAL_ONLY_MAPPED flag
						"LOM"
						{
							if ($EntryValue -eq "TRUE") { $HashProps.LocalOnlyMapping = $true }
							else { $HashProps.LocalOnlyMapping = $false } # Field is blank
							break
						}
						# This token value represents the PlatformValidityList field of the FW_RULE structure
						"Platform" { $HashProps.Platform = $EntryValue; break }
						# This token represents the operator to use on the last entry of the PlatformValidityList field of the FW_RULE structure
						"Platform2" { $HashProps.Platform2 = $EntryValue; break }
						# This token value represents the dwTrustTupleKeywords field of the FW_RULE structure
						"TTK2_27" { $HashProps.LocalOnlyMapping = $EntryValue; break }
						# This token value represents the LocalPorts field of the FW_RULE structure, specifically the wPortKeywords field
						"LPort2_20" { $HashProps.LocalOnlyMapping = $EntryValue; break }
						#  This token represents the wszDescription
						"Desc" { $HashProps.Description = $EntryValue; break }
						default
						{
							Write-Error -Category NotImplemented -TargetObject $RuleValue `
								-Message "Parsing not implemented for $RuleValue"
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

				# Create output object using the properties defined in the hashtable
				$RuleObject = New-Object -TypeName "PSCustomObject" -Property $HashProps

				# TODO: Getting rules based on function parameters should be done beforehand to
				# reduce amount of rules parsed for performance reasons
				if (![string]::IsNullOrEmpty($DisplayName))
				{
					$RuleObject = $RuleObject | Where-Object {
						# Write-Warning "DisplayName: $($_.DisplayName)"
						$_.DisplayName -like $DisplayName
					}
				}

				if (![string]::IsNullOrEmpty($DisplayGroup))
				{
					$RuleObject = $RuleObject | Where-Object {
						# Write-Warning "DisplayGroup: $($_.DisplayGroup)"
						$_.DisplayGroup -like $DisplayGroup
					}
				}

				if (![string]::IsNullOrEmpty($Direction))
				{
					$RuleObject = $RuleObject | Where-Object {
						# Write-Warning "Direction: $($_.Direction)"
						$_.Direction -eq $Direction
					}
				}

				Write-Output $RuleObject
			} # foreach registry rule
		}
	}
}

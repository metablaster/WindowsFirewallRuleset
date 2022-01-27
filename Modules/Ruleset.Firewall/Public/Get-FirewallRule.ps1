
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
Get-FirewallRule gets firewall rules by drilling registry

.PARAMETER Domain
Target computer name from which rules are to be queried

.PARAMETER Local
Retrive rules from persistent store (control panel firewall)

.PARAMETER GPO
Retrive rules from GPO store (GPO firewall)

.EXAMPLE
PS> Get-FirewallRule

.INPUTS
None. You cannot pipe objects to Get-FirewallRule

.OUTPUTS
[PSCustomObject]

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Get-FirewallRule.md

.LINK
https://stackoverflow.com/questions/53246271/get-netfirewallruleget-netfirewallportfilter-are-too-slow

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpfas/2efe0b76-7b4a-41ff-9050-1023f8196d16

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fasp/8c008258-166d-46d4-9090-f2ffaa01be4b
#>
function Get-FirewallRule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Ruleset.Firewall/Help/en-US/Get-FirewallRule.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $Local,

		[Parameter()]
		[switch] $GPO
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

			# Prepare hashtable
			$HashProps = @{
				DisplayName = $null
				RuleVersion = $null
				Action = $null
				Enabled = $null # Active
				Direction = $null # Dir
				Protocol = $null
				LPort = $null
				App = $null
				Name = $null # Name
				Description = $null # Desc
				DisplayGroup = $null # EmbedCtxt
				Profile = $null
				RA4 = $null
				RA42 = $null
				RA6 = $null
				RA62 = $null
				Service = $null # Svc
				RPort = $null
				ICMP6 = $null
				EdgeTraversalPolicy = $null # Edge
				LA4 = $null
				LA6 = $null
				ICMP4 = $null
				LPort2_10 = $null
				RPort2_10 = $null
				Platform = $null # Platform
				Platform2 = $null #
				InterfaceType = $null # IFType
				ApplicationPackage = $null # AppPkgId
				Owner = $null # LUOwn
				LocalUser = $null # LUAuth
			}

			<#
			Name                    : NETDIS-UPnPHost-In-TCP-Active
			ID                      : NETDIS-UPnPHost-In-TCP-Active
			DisplayName             : Network Discovery (UPnP-In)
			Group                   : @FirewallAPI.dll,-32752
			Enabled                 : True
			Profile                 : Private
			Platform                : {}
			Direction               : Inbound
			Action                  : Allow
			EdgeTraversalPolicy     : Block
			LSM                     : False
			PrimaryStatus           : OK
			Status                  : The rule was parsed successfully from the store. (65536)
			EnforcementStatus       : NotApplicable
			PolicyStoreSourceType   : Local
			Caption                 :
			Description             : Inbound rule for Network Discovery to allow use of Universal Plug and Play. [TCP 2869]
			ElementName             : @FirewallAPI.dll,-32761
			InstanceID              : NETDIS-UPnPHost-In-TCP-Active
			CommonName              :
			PolicyKeywords          :
			PolicyDecisionStrategy  : 2
			PolicyRoles             :
			ConditionListType       : 3
			CreationClassName       : MSFT|FW|FirewallRule|NETDIS-UPnPHost-In-TCP-Active
			ExecutionStrategy       : 2
			Mandatory               :
			PolicyRuleName          :
			Priority                :
			RuleUsage               :
			SequencedActions        : 3
			SystemCreationClassName :
			SystemName              :
			DisplayGroup            : Network Discovery
			LocalOnlyMapping        : False
			LooseSourceMapping      : False
			Owner                   :
			Platforms               : {}
			PolicyStoreSource       : PersistentStore
			Profiles                : 2
			RuleGroup               : @FirewallAPI.dll,-32752
			StatusCode              : 65536
			PSComputerName          :
			CimClass                : root/standardcimv2:MSFT_NetFirewallRule
			CimInstanceProperties   : {Caption, Description, ElementName, InstanceID…}
			CimSystemProperties     : Microsoft.Management.Infrastructure.CimSystemProperties
			#>

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

			foreach ($RuleName in $RootKey.GetValueNames())
			{
				$HashProps.Name = $RuleName
				$HashProps.RuleVersion = ($RootKey.GetValue($RuleName) -split '\|')[0]

				# Iterate through the rest of value of the registry rule
				foreach ($RuleValue in ($RootKey.GetValue($RuleName) -split '\|'))
				{
					switch -Regex (($RuleValue -split '=')[0])
					{
						"Action" { $HashProps.Action = ($RuleValue -split "=")[1] }
						# This token represents the FW_RULE_FLAGS_ACTIVE flag
						"Active" { $HashProps.Enabled = ($RuleValue -split "=")[1] }
						# This token value represents the Direction field
						"Dir" { $HashProps.Direction = ($RuleValue -split "=")[1] }
						"Protocol" { $HashProps.Protocol = ($RuleValue -split "=")[1] }
						# This token value represents the LocalPorts
						"LPort" { $HashProps.LPort = ($RuleValue -split "=")[1] }
						# This token represents the wszLocalApplication field of the FW_RULE structure
						"App" { $HashProps.App = ($RuleValue -split "=")[1] }
						# This token represents the wszName field of the FW_RULE structure
						# A pointer to a Unicode string that provides a friendly name for the rule
						"Name" { $HashProps.DisplayName = ($RuleValue -split "=")[1] }
						#  This token represents the wszDescription
						"Desc" { $HashProps.Description = ($RuleValue -split "=")[1] }
						# It specifies a group name for this rule
						"EmbedCtxt" { $HashProps.DisplayGroup = ($RuleValue -split "=")[1] }
						"Profile" { $HashProps.Profile = ($RuleValue -split "=")[1] }
						# This token value represents the RemoteAddress field of the FW_RULE structure, specifically the v4 fields
						"RA4" { [array] $HashProps.RA4 += ($RuleValue -split "=")[1] }
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						"RA42" { [array] $HashProps.RA42 += ($RuleValue -split "=")[1] }
						# This token value represents the RemoteAddress field of the FW_RULE structure, specifically the v6 fields
						"RA6" { [array] $HashProps.RA6 += ($RuleValue -split "=")[1] }
						# This token value represents the RemoteAddresses field of the FW_RULE structure, specifically the dwV4AddressKeywords field
						"RA62" { [array] $HashProps.RA62 += ($RuleValue -split "=")[1] }
						# This token represents the wszLocalService
						"Svc" { $HashProps.Service = ($RuleValue -split "=")[1] }
						# This token value represents the RemotePorts field of the FW_RULE structure.
						# As such defined, RemotePorts is of type FW_PORTS, which contains a Ports field of type FW_PORT_RANGE_LIST
						"RPort" { $HashProps.RPort = ($RuleValue -split "=")[1] }
						# This token value represents the V6TypeCodeList
						"ICMP6" { $HashProps.ICMP6 = ($RuleValue -split "=")[1] }
						# This token represents the FW_RULE_FLAGS_ROUTEABLE_ADDRS_TRAVERSE flag
						"Edge" { $HashProps.EdgeTraversalPolicy = ($RuleValue -split "=")[1] }
						# This token value represents the LocalAddress field of the FW_RULE structure, specifically the v4 fields
						"LA4" { [array]$HashProps.LA4 += ($RuleValue -split "=")[1] }
						# This token value represents the LocalAddress field of the FW_RULE structure, specifically the v6 fields
						"LA6" { [array]$HashProps.LA6 += ($RuleValue -split "=")[1] }
						# This token value represents the V4TypeCodeList field
						"ICMP4" { $HashProps.ICMP4 = ($RuleValue -split "=")[1] }
						# This token value represents the LocalPorts
						"LPort2_10" { $HashProps.LPort2_10 = ($RuleValue -split "=")[1] }
						# This token value represents the RemotePorts
						"RPort2_10" { $HashProps.RPort2_10 = ($RuleValue -split "=")[1] }
						# This token value represents the PlatformValidityList field of the FW_RULE structure
						"Platform" { $HashProps.Platform = ($RuleValue -split "=")[1] }
						# This token represents the dwLocalInterfaceType field of the FW_RULE structure.
						"IFType" { $HashProps.InterfaceType = ($RuleValue -split "=")[1] }
						# This token represents the operator to use on the last entry of the PlatformValidityList field of the FW_RULE structure
						"Platform2" { $HashProps.Platform2 = ($RuleValue -split "=")[1] }
						# This token represents the wszPackageId field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format ([MS-DTYP] section 2.4.2.1).
						# It is a condition that specifies the application SID of the process that uses the traffic that the rule matches.
						# A null in this field means that the rule applies to all processes in the host.
						"AppPkgId" { $HashProps.ApplicationPackage = ($RuleValue -split "=")[1] }
						#  This token represents the wszLocalUserOwner field of the FW_RULE structure
						# FW_RULE: A pointer to a Unicode string in SID string format. The SID specifies the security principal that owns the rule.
						"LUOwn" { $HashProps.Owner = ($RuleValue -split "=")[1] }
						# This token represents the wszLocalUserAuthorizationList field of the FW_RULE structure
						"LUAuth" { $HashProps.LocalUser = ($RuleValue -split "=")[1] }
						# This token value represents the base64 encoded content of wszLocalUserAuthorizationList and
						# it also adds the FW_RULE_FLAGS_LUA_CONDITIONAL_ACE flag on the wFlags field of the FW_RULE2_24 structure
						"LUAuth2_24" { $HashProps.LocalUserBase64 = ($RuleValue -split "=")[1] }
						# Ignoring empty key
						""
						{
							# Write-Warning -Message "Ignored value: $(($RuleValue -split "=")[1])"
							continue
						}
						"v\d+\.d+" { continue } # version already handled
						default
						{
							Write-Error -Category NotImplemented -TargetObject $RuleValue `
								-Message "Parsing not implemented for $RuleValue"
						}
					}
				}

				# Create output object using the properties defined in the hashtable
				New-Object -TypeName "PSCustomObject" -Property $HashProps
			}
		}
	}
}

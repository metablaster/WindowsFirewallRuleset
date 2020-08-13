
<#
MIT License

Copyright (C) 2020 Markus Scholtes

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
Convert String array to comma separated list
.DESCRIPTION
Convert String array to comma separated list
.PARAMETER StringArray
String array which to convert
.EXAMPLE
TODO: provide example and description
.INPUTS
None. You cannot pipe objects to StringArrayToList
.OUTPUTS
[string] comma separated list
.NOTES
None.
#>
function StringArrayToList
{
	[OutputType([System.String])]
	param(
		[Parameter()]
		[string[]] $StringArray
	)

	if ($StringArray)
	{
		$Result = ""
		foreach ($Value In $StringArray)
		{
			if ($Result -ne "")
			{
				$Result += ","
			}

			$Result += $Value
		}
		return $Result
	}
	else
	{
		return ""
	}
}

<#
.SYNOPSIS
Exports firewall rules to a CSV or JSON file.
.DESCRIPTION
Exports firewall rules to a CSV or JSON file. Local and policy based rules will be given out.
CSV files are semicolon separated (Beware! Excel is not friendly to CSV files).
All rules are exported by default, you can filter with parameter -Name, -Inbound, -Outbound,
-Enabled, -Disabled, -Allow and -Block.
.PARAMETER Name
Display name of the rules to be processed. Wildcard character * is allowed.
.PARAMETER CSVFile
Output file
.PARAMETER JSON
Output in JSON instead of CSV format
.PARAMETER Inbound
Export inbound rules
.PARAMETER Outbound
Export outbound rules
.PARAMETER Enabled
Export enabled rules
.PARAMETER Disabled
Export disabled rules
.PARAMETER Allow
Export allowing rules
.PARAMETER Block
Export blocking rules
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15
.EXAMPLE
Export-FirewallRules
Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Export-FirewallRules -Inbound -Allow
Exports all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Export-FirewallRules snmp* SNMPRules.json -json
Exports all SNMP firewall rules to the JSON file SNMPRules.json.
#>
function Export-FirewallRules
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param(
		[Parameter()]
		[string] $Name = "*",

		[Parameter()]
		[string] $CSVFile = ".\FirewallRules.csv",

		[Parameter()]
		[switch]$JSON,

		[Parameter()]
		[switch]$Inbound,

		[Parameter()]
		[switch]$Outbound,

		[Parameter()]
		[switch]$Enabled,

		[Parameter()]
		[switch]$Disabled,

		[Parameter()]
		[switch]$Block,

		[Parameter()]
		[switch]$Allow
	)

	# Filter rules?
	# Filter by direction
	$Direction = "*"
	if ($Inbound -And !$Outbound) { $Direction = "Inbound" }
	if (!$Inbound -And $Outbound) { $Direction = "Outbound" }

	# Filter by state
	$RuleState = "*"
	if ($Enabled -And !$Disabled) { $RuleState = "True" }
	if (!$Enabled -And $Disabled) { $RuleState = "False" }

	# Filter by action
	$Action = "*"
	if ($Allow -And !$Block) { $Action = "Allow" }
	if (!$Allow -And $Block) { $Action = "Block" }


	# read firewall rules
	$FirewallRules = Get-NetFirewallRule -DisplayName $Name -PolicyStore "ActiveStore" |
	Where-Object {
		$_.Direction -like $Direction -and $_.Enabled -like $RuleState -And $_.Action -like $Action
	}

	# start array of rules
	$FirewallRuleSet = @()
	foreach ($Rule In $FirewallRules)
	{
		# iterate through rules
		Write-Output "Processing rule `"$($Rule.DisplayName)`" ($($Rule.Name))"

		# Retrieve addresses,
		$AddressFilter = $Rule | Get-NetFirewallAddressFilter
		# ports,
		$PortFilter = $Rule | Get-NetFirewallPortFilter
		# application,
		$ApplicationFilter = $Rule | Get-NetFirewallApplicationFilter
		# service,
		$ServiceFilter = $Rule | Get-NetFirewallServiceFilter
		# interface,
		$InterfaceFilter = $Rule | Get-NetFirewallInterfaceFilter
		# interface type
		$InterfaceTypeFilter = $Rule | Get-NetFirewallInterfaceTypeFilter
		# and security settings
		$SecurityFilter = $Rule | Get-NetFirewallSecurityFilter

		# generate sorted Hashtable
		$HashProps = [PSCustomObject]@{
			Name = $Rule.Name
			DisplayName = $Rule.DisplayName
			Description = $Rule.Description
			Group = $Rule.Group
			Enabled = $Rule.Enabled
			Profile = $Rule.Profile
			Platform = StringArrayToList $Rule.Platform
			Direction = $Rule.Direction
			Action = $Rule.Action
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LooseSourceMapping = $Rule.LooseSourceMapping
			LocalOnlyMapping = $Rule.LocalOnlyMapping
			Owner = $Rule.Owner
			LocalAddress = StringArrayToList $AddressFilter.LocalAddress
			RemoteAddress = StringArrayToList $AddressFilter.RemoteAddress
			Protocol = $PortFilter.Protocol
			LocalPort = StringArrayToList $PortFilter.LocalPort
			RemotePort = StringArrayToList $PortFilter.RemotePort
			IcmpType = StringArrayToList $PortFilter.IcmpType
			DynamicTarget = $PortFilter.DynamicTarget
			Program = $ApplicationFilter.Program -Replace "$($ENV:SystemRoot.Replace("\","\\"))\\", "%SystemRoot%\" -Replace "$(${ENV:ProgramFiles(x86)}.Replace("\","\\").Replace("(","\(").Replace(")","\)"))\\", "%ProgramFiles(x86)%\" -Replace "$($ENV:ProgramFiles.Replace("\","\\"))\\", "%ProgramFiles%\"
			Package = $ApplicationFilter.Package
			Service = $ServiceFilter.Service
			InterfaceAlias = StringArrayToList $InterfaceFilter.InterfaceAlias
			InterfaceType = $InterfaceTypeFilter.InterfaceType
			LocalUser = $SecurityFilter.LocalUser
			RemoteUser = $SecurityFilter.RemoteUser
			RemoteMachine = $SecurityFilter.RemoteMachine
			Authentication = $SecurityFilter.Authentication
			Encryption = $SecurityFilter.Encryption
			OverrideBlockRules = $SecurityFilter.OverrideBlockRules
		}

		# add to array with rules
		$FirewallRuleSet += $HashProps
	}

	if (!$JSON)
	{
		# output rules in CSV format
		$FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Set-Content $CSVFile
	}
	else
	{
		# output rules in JSON format
		$FirewallRuleSet | ConvertTo-Json | Set-Content $CSVFile
	}
}

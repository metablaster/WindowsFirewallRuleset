
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
Convert comma separated list to String array
.DESCRIPTION
Convert comma separated list to String array
.PARAMETER List

.PARAMETER DefaultValue

.EXAMPLE
TODO: provide example and description
.INPUTS
None. You cannot pipe objects to ListToStringArray
.OUTPUTS
[string[]] array from comma separated list
.NOTES
TODO: output type
#>
function ListToStringArray
{
	param(
		[Parameter()]
		[string] $List,

		[Parameter()]
		[string] $DefaultValue = "Any"
	)

	if (![string]::IsNullOrEmpty($List))
	{
		return ($List -split ",")
	}
	else
	{
		return $DefaultValue
	}
}

<#
.SYNOPSIS
Convert value to boolean
.DESCRIPTION
Convert value to boolean
.PARAMETER Value

.PARAMETER DefaultValue

.EXAMPLE
TODO: provide example and description
.INPUTS
None. You cannot pipe objects to ValueToBoolean
.OUTPUTS
[bool] of the input value
.NOTES
None.
#>
function ValueToBoolean
{
	[OutputType([System.Boolean])]
	param(
		[Parameter()]
		[string] $Value,

		[Parameter()]
		[bool] $DefaultValue = $false
	)

	if (![string]::IsNullOrEmpty($Value))
	{
		if (($Value -eq "True") -or ($Value -eq "1"))
		{
			return $true
		}
		else
		{
			return $false
		}
	}
	else
	{
		return $DefaultValue
	}
}

<#
.SYNOPSIS
Imports firewall rules from a CSV or JSON file.
.DESCRIPTION
Imports firewall rules from with Export-FirewallRules generated CSV or JSON files. CSV files have to
be separated with semicolons. Existing rules with same display name will be overwritten.
.PARAMETER CSVFile
Input file
.PARAMETER JSON
Input in JSON instead of CSV format
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15
.EXAMPLE
Import-FirewallRules
Imports all firewall rules in the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Import-FirewallRules WmiRules.json -json
Imports all firewall rules in the JSON file WmiRules.json.
#>
function Import-FirewallRules
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param(
		[Parameter()]
		[string] $CSVFile = ".\FirewallRules.csv",

		[Parameter()]
		[switch] $JSON
	)

	if (!$JSON)
	{
		# read CSV file
		$FirewallRules = Get-Content $CSVFile | ConvertFrom-Csv -Delimiter ";"
	}
	else
	{
		# read JSON file
		$FirewallRules = Get-Content $CSVFile | ConvertFrom-Json
	}

	# iterate rules
	foreach ($Rule In $FirewallRules)
	{
		# generate Hashtable for New-NetFirewallRule parameters
		$RuleSplatHash = @{
			Name = $Rule.Name
			Displayname = $Rule.Displayname
			Description = $Rule.Description
			Group = $Rule.Group
			Enabled = $Rule.Enabled
			Profile = $Rule.Profile
			Platform = ListToStringArray $Rule.Platform @()
			Direction = $Rule.Direction
			Action = $Rule.Action
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LooseSourceMapping = ValueToBoolean $Rule.LooseSourceMapping
			LocalOnlyMapping = ValueToBoolean $Rule.LocalOnlyMapping
			LocalAddress = ListToStringArray $Rule.LocalAddress
			RemoteAddress = ListToStringArray $Rule.RemoteAddress
			Protocol = $Rule.Protocol
			LocalPort = ListToStringArray $Rule.LocalPort
			RemotePort = ListToStringArray $Rule.RemotePort
			IcmpType = ListToStringArray $Rule.IcmpType
			DynamicTarget = if ([string]::IsNullOrEmpty($Rule.DynamicTarget)) { "Any" } else { $Rule.DynamicTarget }
			Program = $Rule.Program
			Service = $Rule.Service
			InterfaceAlias = ListToStringArray $Rule.InterfaceAlias
			InterfaceType = $Rule.InterfaceType
			LocalUser = $Rule.LocalUser
			RemoteUser = $Rule.RemoteUser
			RemoteMachine = $Rule.RemoteMachine
			Authentication = $Rule.Authentication
			Encryption = $Rule.Encryption
			OverrideBlockRules = ValueToBoolean $Rule.OverrideBlockRules
		}

		# for SID types no empty value is defined, so omit if not present
		if (![string]::IsNullOrEmpty($Rule.Owner)) { $RuleSplatHash.Owner = $Rule.Owner }
		if (![string]::IsNullOrEmpty($Rule.Package)) { $RuleSplatHash.Package = $Rule.Package }

		Write-Output "Generating firewall rule `"$($Rule.DisplayName)`" ($($Rule.Name))"
		# remove rule if present
		Get-NetFirewallRule -EA SilentlyContinue -Name $Rule.Name | Remove-NetFirewallRule

		# generate new firewall rule, parameter are assigned with splatting
		New-NetFirewallRule -EA Continue @RuleSplatHash
	}
}


<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes
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
Convert String array to comma separated list
.DESCRIPTION
Convert String array to comma separated list
.PARAMETER StringArray
String array which to convert
.EXAMPLE
TODO: provide example and description
.INPUTS
None. You cannot pipe objects to Convert-ArrayToList
.OUTPUTS
[string] comma separated list
.NOTES
None.
#>
function Convert-ArrayToList
{
	[OutputType([System.String])]
	param(
		[Parameter()]
		[string[]] $StringArray
	)

	if ($StringArray)
	{
		[string] $Result = ""
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
Convert multi line string array to single line string
.DESCRIPTION
Convert multi line string array to single line string
`r is encoded as %% and `n as ||
.PARAMETER MultiLine
String array which to convert
.PARAMETER JSON
Input string will go to JSON file, meaning no need to encode
.EXAMPLE
Convert-MultiLineToList "Some`rnString"
Produces: Some||String
.INPUTS
None. You cannot pipe objects to Convert-ArrayToList
.OUTPUTS
[string] comma separated list
.NOTES
None.
#>
function Convert-MultiLineToList
{
	[OutputType([System.String])]
	param(
		[Parameter()]
		[string] $MultiLine,

		[Parameter()]
		[switch] $JSON
	)

	if ([System.String]::IsNullOrEmpty($MultiLine))
	{
		return ""
	}

	# replace new line with encoded string
	# For CSV files need to encode multi line rule description into single line
	if ($JSON)
	{
		return $MultiLine
	}
	else
	{
		return $MultiLine.Replace("`r", "%%").Replace("`n", "||")
	}
}

<#
.SYNOPSIS
Exports firewall rules to a CSV or JSON file.
.DESCRIPTION
Exports firewall rules to a CSV or JSON file. Only local GPO rules are exported by default.
CSV files are semicolon separated (Beware! Excel is not friendly to CSV files).
All rules are exported by default, you can filter with parameter -Name, -Inbound, -Outbound,
-Enabled, -Disabled, -Allow and -Block.
If the export file already exists it's content will be replaced by default.
.PARAMETER PolicyStore
Policy store from which to export rules, default is local GPO.
For more information about stores see:
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/FirewallParameters.md
.PARAMETER DisplayName
Display name of the rules to be processed. Wildcard character * is allowed.
.PARAMETER DisplayGroup
Display group of the rules to be processed. Wildcard character * is allowed.
.PARAMETER Folder
Path into which to save file
.PARAMETER FileName
Output file, default is JSON format
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
.PARAMETER Append
Append exported rules to existing file instead of replacing
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Changes by metablaster - August 2020:
1. Applied formatting and code style according to project rules
2. Added switch to optionally append instead of replacing output file
3. Separated functions into their own scope
4. Added function to decode string into multi line
5. Added parameter to target specific policy store
6. Added parameter to let specify directory, and crate it if it doesn't exist
7. Added more output streams for debug, verbose and info
8. Added parameter to export according to rule group
9. Changed minor flow and logic of execution
10. Make output formatted and colored
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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'There is no way to replace Write-Host here')]
	[OutputType([System.Void])]
	[CmdletBinding()]
	param(
		[Parameter()]
		[string] $PolicyStore = [System.Environment]::MachineName,

		[Parameter()]
		[string] $Folder = ".",

		[Parameter()]
		[string] $FileName = "FirewallRules",

		[Parameter()]
		[string] $DisplayName = "*",

		[Parameter()]
		[string] $DisplayGroup = "*",

		[Parameter()]
		[switch] $JSON,

		[Parameter()]
		[switch] $Inbound,

		[Parameter()]
		[switch] $Outbound,

		[Parameter()]
		[switch] $Enabled,

		[Parameter()]
		[switch] $Disabled,

		[Parameter()]
		[switch] $Block,

		[Parameter()]
		[switch] $Allow,

		[Parameter()]
		[switch] $Append
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting up variables"

	# Filter rules?
	# NOTE: because there are 3 possibilities for each of below switches we use -like operator
	# Filter by direction
	$Direction = "*"
	if ($Inbound -and !$Outbound) { $Direction = "Inbound" }
	if (!$Inbound -and $Outbound) { $Direction = "Outbound" }

	# Filter by state
	$RuleState = "*"
	if ($Enabled -and !$Disabled) { $RuleState = "True" }
	if (!$Enabled -and $Disabled) { $RuleState = "False" }

	# Filter by action
	$Action = "*"
	if ($Allow -and !$Block) { $Action = "Allow" }
	if (!$Allow -and $Block) { $Action = "Block" }

	# read firewall rules
	# NOTE: getting rules may fail for multiple reasons, there is no point to handle errors here
	if ($DisplayGroup -eq "")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules - skip grouped rules"

		$FirewallRules = Get-NetFirewallRule -DisplayName $DisplayName -PolicyStore $PolicyStore |
		Where-Object {
			$_.DisplayGroup -Like $DisplayGroup -and $_.Direction -like $Direction `
				-and $_.Enabled -like $RuleState -and $_.Action -like $Action
		}
	}
	elseif ($DisplayGroup -eq "*")
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules"

		$FirewallRules = Get-NetFirewallRule -DisplayName $DisplayName -PolicyStore $PolicyStore |
		Where-Object {
			$_.Direction -like $Direction -and $_.Enabled -like $RuleState -and $_.Action -like $Action
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules - skip ungrouped rules"

		$FirewallRules = Get-NetFirewallRule -DisplayName $DisplayName `
			-DisplayGroup $DisplayGroup -PolicyStore $PolicyStore |
		Where-Object {
			$_.Direction -like $Direction -and $_.Enabled -like $RuleState -and $_.Action -like $Action
		}
	}

	if (!$FirewallRules)
	{
		Write-Warning -Message "No rules were retrieved from firewall to export"
		Write-Information -Tags "User" -MessageData "INFO: possible cause is either no match or an error ocurred"
		return
	}

	# start array of rules
	$FirewallRuleSet = @()
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

	foreach ($Rule In $FirewallRules)
	{
		# iterate through rules
		if ($Rule.Group -like "")
		{
			Write-Host "Export Rule: [Ungrouped Rule] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
		}
		else
		{
			Write-Host "Export Rule: [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
		}

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
			Description = Convert-MultiLineToList $Rule.Description -JSON:$JSON
			Group = $Rule.Group
			Enabled = $Rule.Enabled
			Profile = $Rule.Profile
			Platform = Convert-ArrayToList $Rule.Platform
			Direction = $Rule.Direction
			Action = $Rule.Action
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LooseSourceMapping = $Rule.LooseSourceMapping
			LocalOnlyMapping = $Rule.LocalOnlyMapping
			Owner = $Rule.Owner
			LocalAddress = Convert-ArrayToList $AddressFilter.LocalAddress
			RemoteAddress = Convert-ArrayToList $AddressFilter.RemoteAddress
			Protocol = $PortFilter.Protocol
			LocalPort = Convert-ArrayToList $PortFilter.LocalPort
			RemotePort = Convert-ArrayToList $PortFilter.RemotePort
			IcmpType = Convert-ArrayToList $PortFilter.IcmpType
			DynamicTarget = $PortFilter.DynamicTarget
			# TODO: need to see why is this needed
			Program = $ApplicationFilter.Program -Replace "$($ENV:SystemRoot.Replace("\","\\"))\\", "%SystemRoot%\" -Replace "$(${ENV:ProgramFiles(x86)}.Replace("\","\\").Replace("(","\(").Replace(")","\)"))\\", "%ProgramFiles(x86)%\" -Replace "$($ENV:ProgramFiles.Replace("\","\\"))\\", "%ProgramFiles%\"
			Package = $ApplicationFilter.Package
			Service = $ServiceFilter.Service
			InterfaceAlias = Convert-ArrayToList $InterfaceFilter.InterfaceAlias
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

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing rules to file"

	# Create target folder directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating exports directory $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	if ($JSON)
	{
		# output rules in JSON format
		if ((Split-Path -Extension $FileName) -ne ".json")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".json"
		}

		if ($Append)
		{
			# TODO: need to implement appending to JSON
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Appending to JSON not implemented"
			$FirewallRuleSet | ConvertTo-Json | Set-Content "$Folder\$FileName" -Encoding utf8
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in JSON file"
			$FirewallRuleSet | ConvertTo-Json | Set-Content "$Folder\$FileName" -Encoding utf8
		}
	}
	else
	{
		# output rules in CSV format
		if ((Split-Path -Extension $FileName) -ne ".csv")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".csv"
		}

		$FileExists = Test-Path -PathType Leaf -Path "$Folder\$FileName"

		if ($Append)
		{
			if ($FileExists)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Appending to CSV file"
				$FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";" |
				Select-Object -Skip 1 | Add-Content "$Folder\$FileName" -Encoding utf8
				return
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Not appending because no existing file"
			}
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in CSV file"
		$FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";" |
		Set-Content "$Folder\$FileName" -Encoding utf8
	}

	Write-Information -Tags "User" -MessageData "INFO: Exporting firewall rules done"
}

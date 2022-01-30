
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 Markus Scholtes
Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Exports firewall rules to a CSV or JSON file

.DESCRIPTION
Export-FirewallRule exports firewall rules to a CSV or JSON file.
Only local GPO rules are exported by default.
CSV files are semicolon separated (Beware! Excel is not friendly to CSV files).
All rules are exported by default, you can filter with parameter -Name, -Inbound, -Outbound,
-Enabled, -Disabled, -Allow and -Block.
If the export file already exists it's content will be replaced by default.

.PARAMETER Domain
Computer name from which to export rules, default is local GPO.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file, default is CSV format

.PARAMETER DisplayName
Display name of the rules to be processed. Wildcard character * is allowed.

.PARAMETER DisplayGroup
Display group of the rules to be processed. Wildcard character * is allowed.

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
Append exported rules to existing file.
By default file of same name is replaced with new content

.EXAMPLE
PS> Export-FirewallRule

Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.

.EXAMPLE
PS> Export-FirewallRule -Inbound -Allow

Exports all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory.

.EXAMPLE
PS> Export-FirewallRule -DisplayGroup ICMP* ICMPRules.json -json

Exports all ICMP firewall rules to the JSON file ICMPRules.json.

.INPUTS
None. You cannot pipe objects to Export-FirewallRule

.OUTPUTS
None. Export-FirewallRule does not generate any output

.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Following modifications by metablaster August 2020:
1. Applied formatting and code style according to project rules
2. Added switch to optionally append instead of replacing output file
3. Separated functions into their own scope
4. Added function to decode string into multi line
5. Added parameter to target specific policy store
6. Added parameter to specify directory, and crate it if it doesn't exist
7. Added more output streams for debug, verbose and info
8. Added parameter to export according to rule group
9. Changed minor flow and logic of execution
10. Make output formatted and colored
11. Added progress bar
December 2020:
1. Rename parameters according to standard name convention
2. Support resolving path wildcard pattern
January 2022:
1. Implemented appending to json

TODO: Export to excel

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallRule.md

.LINK
https://github.com/MScholtes/Firewall-Manager
#>
function Export-FirewallRule
{
	# TODO: Should be possible to use Format-RuleOutput function
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "Using Write-Host for color consistency")]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallRule.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

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
		[switch] $Allow,

		[Parameter()]
		[switch] $Block,

		[Parameter()]
		[switch] $Append
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Filter rules?
	# NOTE: because there are 3 possibilities for each of the below switches we use -like operator
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

	# Read firewall rules
	[array] $FirewallRules = @()

	# NOTE: Getting rules may fail for multiple reasons, there is no point to handle errors here
	if (($DisplayGroup -eq "") -or ($DisplayGroup -eq "*"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules"

		$FirewallRules += Get-NetFirewallRule -DisplayName $DisplayName -PolicyStore $Domain |
		Where-Object {
			($_.DisplayGroup -Like $DisplayGroup) -and ($_.Direction -like $Direction) -and `
			($_.Enabled -like $RuleState) -and ($_.Action -like $Action)
		}
	}
	else
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules - skip ungrouped rules"

		$FirewallRules += Get-NetFirewallRule -DisplayGroup $DisplayGroup -PolicyStore $Domain |
		Where-Object {
			($_.Direction -like $Direction) -and ($_.Enabled -like $RuleState) -and ($_.Action -like $Action)
		}
	}

	if ($FirewallRules.Length -eq 0)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] No rules were retrieved from firewall to export"
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: possible cause is either no match or an error ocurred"
		return
	}

	# Starting array of rules
	$FirewallRuleSet = @()
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

	# Counter for progress
	[int32] $RuleCount = 0

	foreach ($Rule In $FirewallRules)
	{
		$ProgressParams = @{
			Activity = "Exporting firewall rules according to file '$Filename'"
			PercentComplete = (++$RuleCount / $FirewallRules.Length * 100)
			CurrentOperation = "$($Rule.Direction)\$($Rule.DisplayName)"
			SecondsRemaining = (($FirewallRules.Length - $RuleCount + 1) / 10 * 60)
		}

		if (![string]::IsNullOrEmpty($Rule.DisplayGroup))
		{
			# TODO: for -Status to be consistent (to not repeat multiple times) we need to sort rules
			$ProgressParams.Status = $Rule.DisplayGroup
		}

		Write-Progress @ProgressParams

		# Iterate through rules
		if ([string]::IsNullOrEmpty($Rule.DisplayGroup))
		{
			Write-Host "Export Rule: $($Rule.DisplayName)" -ForegroundColor Cyan
		}
		else
		{
			Write-Host "Export Rule: [$($Rule.DisplayGroup)] -> $($Rule.DisplayName)" -ForegroundColor Cyan
		}

		# NOTE: Filters are what makes this script ultra slow, each takes approx 1 second
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

		# TODO: Using [ordered] will not work for PowerShell Desktop, however [ordered] was introduced in PowerShell 3.0
		# Add sorted hashtable to result
		$FirewallRuleSet += [PSCustomObject]@{
			Name = $Rule.Name
			DisplayName = $Rule.DisplayName
			Group = $Rule.Group
			DisplayGroup = $Rule.DisplayGroup
			Action = $Rule.Action
			Enabled = $Rule.Enabled
			Direction = $Rule.Direction
			Profile = $Rule.Profile
			Protocol = $PortFilter.Protocol
			LocalPort = Convert-ArrayToList $PortFilter.LocalPort
			RemotePort = Convert-ArrayToList $PortFilter.RemotePort
			IcmpType = Convert-ArrayToList $PortFilter.IcmpType
			LocalAddress = Convert-ArrayToList $AddressFilter.LocalAddress
			RemoteAddress = Convert-ArrayToList $AddressFilter.RemoteAddress
			Service = $ServiceFilter.Service
			Program = $ApplicationFilter.Program
			InterfaceType = $InterfaceTypeFilter.InterfaceType
			InterfaceAlias = Convert-ArrayToList $InterfaceFilter.InterfaceAlias
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LocalUser = $SecurityFilter.LocalUser
			RemoteUser = $SecurityFilter.RemoteUser
			Owner = Restore-IfBlank $Rule.Owner
			Package = Restore-IfBlank $ApplicationFilter.Package
			LooseSourceMapping = $Rule.LooseSourceMapping
			LocalOnlyMapping = $Rule.LocalOnlyMapping
			Platform = Convert-ArrayToList $Rule.Platform
			Description = Convert-MultiLineToList $Rule.Description -JSON:$JSON
			DynamicTarget = $PortFilter.DynamicTarget
			RemoteMachine = $SecurityFilter.RemoteMachine
			Authentication = $SecurityFilter.Authentication
			Encryption = $SecurityFilter.Encryption
			OverrideBlockRules = $SecurityFilter.OverrideBlockRules
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing rules to file"

	$Path = Resolve-FileSystemPath $Path -Create
	if (!$Path)
	{
		# Errors if any, reported by Resolve-FileSystemPath
		return
	}

	# NOTE: Split-Path -Extension is not available in Windows PowerShell
	$FileExtension = [System.IO.Path]::GetExtension($FileName)

	# HACK: For some very odd reason rule properties Action, Enabled, Direction and Profile will
	# be saved as numbers, and odd enough it will work for import.
	# This happens after ConvertTo-Json, $FirewallRuleSet variable contains string values
	if ($JSON)
	{
		# Output rules in JSON format
		if (!$FileExtension -or ($FileExtension -ne ".json"))
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".json"
		}

		if ($Append)
		{
			if (Test-Path -PathType Leaf -Path "$Path\$FileName")
			{
				$JsonFile = ConvertFrom-Json -InputObject (Get-Content -Path "$Path\$FileName" -Raw)
				@($JsonFile; $FirewallRuleSet) | ConvertTo-Json |
				Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Not appending rule to file because no existing file"
			}
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in JSON file"
			$FirewallRuleSet | ConvertTo-Json | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
	}
	else
	{
		# Output rules in CSV format
		if (!$FileExtension -or ($FileExtension -ne ".csv"))
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".csv"
		}

		if ($Append)
		{
			if (Test-Path -PathType Leaf -Path "$Path\$FileName")
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Appending to CSV file"
				$FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";" |
				Select-Object -Skip 1 | Add-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
			}
			else
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Not appending rule to file because no existing file"
			}
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Replacing content in CSV file"
			$FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";" |
			Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
		}
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall rules into '$FileName' done"
}

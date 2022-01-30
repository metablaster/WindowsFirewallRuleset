
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
Exports firewall rules to a CSV or JSON file from registry

.DESCRIPTION
Export-RegistryRule exports firewall rules to a CSV or JSON file directly from registry.
Only local GPO rules are exported by default.
CSV files are semicolon separated.
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
PS> Export-RegistryRule

Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.

.EXAMPLE
PS> Export-RegistryRule -Inbound -Allow

Exports all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory.

.EXAMPLE
PS> Export-RegistryRule -DisplayGroup ICMP* ICMPRules.json -JSON

Exports all ICMP firewall rules to the JSON file ICMPRules.json.

.INPUTS
None. You cannot pipe objects to Export-RegistryRule

.OUTPUTS
None. Export-RegistryRule does not generate any output

.NOTES
TODO: Export to excel
Excel is not friendly to CSV files

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md

.LINK
https://github.com/MScholtes/Firewall-Manager
#>
function Export-RegistryRule
{
	# TODO: Should be possible to use Format-RuleOutput function
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "Using Write-Host for color consistency")]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md")]
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
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Exporting rules from registry"

	$FirewallRules += Get-RegistryRule -GroupPolicy -DisplayName $DisplayName -DisplayGroup $DisplayGroup |
	Where-Object {
		($_.Direction -like $Direction) -and ($_.Enabled -like $RuleState) -and ($_.Action -like $Action)
	}

	if ($FirewallRules.Length -eq 0)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] No rules were retrieved from registry to export"
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: possible cause is either no match or an error ocurred"
		return
	}

	# Starting array of rules
	$FirewallRuleSet = @()
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

	foreach ($Rule In $FirewallRules)
	{
		# Iterate through rules
		if ($Rule.DisplayGroup -like "")
		{
			Write-Host "Export Rule: $($Rule.DisplayName)" -ForegroundColor Cyan
		}
		else
		{
			Write-Host "Export Rule: [$($Rule.DisplayGroup)] -> $($Rule.DisplayName)" -ForegroundColor Cyan
		}

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
			Profile = Convert-ArrayToList $Rule.Profile
			Protocol = Restore-IfBlank $Rule.Protocol
			LocalPort = Convert-ArrayToList $Rule.LocalPort
			RemotePort = Convert-ArrayToList $Rule.RemotePort
			IcmpType = Convert-ArrayToList $Rule.IcmpType
			LocalAddress = Convert-ArrayToList $Rule.LocalAddress
			RemoteAddress = Convert-ArrayToList $Rule.RemoteAddress
			Service = Restore-IfBlank $Rule.Service
			Program = Restore-IfBlank $Rule.Program
			InterfaceType = Convert-ArrayToList $Rule.InterfaceType
			InterfaceAlias = Convert-ArrayToList $Rule.InterfaceAlias
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LocalUser = Restore-IfBlank $Rule.LocalUser
			RemoteUser = Restore-IfBlank $Rule.RemoteUser
			Owner = Restore-IfBlank $Rule.Owner
			Package = Restore-IfBlank $Rule.Package
			LooseSourceMapping = Restore-IfBlank $Rule.LooseSourceMapping -DefaultValue $false
			LocalOnlyMapping = Restore-IfBlank $Rule.LocalOnlyMapping -DefaultValue $false
			Platform = Convert-ArrayToList $Rule.Platform -DefaultValue @()
			Description = Convert-MultiLineToList $Rule.Description -JSON:$JSON
			# TODO: Not handled in Get-RegistryRule
			# DynamicTarget = $PortFilter.DynamicTarget
			# RemoteMachine = $SecurityFilter.RemoteMachine
			# Authentication = $SecurityFilter.Authentication
			# Encryption = $SecurityFilter.Encryption
			# OverrideBlockRules = $SecurityFilter.OverrideBlockRules
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

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall rules into: '$FileName' done"
}

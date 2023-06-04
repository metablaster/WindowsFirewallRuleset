
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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
Computer name from which rules are to be exported

.PARAMETER Path
Directory location into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file, default is CSV format

.PARAMETER DisplayName
Display name of the rules to be processed. Wildcard character * is allowed.
DisplayName is case sensitive.

.PARAMETER DisplayGroup
Display group of the rules to be processed. Wildcard character * is allowed.
DisplayGroup is case sensitive.

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

.PARAMETER Force
If specified does not prompt to replace existing file.

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
TODO: In one case no export file was made (with Backup-Firewall.ps1), rerunning again worked.
TODO: We should probably handle duplicate rule name entires, ex. replace or error,
because if file with duplicates is imported it will cause removal of duplicate rules.
TODO: Export CP firewall
NOTE: Exporting to REG makes no sense because reg file can't be simply imported or executed

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md

.LINK
https://github.com/MScholtes/Firewall-Manager
#>
function Export-RegistryRule
{
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
		[switch] $Append,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

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
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding .json extension to input file"
			$FileName += ".json"
		}
	}
	else
	{
		# Output rules in CSV format
		if (!$FileExtension -or ($FileExtension -ne ".csv"))
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding .csv extension to input file"
			$FileName += ".csv"
		}
	}

	$DestinationFile = "$Path\$FileName"
	$FileExists = Test-Path -Path $DestinationFile -PathType Leaf

	if ($FileExists)
	{
		if (!$Append -and !($Force -or $PSCmdlet.ShouldContinue($DestinationFile, "Replace existing export file?")))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Exporting firewall rules to '$FileName' was aborted"
			return
		}
	}
	elseif ($Append)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Exporting to new file because the specified file '$DestinationFile' does not exist"
	}

	#region ExportRules
	$FilterParams = @{
	}

	# Filter by direction
	if ($Inbound -and !$Outbound) { $FilterParams.Direction = "Inbound" }
	elseif (!$Inbound -and $Outbound) { $FilterParams.Direction = "Outbound" }

	# Filter by state
	if ($Enabled -and !$Disabled) { $FilterParams.Enabled = "True" }
	elseif (!$Enabled -and $Disabled) { $FilterParams.Enabled = "False" }

	# Filter by action
	if ($Allow -and !$Block) { $FilterParams.Action = "Allow" }
	elseif (!$Allow -and $Block) { $FilterParams.Action = "Block" }

	# Read firewall rules
	[array] $FirewallRules = @()
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall rules from registry on '$Domain' computer..."

	$FirewallRules = Get-RegistryRule -GroupPolicy -DisplayName $DisplayName -DisplayGroup $DisplayGroup -Domain $Domain @FilterParams

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
			Write-ColorMessage "Export Rule: $($Rule.DisplayName)" Cyan
		}
		else
		{
			Write-ColorMessage "Export Rule: [$($Rule.DisplayGroup)] -> $($Rule.DisplayName)" Cyan
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
	#endregion

	if ($JSON)
	{
		if ($Append -and $FileExists)
		{
			$JsonFile = ConvertFrom-Json -InputObject (Get-Content -Path $DestinationFile -Raw)
			@($JsonFile; $FirewallRuleSet) | ConvertTo-Json |
			Set-Content -Path $DestinationFile -Encoding $DefaultEncoding
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing rules to '$FileName'"
			$FirewallRuleSet | ConvertTo-Json | Set-Content -Path $DestinationFile -Encoding $DefaultEncoding
		}
	}
	else
	{
		$CsvData = $FirewallRuleSet | ConvertTo-Csv -NoTypeInformation -Delimiter ";"

		if ($Append -and $FileExists)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Appending to existing CSV file"
			$CsvData | Select-Object -Skip 1 |
			Add-Content -Path $DestinationFile -Encoding $DefaultEncoding
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing rules to '$FileName'"
			$CsvData | Set-Content -Path $DestinationFile -Encoding $DefaultEncoding
		}
	}

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: $($FirewallRules.Length) firewall rules were exported to '$FileName'"
}

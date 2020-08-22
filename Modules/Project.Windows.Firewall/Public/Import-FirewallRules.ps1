
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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
Imports firewall rules from a CSV or JSON file.
.DESCRIPTION
Imports firewall rules from with Export-FirewallRules generated CSV or JSON files.
CSV files have to be separated with semicolons.
Existing rules with same name will be overwritten.
.PARAMETER PolicyStore
Policy store into which to import rules, default is local GPO.
For more information about stores see:
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/FirewallParameters.md
.PARAMETER Folder
Path into which to save file
.PARAMETER FileName
Input file
.PARAMETER JSON
Input from JSON instead of CSV format
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Changes by metablaster - August 2020:
1. Applied formatting and code style according to project rules
2. Added parameter to target specific policy store
3. Separated functions into their own scope
4. Added function to decode string into multi line
5. Added parameter to let specify directory
6. Added more output streams for debug, verbose and info
7. Changed minor flow and logic of execution
8. Make output formatted and colored
.EXAMPLE
Import-FirewallRules
Imports all firewall rules in the CSV file FirewallRules.csv
If no file is specified, FirewallRules.json in the current directory is searched.
.EXAMPLE
Import-FirewallRules WmiRules.csv CSV
Imports all firewall rules in the SCV file WmiRules.csv
#>
function Import-FirewallRules
{
	[OutputType([void])]
	[CmdletBinding()]
	param(
		[Parameter()]
		[string] $PolicyStore = [System.Environment]::MachineName,

		[Parameter()]
		[string] $Folder = ".",

		[Parameter()]
		[string] $FileName = "FirewallRules",

		[Parameter()]
		[switch] $JSON
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($JSON)
	{
		# read JSON file
		if ((Split-Path -Extension $FileName) -ne ".json")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".json"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading JSON file"
		$FirewallRules = Get-Content "$Folder\$FileName" -Encoding utf8 | ConvertFrom-Json
	}
	else
	{
		# read CSV file
		if ((Split-Path -Extension $FileName) -ne ".csv")
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
			$FileName += ".csv"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading CSV file"
		$FirewallRules = Get-Content "$Folder\$FileName" -Encoding utf8 | ConvertFrom-Csv -Delimiter ";"
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

	# iterate rules
	foreach ($Rule In $FirewallRules)
	{
		# generate Hashtable for New-NetFirewallRule parameters
		$RuleSplatHash = @{
			Name = $Rule.Name
			Displayname = $Rule.Displayname
			Description = Convert-ListToMultiLine $Rule.Description -JSON:$JSON
			group = $Rule.Group
			Enabled = $Rule.Enabled
			Profile = $Rule.Profile
			Platform = Convert-ListToArray $Rule.Platform @()
			Direction = $Rule.Direction
			Action = $Rule.Action
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LooseSourceMapping = Convert-ValueToBoolean $Rule.LooseSourceMapping
			LocalOnlyMapping = Convert-ValueToBoolean $Rule.LocalOnlyMapping
			LocalAddress = Convert-ListToArray $Rule.LocalAddress
			RemoteAddress = Convert-ListToArray $Rule.RemoteAddress
			Protocol = $Rule.Protocol
			LocalPort = Convert-ListToArray $Rule.LocalPort
			RemotePort = Convert-ListToArray $Rule.RemotePort
			IcmpType = $Rule.IcmpType
			DynamicTarget = if ([string]::IsNullOrEmpty($Rule.DynamicTarget)) { "Any" } else { $Rule.DynamicTarget }
			Program = $Rule.Program
			Service = $Rule.Service
			InterfaceAlias = Convert-ListToArray $Rule.InterfaceAlias
			InterfaceType = $Rule.InterfaceType
			LocalUser = $Rule.LocalUser
			RemoteUser = $Rule.RemoteUser
			RemoteMachine = $Rule.RemoteMachine
			Authentication = $Rule.Authentication
			Encryption = $Rule.Encryption
			OverrideBlockRules = Convert-ValueToBoolean $Rule.OverrideBlockRules
		}

		# for SID types no empty value is defined, so omit if not present
		if (![string]::IsNullOrEmpty($Rule.Owner))
		{
			$LoginName = $(ConvertFrom-SID $Rule.Owner).Name

			if ([string]::IsNullOrEmpty($LoginName))
			{
				Write-Warning -Message "Importing rule '$($Rule.Displayname)' skipped, store app owner does not exist"
				continue
			}
			else
			{
				$RuleSplatHash.Owner = $Rule.Owner
			}
		}

		if (![string]::IsNullOrEmpty($Rule.Package))
		{
			$LoginName = $(ConvertFrom-SID $Rule.Package).Name

			if ([string]::IsNullOrEmpty($LoginName))
			{
				Write-Warning -Message "Importing rule '$($Rule.Displayname)' skipped, store app package does not exist"
				continue
			}
			else
			{
				$RuleSplatHash.Package = $Rule.Package
			}
		}

		# remove rule if present
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if rule exists"

		$IsRemoved = @()
		Remove-NetFirewallRule -Name $Rule.Name -PolicyStore $PolicyStore -ErrorAction SilentlyContinue -ErrorVariable IsRemoved

		if ($IsRemoved.Count -gt 0)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Not replacing rule"
		}
		else
		{
			Write-Information -MessageData "INFO: Replacing existing rule"
		}

		# generate new firewall rule, parameters are assigned with splatting
		New-NetFirewallRule -PolicyStore $PolicyStore @RuleSplatHash | Format-Output -Label "Import Rule"
	}

	Write-Information -Tags "User" -MessageData "INFO: Importing firewall rules from '$FileName' done"
}

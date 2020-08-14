
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
None. You cannot pipe objects to Convert-ListToArray
.OUTPUTS
[string[]] array from comma separated list
.NOTES
TODO: output type
TODO: DefaultValue can't be string, try string[]
#>
function Convert-ListToArray
{
	param(
		[Parameter()]
		[string] $List,

		[Parameter()]
		$DefaultValue = "Any"
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
None. You cannot pipe objects to Convert-ValueToBoolean
.OUTPUTS
[bool] of the input value
.NOTES
None.
#>
function Convert-ValueToBoolean
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
Convert encoded single line string to multi line string array
.DESCRIPTION
Convert encoded single line string to multi line CRLF string array
Input string `r is encoded as %% and `n as ||
.PARAMETER MultiLine
String which to convert
.PARAMETER JSON
Input string is from JSON file, meaning no need to decode
.EXAMPLE
Convert-ListToMultiLine "Some%%||String"
Produces:
Some
String
.INPUTS
None. You cannot pipe objects to Convert-ArrayToList
.OUTPUTS
[string] multi line string
.NOTES
None.
#>
function Convert-ListToMultiLine
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

	# replace encoded string with new line
	if ($JSON)
	{
		return $MultiLine
	}
	else
	{

		# For CSV files need to encode multi line rule description into single line
		return $MultiLine.Replace("%%", "`r").Replace("||", "`n")
	}
}

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

Changes by metablaster:
1. Applied formatting and code style according to project rules
2. Added parameter to target specific policy store
3. Separated functions into their own scope
4. Added function to decode string into multi line
5. Added parameter to let specify directory
6. Added more output streams for debug, verbose and info
TODO: maybe importing only specific rules from file?
TODO: maybe skip importing rules that already exist?
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
		if (![string]::IsNullOrEmpty($Rule.Owner)) { $RuleSplatHash.Owner = $Rule.Owner }
		if (![string]::IsNullOrEmpty($Rule.Package)) { $RuleSplatHash.Package = $Rule.Package }

		# remove rule if present
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if rule exists"
		Remove-NetFirewallRule -Name $Rule.Name -PolicyStore $PolicyStore -ErrorAction SilentlyContinue

		# generate new firewall rule, parameters are assigned with splatting
		New-NetFirewallRule -PolicyStore $PolicyStore @RuleSplatHash | Format-Output -Label "Import Rule"
	}

	Write-Information -Tags "User" -MessageData "INFO: Importing firewall rules done"
}

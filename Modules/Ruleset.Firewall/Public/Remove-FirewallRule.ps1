
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
Removes firewall rules according to a list in a CSV or JSON file

.DESCRIPTION
Removes firewall rules according to a with Export-FirewallRule generated list in a CSV or JSON file.
CSV files have to be separated with semicolons.
Only the field Name or - if Name is missing - DisplayName is used, all other fields can be omitted.

.PARAMETER Domain
Policy store from which remove rules, default is local GPO.

.PARAMETER Path
Folder in which file is located.
Wildcard characters are supported.

.PARAMETER FileName
File name according to which to delete rules

.PARAMETER JSON
Input file in JSON instead of CSV format

.EXAMPLE
PS> Remove-FirewallRule

Removes all firewall rules according to a list in the CSV file FirewallRules.csv in the current directory.

.EXAMPLE
Remove-FirewallRule WmiRules.json -JSON

Removes all firewall rules according to the list in the JSON file WmiRules.json.

.INPUTS
None. You cannot pipe objects to Remove-FirewallRule

.OUTPUTS
None. Remove-FirewallRule does not generate any output

.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Changes by metablaster - August 2020:
1. Applied formatting and code style according to project rules
2. Added parameter to target specific policy store
3. Added parameter to let specify directory
4. Added more output streams for debug, verbose and info
5. Make output formatted and colored
6. Changed minor flow of execution
December 2020:
1. Rename parameters according to standard name convention
2. Support resolving path wildcard pattern
TODO: implement removing rules not according to file

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Remove-FirewallRule.md

.LINK
https://github.com/MScholtes/Firewall-Manager
#>
function Remove-FirewallRule
{
	# TODO: Should be possible to use Format-RuleOutput function
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSAvoidUsingWriteHost", "", Scope = "Function", Justification = "Using Write-Host for color consistency")]
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Remove-FirewallRule.md")]
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
		[switch] $JSON
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ShouldProcess("Remove firewall rules according to file"))
	{
		$Path = Resolve-FileSystemPath $Path
		if (!$Path -or !$Path.Exists)
		{
			Write-Error -Category ResourceUnavailable -Message "The path was not found: $Path"
			return
		}

		# NOTE: Split-Path -Extension is not available in Windows PowerShell
		$FileExtension = [System.IO.Path]::GetExtension($FileName)

		if ($JSON)
		{
			# read JSON file
			if (!$FileExtension)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
				$FileName += ".json"
			}
			elseif ($FileExtension -ne ".json")
			{
				Write-Warning -Message "Unexpected file extension '$FileExtension'"
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading JSON file"
			Confirm-FileEncoding "$Path\$FileName"
			$FirewallRules = Get-Content "$Path\$FileName" -Encoding $DefaultEncoding | ConvertFrom-Json
		}
		else
		{
			# read CSV file
			if (!$FileExtension)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
				$FileName += ".csv"
			}
			elseif ($FileExtension -ne ".csv")
			{
				Write-Warning -Message "Unexpected file extension '$FileExtension'"
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading CSV file"
			Confirm-FileEncoding "$Path\$FileName"
			$FirewallRules = Get-Content "$Path\$FileName" -Encoding $DefaultEncoding | ConvertFrom-Csv -Delimiter ";"
		}

		# iterate rules
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

		foreach ($Rule In $FirewallRules)
		{
			$CurrentRule = $null

			if (![string]::IsNullOrEmpty($Rule.Name))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rule according to Name"
				$CurrentRule = Get-NetFirewallRule -PolicyStore $Domain -Name $Rule.Name -ErrorAction SilentlyContinue

				if (!$CurrentRule)
				{
					Write-Error -Category ObjectNotFound -TargetObject $Rule `
						-Message "Firewall rule `"$($Rule.Name)`" does not exist"
					continue
				}
			}
			else
			{
				if (![string]::IsNullOrEmpty($Rule.DisplayName))
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rule according to DisplayName"
					$CurrentRule = Get-NetFirewallRule -PolicyStore $Domain -DisplayName $Rule.DisplayName -ErrorAction SilentlyContinue

					if (!$CurrentRule)
					{
						Write-Error -Category ObjectNotFound -TargetObject $Rule `
							-Message "Firewall rule `"$($Rule.DisplayName)`" does not exist"
						continue
					}
				}
				else
				{
					Write-Error -Category ReadError -TargetObject $Rule `
						-Message "Failure in data record"
					continue
				}
			}

			Write-Host "Remove Rule: [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
			Remove-NetFirewallRule -PolicyStore $Domain -Name $CurrentRule.Name
		}

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing firewall rules according to '$FileName' done"
	}
}

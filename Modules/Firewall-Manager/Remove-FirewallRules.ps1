
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
Removes firewall rules according to a list in a CSV or JSON file.
.DESCRIPTION
Removes firewall rules according to a with Export-FirewallRules generated list in a CSV or JSON file.
CSV files have to be separated with semicolons. Only the field Name or - if Name is missing - DisplayName
is used, all other fields can be omitted
.PARAMETER CSVFile
Input file
.PARAMETER JSON
Input in JSON instead of CSV format
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15
.EXAMPLE
Remove-FirewallRules
Removes all firewall rules according to a list in the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Remove-FirewallRules WmiRules.json -json
Removes all firewall rules according to the list in the JSON file WmiRules.json.
#>
function Remove-FirewallRules
{
	[OutputType([System.Void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param(
		[Parameter()]
		[string] $CSVFile = ".\FirewallRules.csv",

		[Parameter()]
		[switch] $JSON
	)

	if ($PSCmdlet.ShouldProcess("Remove firewall rules according to file"))
	{
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
			$CurrentRule = $null
			if (![string]::IsNullOrEmpty($Rule.Name))
			{
				$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -Name $Rule.Name
				if (!$CurrentRule)
				{
					Write-Error "Firewall rule `"$($Rule.Name)`" does not exist"
					continue
				}
			}
			else
			{
				if (![string]::IsNullOrEmpty($Rule.DisplayName))
				{
					$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -DisplayName $Rule.DisplayName
					if (!$CurrentRule)
					{
						Write-Error "Firewall rule `"$($Rule.DisplayName)`" does not exist"
						continue
					}
				}
				else
				{
					Write-Error "Failure in data record"
					continue
				}
			}

			Write-Output "Removing firewall rule `"$($CurrentRule.DisplayName)`" ($($CurrentRule.Name))"
			Get-NetFirewallRule -EA SilentlyContinue -Name $CurrentRule.Name | Remove-NetFirewallRule
		}
	}
}

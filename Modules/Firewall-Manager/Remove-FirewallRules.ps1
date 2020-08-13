
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

Changes by metablaster:
1. Applied formatting and code style according to project rules
2. Added parameter to target specific policy store
3. Added parameter to let specify directory
TODO: need to have colored output as when removing rules with Format-Output
TODO: maybe removing only specific rules from file?
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
		[string] $PolicyStore = [System.Environment]::MachineName,

		[Parameter()]
		[string] $Folder = ".",

		[Parameter()]
		[string] $FileName = "FirewallRules",

		[Parameter()]
		[switch] $JSON
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("Remove firewall rules according to file"))
	{
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

		# iterate rules
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

		foreach ($Rule In $FirewallRules)
		{
			$CurrentRule = $null

			if (![string]::IsNullOrEmpty($Rule.Name))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rule according to Name"
				$CurrentRule = Get-NetFirewallRule -PolicyStore $PolicyStore -Name $Rule.Name -ErrorAction SilentlyContinue

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
					$CurrentRule = Get-NetFirewallRule -PolicyStore $PolicyStore -DisplayName $Rule.DisplayName -ErrorAction SilentlyContinue

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

			Write-Output "Removing firewall rule `"$($CurrentRule.DisplayName)`" ($($CurrentRule.Name))"
			Remove-NetFirewallRule -PolicyStore $PolicyStore -Name $CurrentRule.Name
		}
	}
}

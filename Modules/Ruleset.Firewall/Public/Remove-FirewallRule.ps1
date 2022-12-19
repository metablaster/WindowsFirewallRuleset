
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
Removes firewall rules according to Export-FirewallRule or Export-RegistryRule generated list in a
CSV or JSON file.
CSV files have to be separated with semicolons.
Only the field Name is used (or if Name is missing, DisplayName is used), all other fields can be omitted.

.PARAMETER Domain
Computer name from which remove rules, default is local GPO.

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
January 2022:
1. Added time measurement code
2. Added progress bar

TODO: implement removing rules not according to file
TODO: Remoting not finished

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Remove-FirewallRule.md

.LINK
https://github.com/MScholtes/Firewall-Manager
#>
function Remove-FirewallRule
{
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Remove-FirewallRule.md")]
	[OutputType([string])]
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

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	$Domain = Format-ComputerName $Domain

	if ($PSCmdlet.ShouldProcess("Windows GPO Firewall", "Remove firewall rules according to file '$FileName'"))
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
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Unexpected file extension '$FileExtension'"
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
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Unexpected file extension '$FileExtension'"
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading CSV file"
			Confirm-FileEncoding "$Path\$FileName"
			$FirewallRules = Get-Content "$Path\$FileName" -Encoding $DefaultEncoding | ConvertFrom-Csv -Delimiter ";"
		}

		# iterate rules
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Iterating rules"

		# Counter for progress
		[int32] $RuleCount = 0

		$StopWatch = [System.Diagnostics.Stopwatch]::new()
		$StopWatch.Start()

		foreach ($Rule In $FirewallRules)
		{
			# TODO: -SecondsRemaining needs to be updated after precise speed test
			$ProgressParams = @{
				Activity = "Removing firewall rules according to '$FileName'"
				PercentComplete = (++$RuleCount / $FirewallRules.Length * 100)
				SecondsRemaining = (($FirewallRules.Length - $RuleCount + 1) / 10 * 60)
			}

			if (![string]::IsNullOrEmpty($Rule.Group))
			{
				$ProgressParams.Status = "$($Rule.Direction)\$($Rule.Group)"
			}

			$CurrentRule = $null

			if (![string]::IsNullOrEmpty($Rule.Name))
			{
				if (![string]::IsNullOrEmpty($Rule.DisplayName))
				{
					$ProgressParams.CurrentOperation = $Rule.DisplayName
				}
				else
				{
					$ProgressParams.CurrentOperation = $Rule.Name
				}

				Write-Progress @ProgressParams
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Get rule according to Name"
				$CurrentRule = Get-NetFirewallRule -PolicyStore $Domain -Name $Rule.Name -ErrorAction SilentlyContinue

				if (!$CurrentRule)
				{
					Write-Error -Category ObjectNotFound -TargetObject $Rule `
						-Message "Firewall rule `"$($Rule.Name)`" does not exist"
					continue
				}
			}
			elseif (![string]::IsNullOrEmpty($Rule.DisplayName))
			{
				$ProgressParams.CurrentOperation = $Rule.DisplayName
				Write-Progress @ProgressParams

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
					-Message "Specified file contains an error and cannot be used to remove rules"
				continue
			}

			Write-ColorMessage "Remove Rule: [$($Rule | Select-Object -ExpandProperty Group)] -> $($Rule | Select-Object -ExpandProperty DisplayName)" Cyan
			Remove-NetFirewallRule -PolicyStore $Domain -Name $CurrentRule.Name
		}

		$StopWatch.Stop()
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing firewall rules according to '$FileName' done"

		$TotalHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
		$TotalMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
		$TotalSeconds = $StopWatch.Elapsed | Select-Object -ExpandProperty Seconds
		$TotalMinutes += $TotalHours * 60

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Total time needed to remove rules was: $TotalMinutes minutes and $TotalSeconds seconds"
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Get function or commandlet parameter aliases

.DESCRIPTION
Gets aliases of all or specific parameters for one or multiple functions or commandlets

.PARAMETER Command
One or more commandlets or/and functions for which to get parameter aliases

.PARAMETER CommandType
If specified, only commands of the specified type are processed

.PARAMETER Parameter
If specified gets aliases only for those parameters that match wildcard pattern

.PARAMETER Stream
Specify this parameter when you want to stream output object through the pipeline,
by default output object is formatted for output.

.EXAMPLE
PS> Get-ParameterAlias Test-DscConfiguration

.EXAMPLE
PS> Get-Command Enable-NetAdapter* | Get-ParameterAlias -Type Function

.EXAMPLE
PS> Get-parameterAlias * -Parameter "Computer*"

.EXAMPLE
PS> Get-parameterAlias * -Parameter "Computer*" -Stream | Where-Object { $_.Alias } |
Select-Object -ExpandProperty Alias -Unique

.INPUTS
[string]

.OUTPUTS
[System.Management.Automation.PSCustomObject]

.NOTES
None.
#>
function Get-ParameterAlias
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true,
			HelpMessage = "Enter the name of the commandlet or function")]
		[Alias("Function")]
		[SupportsWildcards()]
		[string[]] $Command,

		[Parameter(ValueFromRemainingArguments = $true)]
		[Alias("Type")]
		[ValidateSet("Cmdlet", "Function")]
		[string[]] $CommandType = @("Cmdlet", "Function"),

		[Parameter()]
		[SupportsWildcards()]
		[string] $Parameter = "*",

		[Parameter()]
		[switch] $Stream
	)

	process
	{
		# TODO: Warning out these errors instead
		foreach ($CommandItem in @(Get-Command -Name $Command -CommandType $CommandType -EA Ignore))
		{
			try
			{
				# Commands not valid for host or edition will report errors
				$TargetCommand = Get-Command -Name $CommandItem.Name -EA Stop
			}
			catch [System.Management.Automation.CommandNotFoundException]
			{
				Write-Warning -Message "Command $($CommandItem.Name) not found"
			}
			catch
			{
				Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
			}

			# Select only requested parameters and only those which have aliases
			$Parameters = $TargetCommand.Parameters.Values |
			Where-Object -Property Name -Like $Parameter |
			Where-Object -Property Aliases

			if ($Parameters)
			{
				Write-Output ""
				Write-Output "`tListing $($TargetCommand.CommandType): $($CommandItem.Name)"
				Write-Output ""

				$Format = !$Stream
				if ($Format -and ($Parameters | Select-Object -Property Aliases | Measure-Object).Count -gt 1)
				{
					# If there are multiple parameters Format-Table would insert header for each one
					Write-Verbose -Message "Forcing stream"
					$Format = $false
				}
			}

			foreach ($Param in $Parameters)
			{
				$OutputObject = [PSCustomObject]@{
					Parameter = $Param.Name
					Alias = $Param | Select-Object -ExpandProperty Aliases
				}

				if ($Format)
				{
					Write-Verbose -Message "Formatting output"
					Write-Output $OutputObject | Format-Table
				}
				else
				{
					Write-Verbose -Message "Streaming output"
					Write-Output $OutputObject
				}
			}
		}
	}
}

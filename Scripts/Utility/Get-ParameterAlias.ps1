
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

<#PSScriptInfo

.VERSION 0.9.1

.GUID 122f1ee2-ac42-4bd9-8dfb-9f21a5f3fd1f

.AUTHOR metablaster zebal@protonmail.com

.COPYRIGHT Copyright (C) 2020 metablaster zebal@protonmail.ch

.TAGS TemplateTag

.LICENSEURI https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE

.PROJECTURI https://github.com/metablaster/WindowsFirewallRuleset

.RELEASENOTES
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/CHANGELOG.md
#>

#Requires -Version 5.1

<#
.SYNOPSIS
Get function, commandlet or script parameter aliases

.DESCRIPTION
Gets aliases of all or specific parameters for one or multiple functions, commandlets or scripts.

.PARAMETER Command
One or more commandlets, functions or script names for which to get parameter aliases

.PARAMETER CommandType
If specified, only commands of the specified types are processed

.PARAMETER ParameterName
If specified, gets aliases only for those parameters that match wildcard pattern

.PARAMETER Stream
Specify this parameter when you want to stream output object through the pipeline,
by default output object is formatted for output.

.PARAMETER ShowCommon
If specified, aliases for common parameters will be shown as well

.PARAMETER Unique
if specified, case sensitive unique list of aliases is shown

.EXAMPLE
PS> Get-ParameterAlias Test-DscConfiguration

.EXAMPLE
PS> Get-ParameterAlias "Start*", "Stop-Process" -ShowCommon

.EXAMPLE
PS> Get-Command Enable-NetAdapter* | Get-ParameterAlias -Type Function

.EXAMPLE
PS> Get-parameterAlias "Remove*" -Parameter "Computer*"

.EXAMPLE
PS> Get-parameterAlias -Parameter "Computer*" -Stream -Unique

.INPUTS
[string]

.OUTPUTS
[string]
[System.Management.Automation.PSCustomObject]

.NOTES
The intended purpose of this function is to help name your parameters and their aliases.
For example if you want your function parameters to bind to pipeline by property name for
any 3rd party function that conforms to community development guidelines.
The end result is of course greater reusability of your code.
TODO: Implement filtering by parameter type
#>

[CmdletBinding(PositionalBinding = $false)]
[OutputType([System.Management.Automation.PSCustomObject], [string])]
param (
	[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias("Name")]
	[SupportsWildcards()]
	[string[]] $Command = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Type")]
	[ValidateSet("Cmdlet", "Function", "ExternalScript")]
	[string[]] $CommandType = @("Cmdlet", "Function"),

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Parameter")]
	[SupportsWildcards()]
	[string[]] $ParameterName = "*",

	[Parameter(ParameterSetName = "All")]
	[switch] $Stream,

	[Parameter()]
	[switch] $ShowCommon,

	[Parameter(ParameterSetName = "Unique")]
	[switch] $Unique
)

begin
{
	[array] $UniqueAlias = @()
	$InformationPreference = "Continue"

	# Common parameters
	$Common = @(
		"Confirm"
		"Debug"
		"ErrorAction"
		"ErrorVariable"
		"InformationAction"
		"InformationVariable"
		"OutVariable"
		"OutBuffer"
		"PipelineVariable"
		"Verbose"
		"WarningAction"
		"WarningVariable"
		"WhatIf"
	)
}
process
{
	Write-Debug -Message "params($($PSBoundParameters.Values))"

	foreach ($TargetCommand in @(Get-Command -Name $Command -CommandType $CommandType -ParameterName $ParameterName -EA SilentlyContinue -EV +NotFound))
	{
		$Params = $TargetCommand.Parameters.Values
		if (!$ShowCommon)
		{
			# Skip common parameters by default
			$Params = $Params | Where-Object {
				$_.Name -notin $Common
			}
		}

		[array] $OutputObject = @()
		foreach ($Param in $Params)
		{
			# Select only those parameters which have aliases
			if ($Param.Aliases.Count)
			{
				foreach ($ParameterItem in $ParameterName)
				{
					# Select only those parameters which match requested parameter wildcard
					if ($Param.Name -like $ParameterItem)
					{
						$OutputObject += [PSCustomObject]@{
							Command = $TargetCommand.Name
							$CommandType = $TargetCommand.CommandType
							Parameter = $Param.Name
							ParameterType = $Param.ParameterType
							Alias = $Param | Select-Object -ExpandProperty Aliases
							PSTypeName = "ParameterAlias"
						}
					}
				}
			}
		}

		if ($OutputObject.Count)
		{
			if ($Unique)
			{
				$UniqueAlias += $OutputObject.Alias | Where-Object {
					$_ -cnotin $UniqueAlias
				}
			}
			elseif ($Stream)
			{
				Write-Debug -Message "Streaming output"
				Write-Output $OutputObject
			}
			else
			{
				Write-Information ""
				Write-Information "`tListing $($TargetCommand.CommandType): $($TargetCommand.Name)"
				Write-Information ""

				Write-Debug -Message "Formatting output"
				Write-Output $OutputObject | Format-Table
			}
		}
	}
}
end
{
	if ($Unique -and $UniqueAlias.Count)
	{
		Write-Output $UniqueAlias
	}

	if ($NotFound)
	{
		# Show non found commands at the end
		foreach ($Item in $NotFound)
		{
			Write-Error -Message "Command $($Item.TargetObject) not found"
		}
	}
}

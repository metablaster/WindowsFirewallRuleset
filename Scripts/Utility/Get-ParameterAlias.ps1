
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

.TAGS Utility

.LICENSEURI https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE

.PROJECTURI https://github.com/metablaster/WindowsFirewallRuleset

.RELEASENOTES
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/CHANGELOG.md
#>

<#
.SYNOPSIS
Get parameter aliases

.DESCRIPTION
Gets aliases of all or specific parameters for one or multiple functions, commandlets, scripts or aliases.

.PARAMETER Command
One or more commandlet, function or script names or their alias names for which to get parameter aliases.
Enter a name or name pattern.
Wildcard characters are permitted.

.PARAMETER CommandType
If specified, only commands of the specified types are processed
Enter one or more command types.

.PARAMETER ParameterName
If specified, gets parameter aliases for parameters whose name or alias matches wildcard pattern
Enter parameter names or parameter aliases.
Wildcard characters are supported.

.PARAMETER ParameterType
If specified, gets parameter aliases of the specified parameter type
Enter the full name or partial name of a parameter type.
Wildcard characters are supported.

.PARAMETER TotalCount
Specifies maximum number of matching commands to process.
You can use this parameter to limit the output of a command.

.PARAMETER Stream
Specify this parameter when you want to stream output object through the pipeline,
by default output object is formatted for output.

.PARAMETER ShowCommon
If specified, aliases for common parameters will be shown as well

.PARAMETER Unique
if specified, only case sensitive unique list of aliases is shown

.EXAMPLE
PS> Get-ParameterAlias Test-DscConfiguration

.EXAMPLE
PS> Get-ParameterAlias "Start*", "Stop-Process" -ShowCommon

.EXAMPLE
PS> Get-Command Enable-NetAdapter* | Get-ParameterAlias -Type Function

.EXAMPLE
PS> Get-parameterAlias -Parameter "Computer*" -Count 4

.EXAMPLE
PS> Get-parameterAlias -Parameter "Computer*" -Unique

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
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "All")]
[OutputType([System.Management.Automation.PSCustomObject], [string])]
param (
	[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias("Name")]
	[SupportsWildcards()]
	[string[]] $Command = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Type")]
	[ValidateSet("Cmdlet", "Function", "ExternalScript", "Alias")]
	[string[]] $CommandType = @("Cmdlet", "Function"),

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Parameter")]
	[SupportsWildcards()]
	[string[]] $ParameterName = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[SupportsWildcards()]
	[System.Management.Automation.PSTypeName[]] $ParameterType = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Count")]
	[ValidateRange(0, [int32]::MaxValue)]
	[int32] $TotalCount = [int32]::MaxValue,

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

	# NOTE: Get-Command -ParameterName gets commands that have the specified parameter names or parameter aliases.
	foreach ($TargetCommand in @(Get-Command -Name $Command -CommandType $CommandType -ParameterType $ParameterType `
				-ParameterName $ParameterName -TotalCount $TotalCount -EA SilentlyContinue -EV +NotFound))
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
				foreach ($NameWildcard in $ParameterName)
				{
					# Select only those parameters which match requested parameter name or alias wildcard
					if (($Param.Name -like $NameWildcard) -or ($Param.Aliases -like $NameWildcard))
					{
						foreach ($TypeWildcard in $ParameterType)
						{
							# Select only those parameters which match requested parameter type wildcard
							if ($Param.ParameterType -like $TypeWildcard)
							{
								$OutputObject += [PSCustomObject]@{
									Command = $TargetCommand.Name
									$CommandType = $TargetCommand.CommandType
									ParameterName = $Param.Name
									ParameterType = $Param.ParameterType
									Alias = $Param | Select-Object -ExpandProperty Aliases
									PSTypeName = "ParameterAlias"
								}
							}
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
				if ($TargetCommand.CommandType -eq "Alias")
				{
					$DisplayCommand = Get-Alias -Name $TargetCommand.Name | Select-Object -ExpandProperty DisplayName
				}
				else
				{
					$DisplayCommand = $TargetCommand.Name
				}

				Write-Information ""
				Write-Information "`tListing $($TargetCommand.CommandType): $DisplayCommand"
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

	# Here to avoid duplicate log entries
	Update-Log

	if ($NotFound)
	{
		# Show non found commands at the end
		foreach ($Item in $NotFound)
		{
			# This could be either non found command or alias
			Write-Error -Category ObjectNotFound -Message "No matches for '$($Item.TargetObject)' found" -EV ThrowAway
		}
	}
}

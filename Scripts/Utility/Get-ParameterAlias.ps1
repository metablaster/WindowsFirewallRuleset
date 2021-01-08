
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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

.PARAMETER Count
Specifies maximum number of matching commands to process.
You can use this parameter to limit the output of a command.

.PARAMETER Stream
Specify this parameter when you want to stream output object through the pipeline,
by default output object is formatted for output.

.PARAMETER Exact
If specified, ParameterName pattern does not apply to parameter aliases.
Only parameter names (not parameter aliases) are matched against ParameterName pattern.

.PARAMETER ShowCommon
If specified, aliases for common parameters will be shown as well

.PARAMETER Unique
if specified, only case sensitive unique list of aliases is shown

.PARAMETER ListImported
If specified, only commands already imported into current session are processed.
By default modules for matched commands are imported into global scope.

.PARAMETER Cleanup
If specified removes all modules previously imported by Get-ParameterAlias from current session.
Other parameters are ignored and nothing except cleanup is performed.

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
[string[]]
[System.Management.Automation.PSTypeName[]]

.OUTPUTS
[string]
[System.Management.Automation.PSCustomObject]

.NOTES
The intended purpose of this function is to help name your parameters and their aliases.
For example if you want your function parameters to bind to pipeline by property name for
any 3rd party function that conforms to community development guidelines.
The end result is of course greater reusability of your code.
TODO: Some parameter aliases are not retrieved and it's not clear if this is a bug ex:
-Detailed and -Seconds
TODO: Need to revisit which parameters can be bound from pipeline from other functions and
update ValueFromPipeline arguments.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalVars", "", Justification = "Used because of simplicity")]
[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
[OutputType([System.Management.Automation.PSCustomObject], [string])]
param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias("Name")]
	[SupportsWildcards()]
	[string[]] $Command = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[Alias("Type")]
	[ValidateSet("Cmdlet", "Function", "ExternalScript", "Alias")]
	[string[]] $CommandType = @("Cmdlet", "Function"),

	[Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
	[Alias("Parameter")]
	[SupportsWildcards()]
	[string[]] $ParameterName = "*",

	[Parameter(ValueFromPipelineByPropertyName = $true)]
	[SupportsWildcards()]
	[System.Management.Automation.PSTypeName[]] $ParameterType = "*",

	[Parameter()]
	[Alias("TotalCount")]
	[ValidateRange(0, [int32]::MaxValue)]
	[int32] $Count = [int32]::MaxValue,

	[Parameter(ParameterSetName = "Default")]
	[switch] $Stream,

	[Parameter()]
	[switch] $Exact,

	[Parameter()]
	[switch] $ShowCommon,

	[Parameter(ParameterSetName = "Unique")]
	[switch] $Unique,

	[Parameter()]
	[switch] $ListImported,

	[Parameter()]
	[switch] $Cleanup
)

begin
{
	$InformationPreference = "Continue"

	# If dot sourced update format data only for current session
	if ($MyInvocation.InvocationName -eq ".")
	{
		$FormatFile = $($PSCommandPath + "xml")
		Write-Information -MessageData "INFO: Updating format data from: $((Get-Item $FormatFile).Name)"
		Update-FormatData -PrependPath $FormatFile
		break
	}

	if ($Cleanup)
	{
		if (Get-Variable -Name ImportedModules -Scope Global -ErrorAction Ignore)
		{
			$global:ImportedModules | ForEach-Object {
				Write-Information -MessageData "INFO: Removing module $($_.ModuleName) $($_.ModuleVersion)"
				Remove-Module -FullyQualifiedName $_
			}

			Remove-Variable -Name ImportedModules -Scope Global
		}

		break
	}

	if (!(Get-Variable -Name ImportedModules -Scope Global -ErrorAction Ignore))
	{
		# [Microsoft.PowerShell.Commands.ModuleSpecification[]]
		New-Variable -Name ImportedModules -Scope Global -Value @()
	}

	[array] $UniqueAlias = @()

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

	$ImportParams = @{
		NoClobber = $true
		DisableNameChecking = $true
		ErrorAction = "Stop"
	}

	if ($PSVersionTable.PSEdition -eq "Core")
	{
		$ImportParams.Add("SkipEditionCheck", $true)
	}
}

process
{
	Write-Debug -Message "params($($PSBoundParameters.Values))"

	if (!$ListImported)
	{
		# NOTE: The ParameterName and ParameterType parameters search only commands in the current session
		[array] $MissingModule = Get-Command -Name $Command -CommandType $CommandType | Where-Object {
			![string]::IsNullOrEmpty($_.ModuleName)
		} | Select-Object -ExpandProperty ModuleName -Unique

		foreach ($ModuleName in $MissingModule)
		{
			if (Get-Module -Name $ModuleName)
			{
				Write-Verbose -Message "Module '$ModuleName' already imported"
				continue
			}

			try
			{
				# [System.Management.Automation.PSModuleInfo]
				Import-Module -Name $ModuleName -Scope Global @ImportParams
				$ModuleInfo = Get-Module -Name $ModuleName | Select-Object Name, Version

				if ($ModuleInfo)
				{
					Write-Information -MessageData "INFO: Importing module $($ModuleInfo.Name) $($ModuleInfo.Version)"
					$global:ImportedModules += @{ModuleName = $ModuleInfo.Name; ModuleVersion = $ModuleInfo.Version }
				}
				else
				{
					Write-Warning -Message "Failed to import $ModuleName module"
				}
			}
			catch
			{
				Write-Verbose -Message "$($_.Exception.Message)"
			}
		}
	}

	# NOTE: Get-Command -ParameterName gets commands that have the specified parameter names or parameter aliases.
	foreach ($TargetCommand in @(Get-Command -Name $Command -CommandType $CommandType -ParameterType $ParameterType `
				-ParameterName $ParameterName -TotalCount $Count -ListImported:$ListImported -EA SilentlyContinue -EV +NotFound))
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
					# Select only those parameters which match requested parameter name or conditionally alias wildcard
					if (($Param.Name -like $NameWildcard) -or (!$Exact -and ($Param.Aliases -like $NameWildcard)))
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
									Module = $TargetCommand.ModuleName
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

				if ($TargetCommand.ModuleName)
				{
					$DisplayCommand += " [$($TargetCommand.ModuleName)]"
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
	# NOTE: Not used to avoid importing project modules
	# Update-Log

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

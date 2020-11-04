
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
Get .NET outputs of a commandlet or convert to/from type accelerator

.DESCRIPTION
Returns .NET output typename of a function or commandlet.
When piped, object's output typenames are handled per input.
In both cases input can be translated to/from type accelerator.
The function fails if output type is not .NET type

.PARAMETER InputObject
Target object for which to retrieve output typenames.
This is the actual output of some commandlet or function when passed to Get-TypeName,
either via pipeline or directly.

.PARAMETER Command
Commandlet or function name for which to retrieve OutputType attribute value
The command name can be specified either as "FUNCTIONNAME" or just FUNCTIONNAME

.PARAMETER Name
Translate full type name to accelerator or accelerator to full typename.
By default converts acceleartors to full typenames.
No conversion is done if resultant type already is of desired format.
The name of a type can be specified either as a "typename" or [typename] syntax

.PARAMETER Accelerator
When used converts resultant full typename to accelerator.
Otherwise if specified with 'Name' parameter, converts resultant accelerator to full name.
No conversion is done if resultant type already is of desired format.

.EXAMPLE
PS> Get-TypeName (Get-Process)

System.Diagnostics.Process

.EXAMPLE
PS> Get-TypeName -Command Get-Process

System.Diagnostics.ProcessModule
System.Diagnostics.FileVersionInfo
System.Diagnostics.Process

.EXAMPLE
PS> Get-TypeName -Name [switch]

System.Management.Automation.SwitchParameter

.EXAMPLE
PS> ([System.Environment]::MachineName) | Get-TypeName -Accelerator

string

.EXAMPLE
PS> Generate-Types | Get-TypeName | DealWith-TypeNames

Sends typename for each input object down the pipeline

.INPUTS
[System.Object]

.OUTPUTS
[string]

.NOTES
TODO: There may be multiple accelerators for same type, for example:
Get-TypeName -Name [System.Management.Automation.PSObject] -Accelerator

TODO: Use following code to detect .NET type:
[System.AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
	$_.GetTypes() | Where-Object {
		$_.Name -like "TYPENAME_HERE"
	}
}
#>
function Get-TypeName
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-TypeName.md")]
	[OutputType([string])]
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "Object")]
		[System.Object[]] $InputObject,

		[Parameter(Mandatory = $true, ParameterSetName = "Command")]
		[string] $Command,

		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[string] $Name,

		[Parameter()]
		[switch] $Accelerator
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
		[string] $TypeName = $null

		if ($InputObject)
		{
			# TODO: Could this fail somehow? if yes we need try/catch
			$TypeName = ($InputObject | Get-Member).TypeName | Select-Object -Unique

			if ($TypeName)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processed input object: $TypeName"

				if ($TypeName -as [type])
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Input object '$TypeName' is .NET type"
				}
				else
				{
					Write-Error -Category InvalidType -TargetObject $TypeName `
						-Message "Input object '$TypeName' is not a .NET type"
					return
				}
			}
			else
			{
				Write-Error -Category InvalidResult -TargetObject $TypeName `
					-Message "Input object '$InputObject' could not be resolved to type"
				return
			}
		}
		elseif ($Command)
		{
			# [System.Management.Automation.CmdletInfo]
			if ($CmdletInfo = Get-Command -Name $Command -ErrorAction Ignore)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing command: $($CmdletInfo.Name)"
				# NOTE: The value of the OutputType property of a FunctionInfo object is an array of
				# [System.Management.Automation.PSTypeName] objects, each of which have Name and Type properties.
				# NOTE: PSTypeName represents Type, but can be used where a real type might not be available,
				# in which case the name of the type can be used.
				$OutputType = ($CmdletInfo).OutputType

				if ($OutputType)
				{
					[string[]] $TypeName = $null
					[string[]] $CommandOutputs = $OutputType.Name

					# Exclude non .NET types from OutputType
					foreach ($Type in $CommandOutputs)
					{
						if ($Type -as [type])
						{
							$TypeName += $Type
							Write-Debug -Message "[$($MyInvocation.InvocationName)] The command '$Command' produces '$Type' which is .NET type"
						}
						else
						{
							# Skip non .NET types, continue
							Write-Warning -Message "Typename: '$Type' was excluded, not a .NET type"
						}
					}

					if (!$TypeName -or ($TypeName.Length -eq 0))
					{
						Write-Error -Category InvalidType -TargetObject $TypeName `
							-Message "The command '$Command' does not produce any .NET types"
						return
					}
				}
				else # No OutputType defined
				{
					# NOTE: The value of the OutputType property can be null.
					# It's a null value when the output is a not a .NET type,
					# such as a WMI object or a formatted view of an object.
					# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_outputtypeattribute?view=powershell-7
					Write-Warning -Message "The command: '$Command' does not have [OutputType()] attribute defined"
					return
				}
			}
			else # Get-Command failed
			{
				Write-Error -Category ObjectNotFound -TargetObject $Command `
					-Message "The command: '$Command' was not found in the current PowerShell session"
				return
			}
		}
		elseif ($Name)
		{
			$TypeName = $Name.Trim("[", "]")

			# if Name is not '[]'
			if (![string]::IsNullOrEmpty($TypeName) -and ($TypeName -as [type]))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Typename '$TypeName' is .NET type"
			}
			else
			{
				Write-Error -Category InvalidType -TargetObject $TypeName `
					-Message "Typename '$TypeName' is not a .NET type"
				return
			}
		}
		else
		{
			# TODO: Should not be allowed, but otherwise we won't be able to capture null/void type
			Write-Warning -Message "Input is null, typename implicitly set to: System.Void"
			$TypeName = "System.Void"
		}

		# Let both the -Name and -Accelerator in
		if ($Accelerator -or $Name)
		{
			# NOTE: This simplified solution isn't good because default accelerators are CamelCase
			# And if we omit ToLower() then we get first letter capital
			# ([type] $TypeName).Assembly.GetType($TypeName).Name.ToLower()
			$KeyValue = [PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() |
			Select-Object Key, Value

			$ShortName = $KeyValue | Select-Object -ExpandProperty Key
			$FullName = ($KeyValue | Select-Object -ExpandProperty Value).FullName

			# -Name purpose is to convert in both cases
			if (!$Accelerator -and $Name)
			{
				# For -Name convert from accelerator to full name
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting accelerator to full name for: $TypeName"

				if ($TargetValue = [array]::Find($ShortName, [System.Predicate[string]] { $TypeName -like $args[0] }))
				{
					$TypeName = $FullName[$([array]::IndexOf($ShortName, $TargetValue))]
				}
				else
				{
					# Not an error, the type is still valid .NET type
					Write-Warning -Message "Typename not recognized as accelerator: $TypeName"
				}

				# There is nothing else to do for -Name
				# return $TypeName
			}
			elseif ($Command)
			{
				# For -Command convert all .NET command OutputTypes from full name to accelerator
				[string[]] $CommandOutputs = $TypeName
				[string[]] $TypeName = $null

				# foreach will run more than once only for -Command -Accelerator
				foreach ($Type in $CommandOutputs)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting typename to accelerator for: $Type"
					if ($TargetValue = [array]::Find($FullName, [System.Predicate[string]] { $Type -like $args[0] }))
					{
						$TypeName += $ShortName[$([array]::IndexOf($FullName, $TargetValue))]
					}
					else
					{
						# Not an error, the type is still valid .NET type
						$TypeName += $Type
						Write-Warning -Message "No accelerator found for: $Type"
					}
				}
			}
			else
			{
				# Convert from full name to accelerator for:
				# -InputObject, -Name and System.Void
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting typename to accelerator for: $TypeName"
				if ($TargetValue = [array]::Find($FullName, [System.Predicate[string]] { $TypeName -like $args[0] }))
				{
					$TypeName = $ShortName[$([array]::IndexOf($FullName, $TargetValue))]
				}
				else
				{
					# Not an error, the type is still valid .NET type
					Write-Warning -Message "No accelerator found for: $TypeName"
				}
			}
		} # accelerator

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Success with the result of: $TypeName"
		Write-Output -InputObject $TypeName
	} # process
}

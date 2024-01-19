
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Get commandlet output typename, OutputType attribute or convert to/from type accelerator

.DESCRIPTION
Get-TypeName is a multipurpose type name getter, behavior of the function depends on
parameter set being used.
It can get type name of an object, OutputType attribute of a function or it could
convert type name to accelerator and vice versa (accelerator to full name).
By default the function works only for .NET types but you can force it handle user
defined PSCustomObject's

.PARAMETER InputObject
Target object for which to retrieve output typenames.
This is the actual output of some commandlet or function when passed to Get-TypeName,
either via pipeline or trough parameter.

.PARAMETER Command
Commandlet or function name for which to retrieve OutputType attribute value
The command name can be specified either as "FUNCTIONNAME" or just FUNCTIONNAME

.PARAMETER Name
Translate full type name to accelerator or accelerator to full typename.
By default converts acceleartors to full typenames.
No conversion is done if resultant type already is of desired format.
The name of a type can be specified either as a "typename" or [typename] syntax.
Type specified must be .NET type.

.PARAMETER Accelerator
When used converts resultant full typename to accelerator.
Otherwise If specified, with "Name" parameter, converts resultant accelerator to full name.
No conversion is done if resultant type already is of desired format.

.PARAMETER Force
If specified, the function doesn't check if type name is .NET type.
This is useful only for PSCustomObject types defined with PSTypeName.

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
[object[]]

.OUTPUTS
[string]

.NOTES
There may be multiple accelerators for same type, for example:
Get-TypeName -Name [System.Management.Automation.PSObject] -Accelerator
It's possible to rework function to get the exact type if this is desired see begin block
TODO: Will not work to detect .NET types for formatted output, see Get-FormatData
TODO: Will not work for non .NET types because we have no use of it, but should be implemented,
see Get-TypeName unit test
#>
function Get-TypeName
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-TypeName.md")]
	[OutputType([string])]
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "Object")]
		[object[]] $InputObject,

		[Parameter(Mandatory = $true, ParameterSetName = "Command")]
		[string] $Command,

		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[string] $Name,

		[Parameter()]
		[switch] $Accelerator,

		[Parameter(ParameterSetName = "Object")]
		[Parameter(ParameterSetName = "Command")]
		[switch] $Force
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
		$InvocationName = $MyInvocation.InvocationName

		# TODO: This scriptblock should probably be a separate function called "Trace-TypeName" which would serve for troubleshooting
		[ScriptBlock] $CheckType = {
			param (
				[Parameter()]
				[string] $TypeName
			)

			# NOTE: The result for some types isn't the same here, ex:
			# PSCustomObject -as Type is PSObject, while searching AppDomain it's PSCustomObject
			$Result = $TypeName -as [type]
			if (!$Result)
			{
				Write-Verbose -Message "[$InvocationName] Searching assemblies for type '$TypeName'"
				$Result = foreach ($Assembly in [System.AppDomain]::CurrentDomain.GetAssemblies())
				{
					try
					{
						$AssemblyTypes = $Assembly.GetTypes() | Where-Object {
							($_.Name -eq $TypeName) -or
							($_.FullName -eq $TypeName) -or
							($_.FullName -like "*.$TypeName")
						}
					}
					catch
					{
						# TODO: This might be the case sometimes with PS Core, it fails with $Assembly.GetTypes()
						# Investigate why there is no exception when running this code manually in the console, in which case it simply returns null
						if ($_.Exception.Message -match "Operation is not supported on this platform")
						{
							Write-Warning -Message "[$InvocationName] $($_.Exception.Message)"
						}
						else
						{
							Write-Error -ErrorRecord $_
						}
					}

					$AssemblyTypes | ForEach-Object {
						Write-Verbose -Message "[$InvocationName] Found type $($_.FullName) in assembly: $($Assembly.Location)"
						$_
					}
				}

				if (!$Result)
				{
					Write-Debug -Message "[$InvocationName] Searching assemblies for .NET type failed"
					return
				}
			}

			Write-Output $Result
		} # scriptblock
	}
	process
	{
		[string] $TypeName = $null

		if ($PSCmdlet.ParameterSetName -eq "Object")
		{
			if ($null -eq $InputObject)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Input is null, typename implicitly set to: System.Void"
				$TypeName = "System.Void"
			}
			else
			{
				$TypeName = $InputObject | Get-Member | Select-Object -ExpandProperty TypeName | Select-Object -Unique

				if ($TypeName)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processed input object '$TypeName'"

					if (!$Force)
					{
						if (& $CheckType $TypeName)
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
				}
				else
				{
					Write-Error -Category InvalidResult -TargetObject $TypeName `
						-Message "Input object '$InputObject' could not be resolved to type"
					return
				}
			}
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Command")
		{
			# [System.Management.Automation.CmdletInfo]
			if ($CmdletInfo = Get-Command -Name $Command -ErrorAction Ignore)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing command: $($CmdletInfo.Name)"
				# NOTE: The value of the OutputType property of FunctionInfo object is an array of
				# [System.Management.Automation.PSTypeName] objects, each of which have Name and Type properties.
				# PSTypeName represents Type, but can be used where a real type might not be available,
				# in which case the name of the type can be used.
				if ($CmdletInfo.OutputType)
				{
					[string[]] $TypeName = $null
					[string[]] $CommandOutputs = $CmdletInfo.OutputType.Name

					if ($Force)
					{
						$TypeName = $CommandOutputs
					}
					else
					{
						# Exclude non .NET types from OutputType
						foreach ($Type in $CommandOutputs)
						{
							if (& $CheckType $Type)
							{
								$TypeName += $Type
								Write-Debug -Message "[$($MyInvocation.InvocationName)] The command '$Command' produces '$Type' which is .NET type"
							}
							else
							{
								# Skip non .NET types, continue
								Write-Warning -Message "[$($MyInvocation.InvocationName)] Typename '$Type' was excluded, not a .NET type"
							}
						}

						if (!$TypeName -or ($TypeName.Length -eq 0))
						{
							Write-Error -Category InvalidType -TargetObject $TypeName `
								-Message "The command '$Command' does not produce any .NET types"
							return
						}
					}
				}
				else # No OutputType defined
				{
					# NOTE: The value of the OutputType property can be null.
					# It's a null value when the output is a not a .NET type,
					# such as a WMI object or a formatted view of an object.
					# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_outputtypeattribute
					Write-Warning -Message "[$($MyInvocation.InvocationName)] The command '$Command' does not have [OutputType()] attribute defined"
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
		elseif ($PSCmdlet.ParameterSetName -eq "Name")
		{
			$TypeName = $Name.Trim("[", "]")

			# if Name is not '[]'
			if (![string]::IsNullOrEmpty($TypeName) -and (& $CheckType $TypeName))
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
			throw "Parameter set not handled in $($MyInvocation.InvocationName)"
		}

		# Let both the -Accelerator and -Name without -Accelerator in
		if ($Accelerator -or $PSCmdlet.ParameterSetName -eq "Name")
		{
			# NOTE: This simplified solution isn't good because default accelerators are CamelCase
			# And if we omit ToLower() then we get first letter capital
			# ([type] $TypeName).Assembly.GetType($TypeName).Name.ToLower()
			$KeyValue = [PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() |
			Select-Object Key, Value

			$ShortName = $KeyValue | Select-Object -ExpandProperty Key
			$FullName = ($KeyValue | Select-Object -ExpandProperty Value).FullName

			# Find duplicates to report possible issues
			$RefObject = $KeyValue | Select-Object -ExpandProperty Value -Unique
			$DiffObject = $KeyValue | Select-Object -ExpandProperty Value
			$Comparison = Compare-Object -ReferenceObject $RefObject -DifferenceObject $DiffObject
			$Duplicates = ($Comparison | Select-Object -ExpandProperty InputObject).FullName

			# -Name purpose is to convert in both cases
			if (!$Accelerator -and $PSCmdlet.ParameterSetName -eq "Name")
			{
				# For -Name convert from accelerator to full name
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting accelerator to full name for '$TypeName'"

				if ($TargetValue = [array]::Find($ShortName, [System.Predicate[string]] { $TypeName -like $args[0] }))
				{
					$TypeName = $FullName[$([array]::IndexOf($ShortName, $TargetValue))]

					if ($Duplicates -contains $TypeName)
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Multiple accelerators exist for '$TypeName' type"
					}
				}
				else
				{
					# Not an error, the type is still valid .NET type
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Typename '$TypeName' not recognized as accelerator"
				}

				# There is nothing else to do for -Name
				# return $TypeName
			}
			elseif ($PSCmdlet.ParameterSetName -eq "Command")
			{
				# For -Command convert all .NET command OutputTypes from full name to accelerator
				[string[]] $CommandOutputs = $TypeName
				[string[]] $TypeName = $null

				# foreach will run more than once only for -Command -Accelerator
				foreach ($Type in $CommandOutputs)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting typename to accelerator for '$Type'"
					if ($TargetValue = [array]::Find($FullName, [System.Predicate[string]] { $Type -like $args[0] }))
					{
						$TypeName += $ShortName[$([array]::IndexOf($FullName, $TargetValue))]

						if ($Duplicates -contains $TargetValue)
						{
							Write-Warning -Message "[$($MyInvocation.InvocationName)] Multiple accelerators exist for type '$TargetValue'"
						}
					}
					else
					{
						# Not an error, the type is still valid .NET type
						$TypeName += $Type
						Write-Warning -Message "[$($MyInvocation.InvocationName)] No accelerator found for '$Type'"
					}
				}
			}
			else
			{
				# Convert from full name to accelerator for -InputObject, -Name and System.Void
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting typename to accelerator for '$TypeName'"
				if ($TargetValue = [array]::Find($FullName, [System.Predicate[string]] { $TypeName -like $args[0] }))
				{
					$TypeName = $ShortName[$([array]::IndexOf($FullName, $TargetValue))]

					if ($Duplicates -contains $TargetValue)
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Multiple accelerators exist for type '$TargetValue'"
					}
				}
				else
				{
					# Not an error, the type is still valid .NET type
					Write-Warning -Message "[$($MyInvocation.InvocationName)] No accelerator found for '$TypeName'"
				}
			}
		} # accelerator

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Success with the result of '$TypeName'"
		Write-Output $TypeName
	} # process
}

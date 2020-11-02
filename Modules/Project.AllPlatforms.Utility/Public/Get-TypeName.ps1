
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
Returns .NET type name for input object or command name

.DESCRIPTION
Unlike Get-Member commandlet returns only type name, and if
there are multiple types chooses unique ones only.

.PARAMETER InputObject
Target object for which to retrieve output type name.
This is the actual output of some commandlet or function

.PARAMETER Command
Commandlet or function name for which to retrieve OutputType attribute value

.PARAMETER Name
Translate full type name to accelerator or accelerator to full type name

.PARAMETER Accelerator
When used with 'Name' converts full type name to accelerator
Otherwise if specified converts type name to PowerShell accelerator if there exists one.

.EXAMPLE
PS> Get-TypeName (Get-Process)

System.Diagnostics.Process

.EXAMPLE
PS> Get-TypeName -Command Get-Process

System.Diagnostics.ProcessModule
System.Diagnostics.FileVersionInfo
System.Diagnostics.Process

.EXAMPLE
PS> Get-TypeName -Name "switch"

System.Management.Automation.SwitchParameter

.EXAMPLE
PS> ([System.Environment]::MachineName) | Get-TypeName -Accelerator

string

.EXAMPLE
PS> Generate-Types | Get-TypeName | DealWith-TypeNames

Sends typename for each input object down the pipeline

.INPUTS
System.Object

.OUTPUTS
System.String

.NOTES
None.
#>
function Get-TypeName
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-TypeName.md")]
	[OutputType([System.String])]
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

		if ($Name)
		{
			$TypeName = $Name
		}
		elseif ($InputObject)
		{
			$TypeName = ($InputObject | Get-Member).TypeName | Select-Object -Unique
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing input object: $TypeName"
		}
		elseif ($Command)
		{
			if ($CommandName = Get-Command -Name $Command -ErrorAction Ignore)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing command: $($CommandName.Name)"
				$TypeName = ($CommandName).OutputType.Name
			}
			else
			{
				Write-Error -Category ObjectNotFound -TargetObject $Command `
					-Message "Command: '$Command' was not found in the current PowerShell session"
				return
			}
		}
		else
		{
			Write-Warning -Message "Input is null, typename set to: System.Void"
			$TypeName = "System.Void"
		}

		if ($Accelerator -or $Name)
		{
			# NOTE: This simplified solution isn't good because default accelerators are CamelCase
			# And if we omit ToLower() then we get first letter capital
			# ([type] $TypeName).Assembly.GetType($TypeName).Name.ToLower()

			$KeyValue = [PSCustomObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() |
			Select-Object Key, Value

			$ShortName = $KeyValue | Select-Object -ExpandProperty Key
			$FullName = ($KeyValue | Select-Object -ExpandProperty Value).FullName

			if ($Name)
			{
				$TypeName = $Name
				if (!$Accelerator)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting accelerator to full name for: $Name"
					if ($TargetValue = [array]::Find($ShortName, [System.Predicate[string]] { $TypeName -like $args[0] }))
					{
						return $FullName[$([array]::IndexOf($ShortName, $TargetValue))]
					}
					else
					{
						Write-Warning -Message "Accelerator not recognized for: $Name"
						return
					}
				}
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Converting typename to accelerator for: $TypeName"
			if ($TargetValue = [array]::Find($FullName, [System.Predicate[string]] { $TypeName -like $args[0] }))
			{
				$TypeName = $ShortName[$([array]::IndexOf($FullName, $TargetValue))]
			}
			else
			{
				Write-Warning -Message "No accelerator found for: $TypeName"
				if ($Name) { return }
			}
		}

		Write-Output -InputObject $TypeName
	}
}

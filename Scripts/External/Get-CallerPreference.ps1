
<#
Microsoft Limited Public License (Ms-LPL)

Copyright (C) 2010 Microsoft Corporation. All rights reserved.

This license governs use of the accompanying software.
If you use the software, you accept this license.
If you do not accept the license, do not use the software.

1. Definitions

The terms "reproduce," "reproduction," "derivative works," and "distribution" have the same
meaning here as under U.S. copyright law.
A "contribution" is the original software, or any additions or changes to the software.
A "contributor" is any person that distributes its contribution under this license.
"Licensed patents" are a contributor's patent claims that read directly on its contribution.

2. Grant of Rights

(A) Copyright Grant - Subject to the terms of this license, including the license conditions and
limitations in section 3, each contributor grants you a non-exclusive, worldwide,
royalty-free copyright license to reproduce its contribution, prepare derivative works of its
contribution, and distribute its contribution or any derivative works that you create.
(B) Patent Grant - Subject to the terms of this license, including the license conditions and
limitations in section 3, each contributor grants you a non-exclusive, worldwide,
royalty-free license under its licensed patents to make, have made, use, sell, offer for sale,
import, and/or otherwise dispose of its contribution in the software or derivative works of the
contribution in the software.

3. Conditions and Limitations

(A) No Trademark License- This license does not grant you rights to use any contributors' name,
logo, or trademarks.
(B) If you bring a patent claim against any contributor over patents that you claim are infringed
by the software, your patent license from such contributor to the software ends automatically.
(C) If you distribute any portion of the software, you must retain all copyright, patent, trademark,
and attribution notices that are present in the software.
(D) If you distribute any portion of the software in source code form, you may do so only under this
license by including a complete copy of this license with your distribution.
If you distribute any portion of the software in compiled or object code form, you may only do so
under a license that complies with this license.
(E) The software is licensed "as-is." You bear the risk of using it.
The contributors give no express warranties, guarantees or conditions.
You may have additional consumer rights under your local laws which this license cannot change.
To the extent permitted under your local laws, the contributors exclude the implied warranties of
merchantability, fitness for a particular purpose and non-infringement.
(F) Platform Limitation - The licenses granted in sections 2(A) and 2(B) extend only to the software
or derivative works that you create that run on a Microsoft Windows operating system product.
#>

<#
.SYNOPSIS
Fetches "Preference" variable values from the caller's scope.

.DESCRIPTION
Script module functions do not automatically inherit their caller's variables,
but they can be obtained through the $PSCmdlet variable in Advanced Functions.
This function is a helper function for any script module Advanced Function;
by passing in the values of $ExecutionContext.SessionState and $PSCmdlet,
Get-CallerPreference will set the caller's preference variables locally.

.PARAMETER Cmdlet
The $PSCmdlet object from a script module Advanced Function.

.PARAMETER SessionState
The $ExecutionContext.SessionState object from a script module Advanced Function.
This is how the Get-CallerPreference function sets variables in its callers' scope,
even if that caller is in a different script module.

.PARAMETER Name
Optional array of parameter names to retrieve from the caller's scope.
Default is to retrieve all Preference variables as defined in the about_Preference_Variables
help file (as of PowerShell 4.0)
This parameter may also specify names of variables that are not in the
about_Preference_Variables help file, and the function will retrieve and set those as well.

.EXAMPLE
Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

Imports the default PowerShell preference variables from the caller into the local scope.

.EXAMPLE
Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.

.EXAMPLE
'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

Same as Example 2, but sends variable names to the Name parameter via pipeline input.

.INPUTS
String

.OUTPUTS
None. This function does not produce pipeline output.

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables

.LINK
https://devblogs.microsoft.com/scripting/weekend-scripter-access-powershell-preference-variables/

.LINK
https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d
#>
function Get-CallerPreference
{
	[CmdletBinding(DefaultParameterSetName = 'AllVariables')]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript( { $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
		$Cmdlet,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.SessionState] $SessionState,

		[Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
		[string[]] $Name
	)

	begin
	{
		$filterHash = @{}
	}

	process
	{
		if ($null -ne $Name)
		{
			foreach ($string in $Name)
			{
				$filterHash[$string] = $true
			}
		}
	}

	end
	{
		# List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

		$vars = @{
			'ErrorView' = $null
			'FormatEnumerationLimit' = $null
			'LogCommandHealthEvent' = $null
			'LogCommandLifecycleEvent' = $null
			'LogEngineHealthEvent' = $null
			'LogEngineLifecycleEvent' = $null
			'LogProviderHealthEvent' = $null
			'LogProviderLifecycleEvent' = $null
			'MaximumAliasCount' = $null
			'MaximumDriveCount' = $null
			'MaximumErrorCount' = $null
			'MaximumFunctionCount' = $null
			'MaximumHistoryCount' = $null
			'MaximumVariableCount' = $null
			'OFS' = $null
			'OutputEncoding' = $null
			'ProgressPreference' = $null
			'PSDefaultParameterValues' = $null
			'PSEmailServer' = $null
			'PSModuleAutoLoadingPreference' = $null
			'PSSessionApplicationName' = $null
			'PSSessionConfigurationName' = $null
			'PSSessionOption' = $null

			'ErrorActionPreference' = 'ErrorAction'
			'DebugPreference' = 'Debug'
			'ConfirmPreference' = 'Confirm'
			'WhatIfPreference' = 'WhatIf'
			'VerbosePreference' = 'Verbose'
			'WarningPreference' = 'WarningAction'
		}

		foreach ($entry in $vars.GetEnumerator())
		{
			if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
				($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
			{
				$variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)

				if ($null -ne $variable)
				{
					if ($SessionState -eq $ExecutionContext.SessionState)
					{
						Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
					}
					else
					{
						$SessionState.PSVariable.Set($variable.Name, $variable.Value)
					}
				}
			}
		}

		if ($PSCmdlet.ParameterSetName -eq 'Filtered')
		{
			foreach ($varName in $filterHash.Keys)
			{
				if (-not $vars.ContainsKey($varName))
				{
					$variable = $Cmdlet.SessionState.PSVariable.Get($varName)

					if ($null -ne $variable)
					{
						if ($SessionState -eq $ExecutionContext.SessionState)
						{
							Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
						}
						else
						{
							$SessionState.PSVariable.Set($variable.Name, $variable.Value)
						}
					}
				}
			}
		}
	} # end
} # function Get-CallerPreference

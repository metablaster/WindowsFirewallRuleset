
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Update PowerShell help files

.DESCRIPTION
Update-ModuleHelp updates help files for modules installed in PowerShell edition
which is used to run this function.
Unlike conventional Update-Help commandlet Update-ModuleHelp updates only those modules
for which update is possible without generating errors with update.

.PARAMETER Name
Updates help for the specified modules.
Enter one or more module names or name patterns in a comma-separated list.
Wildcard characters are supported.

.PARAMETER FullyQualifiedName
The value can be a module name, a full module specification, or a path to a module file.

When the value is a path, the path can be fully qualified or relative.
A relative path is resolved relative to the script that contains the using statement.

When the value is a name or module specification, PowerShell searches the PSModulePath for the specified module.
A module specification is a hashtable that has the following keys:

ModuleName - Required Specifies the module name.
GUID - Optional Specifies the GUID of the module.
It's also Required to specify at least one of the three below keys.
ModuleVersion - Specifies a minimum acceptable version of the module.
MaximumVersion - Specifies the maximum acceptable version of the module.
RequiredVersion - Specifies an exact, required version of the module. This can't be used with the other Version keys.

.PARAMETER UICulture
If specified, only modules supporting the specified UI culture are updated.
The default value is en-US

.EXAMPLE
PS> Update-ModuleModuleHelp

.EXAMPLE
PS> Update-ModuleHelp "PowerShellGet" -UICulture ja-JP, en-US

.INPUTS
None. You cannot pipe objects to Update-ModuleModuleHelp

.OUTPUTS
None. Update-ModuleModuleHelp does not generate any output

.NOTES
TODO: Not using ValueFromPipeline because an array isn't distinguished from hashtable to select
proper parameter set name
#>
function Update-ModuleHelp
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Name",
		SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
	[OutputType([void])]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Name", Position = 0)]
		[SupportsWildcards()]
		[Alias("Module")]
		[string[]] $Name = "*",

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "Full", Position = 0,
			HelpMessage = "Specify module to check in the form of ModuleSpecification object")]
		[Microsoft.PowerShell.Commands.ModuleSpecification[]] $FullyQualifiedName,

		[Parameter()]
		[ValidatePattern("^[a-z]{2}-[A-Z]{2}$")]
		[System.Globalization.CultureInfo[]] $UICulture = $DefaultUICulture
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		[PSModuleInfo[]] $UpdatableModules = @()
		Write-Information -Tags $MyInvocation.InvocationName `
			-MessageData "INFO: Checking online for module help updates..."
	}
	process
	{
		if ($PSCmdlet.ShouldProcess("PowerShell help system", "Update PowerShell $($PSVersionTable.PSEdition) help files"))
		{
			# TODO: If not using UICulture en-US errors may occur
			$UpdateParams = @{
				ErrorVariable = "UpdateError"
				ErrorAction = "SilentlyContinue"
				UICulture = $UICulture
			}

			if ($PSCmdlet.ParameterSetName -eq "Name")
			{
				$UpdatableModules = Find-UpdatableModuleHelp -Name $Name -UICulture $UICulture
				if ($UpdatableModules)
				{
					$UpdateParams.Module = $UpdatableModules | Select-Object -ExpandProperty Name
				}
			}
			elseif ($PSCmdlet.ParameterSetName -eq "Full")
			{
				$UpdatableModules = Find-UpdatableModuleHelp -FullyQualifiedName $FullyQualifiedName -UICulture $UICulture

				# TODO: This should be done in Find-UpdatableModuleHelp with Add-Member
				[Microsoft.PowerShell.Commands.ModuleSpecification[]] $ModuleSpecs = @()
				foreach ($ModuleItem in $UpdatableModules)
				{
					$ModuleSpecs += @{
						ModuleName = $ModuleItem.Name
						ModuleVersion = $ModuleItem.Version
						GUID = $ModuleItem.Guid
					}
				}

				if ($ModuleSpecs)
				{
					$UpdateParams.FullyQualifiedModule = $ModuleSpecs
				}
			}
			else
			{
				$UpdatableModules = Find-UpdatableModuleHelp
			}

			if (!$UpdatableModules)
			{
				# HACK: UpdatableModules may be null, failed on Enterprise edition with 0 found helpinfo files.
				# Even after updating modules and manually running Update-Help which btw. succeeded!
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Not all modules contain HelpInfo files required to update help"
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Please re-run 'Update-ModuleHelp' once again later"

				# Otherwise the cause may be because Update-Help was never run which is required to
				# download helpinfo.xml files
				# TODO: Thereofore Update-Help should be called twice?
				Update-Help @UpdateParams
			}
			else
			{
				if (($PSVersionTable.PSEdition -eq "Core") -and ($PSVersionTable.PSVersion -ge 6.1))
				{
					# The -Scope parameter was introduced in PowerShell Core version 6.1
					Update-Help @UpdateParams -Scope AllUsers
				}
				else
				{
					Update-Help @UpdateParams
				}

				# In almost all cases there will be one combined error, ignore that one
				if ($UpdateError -and (($UpdateError | Measure-Object).Count -gt 1))
				{
					$UpdateError
				}
			}
		}
	}
}

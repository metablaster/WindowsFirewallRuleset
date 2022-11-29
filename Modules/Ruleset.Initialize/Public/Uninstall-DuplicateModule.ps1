
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Uninstall duplicate modules

.DESCRIPTION
Uninstall-DuplicateModule uninstalls duplicate modules leaving only the most recent versions of a
module.

Sometimes uninstalling a module in conventional way is not possible, example cases are:
1. Modules which ship with system
2. Modules locked by other modules
3. Modules which prevent updating them

Updating modules which ship with system can't be done, only side by side installation is
possible, with the help of this function those outdated and useless modules are removed from system.

Case from point 2 is recommended only when there are 2 exactly same modules installed,
but the duplicate you are trying to remove is used (locked) instead of first one.

.PARAMETER Name
One or more module names which to uninstall if duplicates are found.
Wildcard characters are supported.

.PARAMETER Scope
Specifies one or more scopes (installation locations) in which to uninstall duplicate modules,
possible values are:
Shipping: Modules which are part of PowerShell installation
System: Modules installed for all users
User: Modules installed for current user

.EXAMPLE
PS> Uninstall-DuplicateModule -Name PowerShellGet, PackageManagement -Location Shipping, System

Removes outdated PowerShellGet and PackageManagement modules excluding those installed in user scope

.EXAMPLE
PS> Get-Module -FullyQualifiedName @{ModuleName = "PackageManagement"; RequiredVersion = "1.0.0.1" } | Uninstall-DuplicateModule

First get module you know should be removed and pass it to pipeline

.INPUTS
[PSModuleInfo[]] module object

.OUTPUTS
None. Uninstall-DuplicateModule does not generate any output

.NOTES
Target module must not be in use by:
1. Other PowerShell session
2. Some system process
3. Session in VSCode
Current session prompt must not point to anywhere in target module path
TODO: we make no automated use of this function except for manual module removal
TODO: Parameter needed which will specify which locations have priority to retain modules
#>
function Uninstall-DuplicateModule
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false)]
	[OutputType([void])]
	param (
		[Parameter(ValueFromPipeline = $true, Position = 0)]
		[SupportsWildcards()]
		[Alias("Module")]
		[string[]] $Name = "*",

		[Parameter()]
		[ValidateSet("Shipping", "System", "User")]
		[string[]] $Scope
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$ErrorActionPreference = "Stop"
		. $PSScriptRoot\..\Scripts\ModuleDirectories.ps1

		# Check if in elevated PowerShell
		# NOTE: can't be part of begin block
		# TODO: not tested if replacing with "Requires RunAs Administrator"
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking current user account elevation"
		$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

		if (!$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
		{
			Write-Error -Category PermissionDenied -TargetObject $Principal -ErrorAction Stop `
				-Message "Elevation required, please open PowerShell as Administrator and try again"
		}

		$SCopeParam = @{}
		if ($Scope) { $SCopeParam.Scope = $Scope }

		[PSModuleInfo[]] $Duplicates = @()
	}
	process
	{
		foreach ($Entry in $Name)
		{
			# Get all duplicates of a specific module name
			$Duplicates = Find-DuplicateModule -Name $Entry @SCopeParam

			if (!$Duplicates)
			{
				continue
			}

			# Iterate all duplicates until only latest version is left
			while ($Duplicates.Count -gt 1)
			{
				# Select lowest version, Find-DuplicateModule sorts modules in ascending order
				$TargetModule = $Duplicates | Select-Object -First 1

				$ModuleName = $TargetModule.Name
				$ModuleVersion = $TargetModule.Version
				$ModuleRoot = $TargetModule.ModuleBase

				if (!(Test-Path -LiteralPath $ModuleRoot -PathType Container))
				{
					Write-Error -Category ObjectNotFound -TargetObject $ModuleRoot `
						-Message "Following module path was not found '$ModuleRoot'"
					continue
				}

				if (!$PSCmdlet.ShouldProcess("$ModuleName $ModuleVersion", "Forced module uninstallation"))
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Operation aborted by user"
					continue
				}

				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Uninstalling module '$ModuleName $ModuleVersion'"

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Taking ownership of $ModuleName $ModuleVersion"

				if (Set-Permission -Owner "Administrators" -LiteralPath $ModuleRoot -Recurse -Confirm:$false -Force)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Granting permissions to Administrators group for $ModuleName $ModuleVersion"

					if (Set-Permission -User "Administrators" -LiteralPath $ModuleRoot -Reset -Recurse -Grant "FullControl" -Confirm:$false -Force)
					{
						try
						{
							# First we need to remove module if it's being used by this session
							[PSModuleInfo] $LoadedModule = Get-Module -Name $ModuleName

							if ($LoadedModule)
							{
								# -Force, Indicates that this cmdlet removes read-only modules.
								# By default, Remove-Module removes only read-write modules.
								Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing $ModuleName $ModuleVersion from current session"
								Remove-Module -Name $ModuleName -Force -ErrorAction Stop
							}

							# Remove all folders and files of a target module
							Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing recursively $ModuleName $ModuleVersion"
							Remove-Item -LiteralPath $ModuleRoot -Recurse -Confirm:$false -Force -ErrorAction Stop

							# Remove uninstalled module from duplicates variable
							$Duplicates = $Duplicates | Where-Object {
								$_.GUID -ne $TargetModule.GUID
							}
						}
						catch
						{
							Write-Error -ErrorRecord $_
							Write-Warning -Message "[$($MyInvocation.InvocationName)] Please close down all other PowerShell sessions including VSCode, then try again"

							if ($ModuleRoot -like "$($pwd.Path)*")
							{
								Write-Information -Tags $MyInvocation.InvocationName `
									-MessageData "INFO: This session's prompt is inside module path, the prompt must leave module path $($pwd.Path)"
							}
							continue
						}

						Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Module $ModuleName $ModuleVersion was removed"
						continue
					}
				}

				Write-Warning -Message "[$($MyInvocation.InvocationName)] Removing module $ModuleName $ModuleVersion failed"
			}
		}
	}
	end
	{
		if ($Duplicates)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Most recent versions of duplicates modules which where left installed are"

			Get-Module -Name $Duplicates.Name -ListAvailable | ForEach-Object {
				$Module = $_
				switch -Wildcard ($_.Path)
				{
					$ShippingPath* { $Module }
					$SystemPath* { $Module }
					$HomePath* { $Module }
					default { break }
				}
			}
		}
	}
}

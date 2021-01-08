
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

<#
.SYNOPSIS
Force uninstall module

.DESCRIPTION
Uninstall-DuplicateModule uninstalls modules which are otherwise not uninstallable, example cases are:
1. Modules that ship with system
2. Modules locked by other modules
3. Modules which prevent updating them

Updating modules which ship with system can't be done, only side by side installation is
possible, with the help of this function those outdated and useless modules are removed from system.

Case from point 2 is recommended only when there are 2 exactly same modules installed,
but the duplicate you are trying to remove is used (locked) instead of first one.

.PARAMETER Module
One or more explicit module objects which to uninstall.
No check for duplicity is performed and all supplied modules are removed.

.PARAMETER Name
One or more module names which to check for outdaness, and uninstall all outdated candidates.
Unlike with "Module" parameter, only outdated modules are uninstalled.

.PARAMETER Scope
Predefined default locations where too search for outdated modules.
Shipping: Modules installed as part of PowerShell
System: Modules installed for all users
User: Modules installed for current user

.PARAMETER Force
If specified, don't prompt for possibly dangerous actions

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
#>
function Uninstall-DuplicateModule
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		DefaultParameterSetName = "Name", PositionalBinding = $false)]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Module")]
		[PSModuleInfo[]] $Module,

		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[string[]] $Name,

		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[ValidateSet("Shipping", "System", "User")]
		[string[]] $Scope,

		[Parameter()]
		[switch] $Force
	)

	begin
	{
		# Check if in elevated PowerShell
		# NOTE: can't be part of begin block
		# TODO: not tested if replacing with "Requires RunAs Administrator"
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking user account elevation"
		$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

		if (!$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
		{
			Write-Error -Category PermissionDenied -TargetObject $Principal `
				-Message "Elevation required, please open PowerShell as Administrator and try again"
			throw $Principal
		}

		if ($Name)
		{
			if ($PSVersionTable.PSEdition -eq "Desktop")
			{
				# This location is reserved for modules that ship with Windows.
				# C:\Windows\System32\WindowsPowerShell\v1.0
				$ShippingPath = "$PSHome\Modules"

				# This location is for system wide modules install
				# C:\Program Files\WindowsPowerShell\Modules
				$SystemPath = "$Env:ProgramFiles\WindowsPowerShell\Modules"

				# This location is for per user modules install
				# C:\Users\USERNAME\Documents\WindowsPowerShell\Modules
				$HomePath = "$Home\Documents\WindowsPowerShell\Modules"
			}
			else
			{
				# C:\Program Files\PowerShell\7\Modules
				$ShippingPath = "$PSHome\Modules"

				# C:\Program Files\PowerShell\Modules
				$SystemPath = "$Env:ProgramFiles\PowerShell\Modules"

				# C:\Users\USERNAME\Documents\PowerShell\Modules
				$HomePath = "$Home\Documents\PowerShell\Modules"
			}

			# Total count of modules to uninstall
			[int32] $TotalRemoveCount = 0

			foreach ($ModuleName in $Name)
			{
				# All named candidates including most recent one
				[PSModuleInfo[]] $AllTargetModule = Get-Module -Name $ModuleName -ListAvailable

				if (!$AllTargetModule -or ($AllTargetModule.Length -lt 2))
				{
					Write-Warning -Message "No candidate modules for removal found with name '$ModuleName'"
					continue
				}

				# Named candidates for removal only
				[PSModuleInfo[]] $TargetModule = @()

				if ($Scope -contains "Shipping")
				{
					$TargetModule += $AllTargetModule | Where-Object -Property ModuleBase -Like $ShippingPath*
				}

				if ($Scope -contains "System")
				{
					$TargetModule += $AllTargetModule | Where-Object -Property ModuleBase -Like $SystemPath*
				}

				if ($Scope -contains "User")
				{
					if ($Scope.Length -gt 1)
					{
						Write-Warning "System wide modules might be removed in favor of user specific installation"
						Write-Information -Tags "User" -MessageData "INFO: To avoid this warning, please don't mix 'User' location with other locations"

						if (!($Force -or $PSCmdlet.ShouldContinue($Scope, "Accept dangerous comparison on all specified module locations")))
						{
							continue
						}
					}

					$TargetModule += $AllTargetModule | Where-Object -Property ModuleBase -Like $HomePath*
				}

				if (!$TargetModule -or ($TargetModule.Length -lt 2))
				{
					Write-Warning -Message "No duplicate modules for removal found with name '$ModuleName'"
					continue
				}

				# Count of current modules to remove
				$RemoveCount = $TargetModule.Length - 1

				# Default sort, from lowest to highest version, to process oldest modules first
				$TargetModule = $TargetModule | Sort-Object Version # -Descending = from highest to lowest

				Write-Information -Tags "User" -MessageData "INFO: Following module $ModuleName is the most recent one and will be kept"
				$TargetModule[$RemoveCount] | Select-Object -Property Name, ModuleBase, Version | Format-List

				# Select all but most recent one
				$Module += $TargetModule | Select-Object -First $RemoveCount
				$TotalRemoveCount += $RemoveCount

				Write-Information -Tags "User" -MessageData "INFO: The count of outdated $ModuleName modules selected for removal is $RemoveCount"
			} # foreach

			Write-Information -Tags "User" -MessageData "INFO: Total count of outdated modules selected for removal is $TotalRemoveCount as follows"
			$Module | Select-Object -Property Name, ModuleBase, Version | Format-List
		} # if Name
	}
	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($Item in $Module)
		{
			$ModuleVersion = $Item.Version
			$ModuleName = $Item.Name
			$ModuleRoot = $Item.ModuleBase

			if ($PSCmdlet.ShouldProcess("$ModuleName $ModuleVersion", "Forced module removal"))
			{
				if (Test-Path -Path $ModuleRoot -PathType Container)
				{
					Write-Information -Tags "User" -MessageData "INFO: Taking ownership of $ModuleName $ModuleVersion"
					if (Set-Permission -Owner "Administrators" -Path $ModuleRoot -Recurse -Confirm:$false -Force)
					{
						Write-Information -MessageData "INFO: Granting permissions to Administrators group for $ModuleName $ModuleVersion"
						if (Set-Permission -Principal "Administrators" -Path $ModuleRoot -Reset -Recurse -Grant "FullControl" -Confirm:$false -Force)
						{
							try
							{
								# First we need to remove module if it's being used by this session
								[PSModuleInfo] $LoadedModule = Get-Module -Name $ModuleName

								if ($LoadedModule)
								{
									# -Force, Indicates that this cmdlet removes read-only modules.
									# By default, Remove-Module removes only read-write modules.
									Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to remove module from current session"
									Remove-Module -Name $ModuleName -Force -ErrorAction Stop
								}

								# Remove all folders and files of a target module
								# TODO: This may fail if some files such as DLL's are in use by current session.
								Write-Information -Tags "User" -MessageData "INFO: Removing recursively $ModuleName $ModuleVersion"
								Remove-Item -Path $ModuleRoot -Recurse -Confirm:$false -Force -ErrorAction Stop
							}
							catch
							{
								Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
								Write-Warning -Message "Please close down all other PowerShell sessions including VSCode, then try again"
								Write-Information -Tags "User" -MessageData "INFO: If this session is inside module path, the session must be restarted"
								continue
							}

							Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName was removed"
							continue
						}
					}

					Write-Warning "Removing module $ModuleName failed"
				}
				else
				{
					Write-Error -Category ObjectNotFound -TargetObject $ModuleRoot `
						-Message "Following module path was not found: $ModuleRoot"
				} # Test-Path
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Operation aborted by user"
			} # ShouldProcess
		}
	}
}

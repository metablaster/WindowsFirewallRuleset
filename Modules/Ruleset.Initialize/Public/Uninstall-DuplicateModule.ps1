
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
Uninstall-DuplicateModule uninstalls duplicate modules per PS edition leaving only the most
recent versions of a module.

Sometimes uninstalling a module in a conventional way is not possible, example cases are:
1. Modules which ship with system
2. Modules locked by other modules
3. Modules which prevent updating them

Updating modules which ship with system can't be done, only side by side installation is
possible, with the help of this function those outdated and useless modules are removed from system.

Case from point 2 above is recommended only when there are 2 exactly same modules installed,
but the duplicate you are trying to remove is used (locked) instead of first one.

.PARAMETER Name
One or more module names which to uninstall if duplicates are found.
If not specified all duplicates are processed.
Wildcard characters are supported.

.PARAMETER Scope
Specifies one or more scopes (installation locations) from which to uninstall duplicate modules,
possible values are:
Shipping: Modules which are part of PowerShell installation
System: Modules installed for all users
User: Modules installed for current user

.PARAMETER Force
If specified, all duplicate modules specified by -Name are removed without further prompt.
This parameter also forces recursive actions on module installation directory,
ex taking ownership and setting file system permissions required for module uninstallation.
It also forces removing read only modules.

.EXAMPLE
PS> Uninstall-DuplicateModule -Name PowerShellGet, PackageManagement -Scope Shipping, System -Force

Removes outdated PowerShellGet and PackageManagement modules excluding those installed per user

.EXAMPLE
PS> Get-Module -FullyQualifiedName @{ModuleName = "PackageManagement"; RequiredVersion = "1.0.0.1" } |
Uninstall-DuplicateModule

First get module you know should be removed and pass it to pipeline

.INPUTS
[string] module name
[PSModuleInfo] module object by property Name

.OUTPUTS
None. Uninstall-DuplicateModule does not generate any output

.NOTES
Module which is to be uninstalled must not be in use by:
1. Other PowerShell session
2. Some system process
3. Session in VSCode
4. Current session prompt must not point to anywhere in target module path
TODO: Should support ShouldProcess
#>
function Uninstall-DuplicateModule
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Uninstall-DuplicateModule")]
	[OutputType([void])]
	param (
		[Parameter(ValueFromPipeline = $true, Position = 0)]
		[SupportsWildcards()]
		[Alias("Module")]
		[string[]] $Name = "*",

		[Parameter()]
		[ValidateSet("Shipping", "System", "User")]
		[string[]] $Scope,

		[Parameter()]
		[switch] $Force
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
		[string[]] $KeptModule = @()
	}
	process
	{
		foreach ($Entry in $Name)
		{
			# Get all duplicates of a specific module name
			$Duplicates = Find-DuplicateModule -Name $Entry @SCopeParam

			if ($Duplicates)
			{
				# Show duplicates for easy decision making on what to remove
				foreach ($Module in $Duplicates)
				{
					$Module
				}
			}
			else
			{
				continue
			}

			# Whether to remove all duplicates of a module currently processed
			$YesToAll = $false
			$NoToAll = $false

			# Iterate all duplicates until only latest version is left
			while ($Duplicates -and (($Duplicates | Measure-Object).Count -gt 1))
			{
				# Select lowest version, Find-DuplicateModule sorts modules in ascending order
				$TargetModule = $Duplicates | Select-Object -First 1

				$ModuleName = $TargetModule.Name
				$ModuleVersion = $TargetModule.Version
				$ModuleRoot = $TargetModule.ModuleBase

				# Keep track of duplicate module names for report
				$KeptModule += $ModuleName

				if (!(Test-Path -LiteralPath $ModuleRoot -PathType Container))
				{
					Write-Error -Category ObjectNotFound -TargetObject $ModuleRoot `
						-Message "The following module path was not found '$ModuleRoot'"
					continue
				}

				# If user doesn't want to remove currently processed module
				if (!$Force -and !$PSCmdlet.ShouldContinue("$ModuleName v$ModuleVersion module", "Duplicate module uninstallation", $true, ([ref] $YesToAll), ([ref] $NoToAll)))
				{
					# Remove current module from candidates for uninstallation
					$Duplicates = $Duplicates | Where-Object {
						$_.GUID -ne $TargetModule.GUID
					}

					Write-Warning -Message "[$($MyInvocation.InvocationName)] Operation to uninstall '$ModuleName v$ModuleVersion' module aborted by user"
					continue
				}

				Write-Information -Tags $MyInvocation.InvocationName `
					-MessageData "INFO: Uninstalling module '$ModuleName $ModuleVersion'"

				# First we need to remove module if it's being used by this session
				[PSModuleInfo] $LoadedModule = Get-Module -Name $ModuleName

				if ($LoadedModule)
				{
					# DOCS: -Force, Indicates that this cmdlet removes read-only modules.
					# By default, Remove-Module removes only read-write modules.
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing $ModuleName $ModuleVersion from current session"

					try
					{
						Remove-Module -Name $ModuleName -Force:$Force -ErrorAction Stop
					}
					catch
					{
						Write-Error -Category ResourceBusy -TargetObject $LoadedModule `
							-Message "Module '$ModuleName' could not be removed from current PS session which is required for uninstallation because: $($_.Exception.Message)"
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Please close down all other PowerShell sessions including VSCode, then try again"
						continue
					}
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Taking ownership of '$ModuleName $ModuleVersion' module"

				# -Force, skips prompting for confirmation to perform recursive action
				if (Set-Permission -Owner "Administrators" -LiteralPath $ModuleRoot -Recurse -Confirm:$false -Force:$Force)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Granting permissions to Administrators group on module '$ModuleName $ModuleVersion'"

					if (Set-Permission -User "Administrators" -LiteralPath $ModuleRoot -Reset -Recurse -Grant "FullControl" -Confirm:$false -Force:$Force)
					{
						# Remove all folders and files of a target module
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing recursively $ModuleName $ModuleVersion"
						try
						{
							# DOCS: -Force, forces the cmdlet to remove items that cannot otherwise be changed, such as hidden or read-only files
							Remove-Item -LiteralPath $ModuleRoot -Recurse -Confirm:$false -Force:$Force -ErrorAction Stop

							# Remove uninstalled module from duplicates variable
							$Duplicates = $Duplicates | Where-Object {
								$_.GUID -ne $TargetModule.GUID
							}
						}
						catch
						{
							Write-Error -Category OperationStopped -TargetObject $ModuleRoot `
								-Message "Module directory '$ModuleRoot' could not be recursively removed because: $($_.Exception.Message)"

							if ($ModuleRoot -like "$($pwd.Path)*")
							{
								Write-Information -Tags $MyInvocation.InvocationName `
									-MessageData "INFO: This session's prompt is inside module path, the prompt must leave module path $($pwd.Path)"
							}
							continue
						}

						Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Module $ModuleName $ModuleVersion was successfully removed"
						continue
					}
				}

				Write-Warning -Message "[$($MyInvocation.InvocationName)] Removing module $ModuleName $ModuleVersion failed"
			}
		}
	}
	end
	{
		$KeptModule = $KeptModule | Select-Object -Unique

		if (($KeptModule | Measure-Object).Count -gt 0)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: From the initial duplicates the following modules remained installed:"

			Get-Module -Name $KeptModule -ListAvailable | ForEach-Object {
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


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
Force remove module
.DESCRIPTION
Uninstall-DuplicateModule removes modules which are otherwise not removable, example cases are:
1. modules that ship with system
2. modules locked by other modules
Case from point 2 is recommended only when there are 2 exactly same modules installed,
but the duplicate you are trying to remove is used (locked) instead of first one
.PARAMETER Module
Explicit module object which to uninstall
.PARAMETER ModulePath
Full path to the module root installation directory,
Warning, if the root directory contains multiple module versions all of them will be uninstalled
.EXAMPLE
PS> Uninstall-DuplicateModule "C:\Users\User\Documents\PowerShell\Modules\PackageManagement"

Module PackageManagement was removed
.EXAMPLE
PS> Get-Module SomeDupeModule | Uninstall-DuplicateModule

Module SomeDupeModule was removed
.INPUTS
[string] path to module base
[PSModuleInfo] module object
.OUTPUTS
None.
.NOTES
Target module must not be in use by:
1. Other PowerShell session
2. Some system process
3. Session in VSCode
Current session prompt must not point to anywhere in target module path
TODO: array input and implement foreach
TODO: we make no automated use of this function except for manual module removal
#>
function Uninstall-DuplicateModule
{
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High',
		DefaultParameterSetName = "Path")]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
		[string] $ModulePath,

		[Parameter(Mandatory = $true, Position = 0,
			ValueFromPipeline = $true, ParameterSetName = "Module")]
		[PSModuleInfo] $Module
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# Check if in elevated PowerShell
		# NOTE: can't be part of begin block
		# TODO: not tested if replacing with "Requires RunAs Administrator"
		Write-Information -Tags "User" -MessageData "INFO: Checking user account elevation"
		$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

		if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
		{
			Write-Error -Category PermissionDenied -TargetObject $Principal `
				-Message "Elevation required, please open PowerShell as Administrator and try again"
			return
		}

		if ($Module)
		{
			$ModuleName = $Module.Name
			$ModuleRoot = $Module.ModuleBase
		}
		else
		{
			$ModuleName = Split-Path -Path $ModulePath -Leaf
			$ModuleRoot = $ModulePath
		}

		if ($PSCmdlet.ShouldProcess($ModuleName, "Forced module removal"))
		{
			if (Test-Path -Path $ModuleRoot)
			{
				Write-Information -Tags "User" -MessageData "INFO: Taking ownership of $ModuleRoot"
				# /a - Gives ownership to the Administrators group instead of the current user.
				# /r - Performs a recursive operation on all files in the specified directory and subdirectories.
				takeown /F $ModuleRoot /A /R

				Write-Information -MessageData "INFO: Replacing ACL's with default ACL's for $ModuleRoot"
				# Replaces ACLs with default inherited ACLs for all matching files
				icacls $ModuleRoot /reset

				Write-Information -MessageData "INFO: Adding Administrator permissions for $ModuleRoot"
				# /grant - Grants specified user access rights.
				# Permissions replace previously granted explicit permissions.
				# Not adding the :r, means that permissions are added to any previously granted explicit permissions.
				# /inheritance - Sets the inheritance level, which can be:
				# e - Enables inheritance
				# d - Disables inheritance and copies the ACEs
				# r - Removes all inherited ACEs
				icacls $ModuleRoot /grant "*S-1-5-32-544:F" /inheritance:d /T

				try
				{
					# Remove all folders and files of target module
					Write-Information -Tags "User" -MessageData "INFO: Removing recursively $ModuleRoot"
					Remove-Item -Path $ModuleRoot -Recurse -Force -Confirm:$false -ErrorAction Stop
				}
				catch
				{
					Write-Error -Message $_
					Write-Warning -Message "Please close down all other PowerShell sessions including VSCode, then try again"
					Write-Information -Tags "User" -MessageData "INFO: If this session is inside module path, the session must be restarted"
					return
				}

				Write-Information -Tags "User" -MessageData "INFO: Module $ModuleName was removed"
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

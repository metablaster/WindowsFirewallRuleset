
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

using namespace System.Security

<#
.SYNOPSIS
Take ownership or set permissions on file system or registry object

.DESCRIPTION
Set-Permission sets permission or ownership of a filesystem or registry object such as file,
folder, registry key or registry item.

.PARAMETER Path
Resource on which to set ownership or permissions.
Valid resources are files, directories, registry keys and registry entries.
Environment variables are allowed.

.PARAMETER Owner
Principal who will be the new owner of a resource.
Using this parameter means taking ownership of a resource.

.PARAMETER Principal
Principal to which to grant specified permissions.
Using this parameter means setting permissions on a resource.

.PARAMETER Domain
Principal domain such as computer name or authority to which principal applies

.PARAMETER Type
Access control type to either allow or deny specified rights

.PARAMETER Rights
Defines the access rights to use for principal when creating access and audit rules.
The default includes: ReadAndExecute, ListDirectory and Traverse
Where:
1. ReadAndExecute: Read and ExecuteFile
2. Read: ReadData, ReadExtendedAttributes, ReadAttributes, and ReadPermissions.

.PARAMETER Inheritance
Inheritance flags specify the semantics of inheritance for access control entries.
This parameter is ignored for leaf objects, such as files or or registry entries.
This parameter controls the "Applies to" column in advanced security dialog
The default is "This folder, subfolders and files"

.PARAMETER Propagation
Specifies how Access Control Entries (ACEs) are propagated to child objects.
These flags are significant only if inheritance flags are present, (when Inheritance is not "None")
This parameter is ignored for leaf objects, such as files or or registry entries.
This parameter affects the "Applies to" column in advanced security dialog

.PARAMETER Protected
If set, protect the specified access rules from inheritance.
The default is to allow inheritance.
Protected access rules cannot be modified by parent objects through inheritance.
This parameter controls the "Enable/Disable Inheritance" button in advanced security dialog

.PARAMETER PreserveInheritance
If set, preserve inherited access rules, which become explicit rules.
The default is to remove inherited access rules.
This parameter is ignored if Protected is not set.
This parameter controls choices offered after "Enable/Disable Inheritance" button.

.PARAMETER Recurse
If specified, applies specified operations to all subobjects.
This parameter is ignored for Leaf objects, such as files or registry entries.

.PARAMETER Reset
If specified, removes all explicit access rules and keeps only inherited.
if "Protected" parameter is specified inherited rules are removed as well.
If "Protected" is specified with "PreserveInheritance", then the inherited rules become
explicit rules and everything else is removed.

.PARAMETER Force
If specified skips prompting for confirmation.

.EXAMPLE
PS> Set-Permission -Principal "SomeUser" -Path "D:\SomePath"

Sets function defaults for user SomeUser on path D:\SomePath

.EXAMPLE
Set-Permission -Principal "Remote Management Users" -Path "D:\SomePath" -Protected

Only "Remote Management Users" have permissions on "D:\SomePath", other entries are removed

.EXAMPLE
PS> Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "D:\SomeFolder" `
	-Type "Deny" -Rights "TakeOwnership, Delete, Modify"

LanmanServer service is denied specified rights for specified directory and all it's contents

.EXAMPLE
PS> Set-Permission -Principal SomeUser -Domain COMPUTERNAME -Path "D:\SomeFolder"

Allows to ReadAndExecute, ListDirectory and Traverse to 'SomeFolder' and it's contents for COMPUTERNAME\SomeUser

.INPUTS
None. You cannot pipe objects to Set-Permission

.OUTPUTS
[bool]

.NOTES
TODO: Manage audit entries
TODO: Which combination is for "Replace all child object permissions with inheritable permissions from this object"
TODO: Which combination is for "Include inheritable permissions from this object's parent"
Set-Permission function is a wrapper around *-Acl commandlets for easier ACL editing.
This function also serves as replacement for takeown.exe and icacls.exe whose syntax is strange and
using these in PowerShell is usually awkward.
TODO: See Get-ChildItem -Force
TODO: Test on registry
TODO: See https://powershellexplained.com/2020-03-15-Powershell-shouldprocess-whatif-confirm-shouldcontinue-everything/
Links listed below are provided for additional parameter description in order of how parameters are declared

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.accesscontroltype?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setaccessruleprotection?view=dotnet-plat-ext-3.1
#>
function Set-Permission
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false, DefaultParameterSetName = "Reset",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Set-Permission.md")]
	[OutputType([bool])]
	param (
		[Alias("File", "Directory", "Key")]
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "Ownership")]
		[string] $Owner,

		[Alias("User")]
		[Parameter(Mandatory = $true, ParameterSetName = "Permission")]
		[string] $Principal,

		[Alias("Computer", "Server", "ComputerName", "Host", "Machine")]
		[Parameter()]
		[string] $Domain,

		[Parameter(ParameterSetName = "Permission")]
		[AccessControl.AccessControlType] $Type = "Allow",

		[Alias("Permission", "Grant")]
		[Parameter(ParameterSetName = "Permission")]
		[AccessControl.FileSystemRights] $Rights = "ReadAndExecute, ListDirectory, Traverse",

		[Parameter(ParameterSetName = "Permission")]
		[AccessControl.InheritanceFlags] $Inheritance = "ContainerInherit, ObjectInherit",

		[Parameter(ParameterSetName = "Permission")]
		[AccessControl.PropagationFlags] $Propagation = "None",

		[Parameter(ParameterSetName = "Reset")]
		[Parameter(ParameterSetName = "Permission")]
		[switch] $Protected,

		[Parameter(ParameterSetName = "Reset")]
		[Parameter(ParameterSetName = "Permission")]
		[switch] $PreserveInheritance,

		[Parameter()]
		[switch] $Recurse,

		[Parameter(ParameterSetName = "Permission")]
		[Parameter(Mandatory = $true, ParameterSetName = "Reset")]
		[switch] $Reset,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$RecurseMessage = ""
	if ($Recurse)
	{
		$RecurseMessage = " recursively"
	}

	if ($Owner)
	{
		$Principal = $Owner
		$Message = "Grant ownership$RecurseMessage to principal: $Principal"
	}
	elseif ($Principal)
	{
		$Message = "Grant permissions$RecurseMessage to principal: $Principal"
	}
	else
	{
		$Message = "Reset permissions$RecurseMessage"
	}

	if (!$PSCmdlet.ShouldProcess($Path, $Message))
	{
		Write-Warning -Message "The operation has been canceled by the user"
		return $false
	}

	if (!(Test-Path -Path $Path))
	{
		Write-Error -TargetObject $Path -Category ObjectNotFound -Message "Specified resource could not be found: '$Path'"
		return $false
	}
	elseif ($Recurse -and (Test-Path -Path $Path -PathType Leaf))
	{
		$Recurse = $false
		Write-Warning -Message "Recurse parameter ignored for leaf objects"
	}

	$Acl = Get-Acl -Path $Path

	if ($Reset)
	{
		# TODO: Test we get permissions to reset
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to reset"

		$IncludeExplicit = $true
		# TODO: This is not essential, IncludeInherited can be $false for all cases,
		# we keep it here to complete tests, remove when done.
		$IncludeInherited = $Protected -and !$PreserveInheritance

		# Get only explicit rules for both SID's
		$Acl.GetAccessRules($IncludeExplicit, $IncludeInherited, [Principal.SecurityIdentifier]) | ForEach-Object {
			if (!$Acl.RemoveAccessRule($_))
			{
				Write-Warning -Message "Removing SID based access rule for $($_.IdentityReference.Value) failed"
			}
		}

		# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.commonobjectsecurity.getaccessrules?view=dotnet-plat-ext-3.1
		# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.commonobjectsecurity.removeaccessrule?view=dotnet-plat-ext-3.1
		# Get only explicit rules for NTAccount's
		$Acl.GetAccessRules($IncludeExplicit, $IncludeInherited, [Principal.NTAccount]) | ForEach-Object {
			if (!$Acl.RemoveAccessRule($_))
			{
				Write-Warning -Message "Removing account based access rule for $($_.IdentityReference.Value) failed"
			}
		}

		# Need to reload object to make inherited values reappear if ACL is missing some or all of them
		if ($Protected -and $PreserveInheritance)
		{
			$Acl.SetAccessRuleProtection($false, $PreserveInheritance)
			Set-Acl -AclObject $Acl -Path $Path
			$Acl = Get-Acl -Path $Path
		}

		# Explicit rules were all removed, inherited will now be either inherited, removed or converted to explicit rules.
		$Acl.SetAccessRuleProtection($Protected, $PreserveInheritance)
		Set-Acl -AclObject $Acl -Path $Path
	}

	if ($Principal)
	{
		if ($Domain)
		{
			$NTAccount = New-Object -TypeName Principal.NTAccount($Domain, $Principal)
		}
		else
		{
			$NTAccount = New-Object -TypeName Principal.NTAccount($Principal)
		}

		try
		{
			# Verify account is valid
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Verifying if principal '$Principal' is valid"
			$NTAccount.Translate([Principal.SecurityIdentifier]).ToString() | Out-Null
		}
		catch
		{
			Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
			return $false
		}
	}

	if ($Owner)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to grant ownership to principal '$Principal'"

		$Acl.SetOwner($NTAccount)
		Set-Acl -AclObject $Acl -Path $Path
	}
	elseif ($Principal)
	{
		# Grant permission to principal for resource
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to grant specified permissions to principal '$Principal'"

		try
		{
			# Represents an abstraction of an access control entry (ACE) that defines an access rule for a file or directory
			if (Test-Path -Path $Path -PathType Leaf)
			{
				# Leaf. An element that does not contain other elements, such as a file or registry entry.
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Input path is leaf: '$(Split-Path -Path $Path -Leaf)'"
				$Permission = New-Object AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Type)
			}
			else
			{
				# Container. An element that contains other elements, such as a directory or registry key.
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Input path is container: '$(Split-Path -Path $Path -Leaf)'"
				$Permission = New-Object AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Inheritance, $Propagation, $Type)
			}

			# Sets or removes protection of the access rules associated with this resource.
			# Protected access rules cannot be modified by parent objects through inheritance.
			$Acl.SetAccessRuleProtection($Protected, $PreserveInheritance)

			# The SetAccessRule method adds the specified access control list (ACL) rule or overwrites any
			# identical ACL rules that match the FileSystemRights value of the rule parameter.
			$Acl.SetAccessRule($Permission)
		}
		catch
		{
			Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
			return $false
		}

		Set-Acl -AclObject $Acl -Path $Path
	}

	if ($Recurse)
	{
		# TODO: Will fail with "-Reset -Recurse -Protected"
		Write-Information -Tags "Project" -MessageData "INFO: Attempting to recursively set permissions on child objects"

		try
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Attempting to recursively get target resource directory tree"
			$ChildItems = Get-ChildItem -Path $Path -Recurse -ErrorAction Stop
		}
		catch
		{
			Write-Warning -Message "You have no permission to finish recursive action"
			if ($Force -or $PSCmdlet.ShouldContinue($Path, "Set required permissions to list directories and change permissions recursively"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions"

				# TODO: These minium required permissions should be removed when job is done
				# Set basic rights to change permissions on all child folders and files
				if ($Owner)
				{
					[AccessControl.FileSystemRights] $GrantFolders = "ListDirectory, TakeOwnership"
					[AccessControl.FileSystemRights] $GrantFiles = "TakeOwnership"
				}
				else
				{
					# TODO: Why is taking ownership not required for recursive *permission* set up?
					[AccessControl.FileSystemRights] $GrantFolders = "ListDirectory, ReadPermissions, ChangePermissions"
					[AccessControl.FileSystemRights] $GrantFiles = "ReadPermissions, ChangePermissions"
				}

				# NOTE: This may be called twice for each child container which fails in "try" block above,
				# It's needed to initiate recursing on this container
				Set-Permission -Path $Path -Principal $Principal -Rights $GrantFolders

				# TODO: Not sure if this will work without "ReadPermissions, ChangePermissions"
				Get-ChildItem -Path $Path -Directory | ForEach-Object {
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions on child container object: $($_.FullName)"
					Set-Permission -Path $_.FullName -Principal $Principal -Rights $GrantFolders -Recurse
				}

				Get-ChildItem -Path $Path -File -Recurse | ForEach-Object {
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions on child leaf object: $($_.FullName)"
					Set-Permission -Path $_.FullName -Principal $Principal -Rights $GrantFiles
				}

				# Now we should be able to get it
				$ChildItems = Get-ChildItem -Path $Path -Recurse -ErrorAction Stop
			}
			else
			{
				Write-Warning -Message "The operation has been canceled by the user"
				return $false
			}
		}
		finally
		{
			# These are manually set or not used here
			$PSBoundParameters.Remove("Path") | Out-Null
			$PSBoundParameters.Remove("Recurse") | Out-Null

			$ChildItems | ForEach-Object {
				# TODO: We end up with both inherited and explicit rules if inheritance is enabled
				# It would be preferred to avoid explicit rules if inheritance is enabled
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions on child object: $($_.FullName)"
				Set-Permission -Path $_.FullName @PSBoundParameters
			}
		}
	}

	return $true
}


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

using namespace System.Security

<#
.SYNOPSIS
Take ownership or set permissions on file system or registry object

.DESCRIPTION
Set-Permission sets permission or ownership of a filesystem or registry object such as file,
folder, registry key or registry item.

Set-Permission function is a wrapper around *-Acl commandlets for easier ACL editing.
This function also serves as replacement for takeown.exe and icacls.exe whose syntax is arcane.

.PARAMETER LiteralPath
Resource on which to set ownership or permissions.
Valid resources are files, directories, registry keys and registry entries.

.PARAMETER Owner
Principal username who will be the new owner of a resource.
Using this parameter means taking ownership of a resource.

.PARAMETER User
Principal username to which to grant specified permissions.
Using this parameter means setting permissions on a resource.

.PARAMETER Domain
Principal domain such as computer name or authority to which username applies

.PARAMETER Type
Access control type to either allow or deny specified rights

.PARAMETER Rights
Defines file system access rights to use for principal when creating access and audit rules.
The default includes: ReadAndExecute, ListDirectory and Traverse
Where:
1. ReadAndExecute: Read and ExecuteFile
2. Read: ReadData, ReadExtendedAttributes, ReadAttributes, and ReadPermissions.

.PARAMETER RegistryRights
Defines registry access rights to use for principal when creating access and audit rules.
The default includes: ReadKey
Where, ReadKey: QueryValues, Notify, EnumerateSubKeys and ReadPermissions

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
If specified, skips prompting for confirmation to perform recursive action

.EXAMPLE
PS> Set-Permission -User "SomeUser" -LiteralPath "D:\SomePath"

Sets function defaults for user SomeUser on path D:\SomePath

.EXAMPLE
PS> Set-Permission -User "Remote Management Users" -LiteralPath "D:\SomePath" -Protected

Only "Remote Management Users" have permissions on "D:\SomePath", other entries are removed

.EXAMPLE
PS> Set-Permission -User "LanmanServer" -Domain "NT SERVICE" -LiteralPath "D:\SomeFolder" `
	-Type "Deny" -Rights "TakeOwnership, Delete, Modify"

LanmanServer service is denied specified rights for specified directory and all it's contents

.EXAMPLE
PS> Set-Permission -User SomeUser -Domain COMPUTERNAME -LiteralPath "D:\SomeFolder"

Allows to ReadAndExecute, ListDirectory and Traverse to "SomeFolder" and it's contents for COMPUTERNAME\SomeUser

.INPUTS
None. You cannot pipe objects to Set-Permission

.OUTPUTS
[bool]

.NOTES
Set-Acl : Requested registry access is not allowed, unable to modify ownership happens because
PowerShell process does not have high enough privileges even if run as Administrator, a fix for this
is in Set-Privilege.ps1 which this function makes use of.

TODO: Manage audit entries
TODO: Which combination is for "Replace all child object permissions with inheritable permissions from this object"
TODO: Which combination is for "Include inheritable permissions from this object's parent"
TODO: See https://powershellexplained.com/2020-03-15-Powershell-shouldprocess-whatif-confirm-shouldcontinue-everything/
TODO: A switch to ignore errors and continue doing things, useful for recurse
TODO: A bunch of other security options can be implemented

Links listed below are provided for additional parameter description in order of how parameters are declared

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Permission.md

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.accesscontroltype?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryrights?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setaccessruleprotection?view=dotnet-plat-ext-3.1

.LINK
https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registrysecurity?view=dotnet-plat-ext-3.1
#>
function Set-Permission
{
	# DefaultParameterSetName = "Reset",
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Permission.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("LP")]
		[string] $LiteralPath,

		[Parameter(Mandatory = $true, ParameterSetName = "Ownership")]
		[string] $Owner,

		[Parameter(Mandatory = $true, ParameterSetName = "Registry")]
		[Parameter(Mandatory = $true, ParameterSetName = "FileSystem")]
		[Alias("UserName")]
		[string] $User,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[AccessControl.AccessControlType] $Type = "Allow",

		[Parameter(Mandatory = $true, ParameterSetName = "FileSystem")]
		[Alias("Permission", "Grant")]
		[AccessControl.FileSystemRights] $Rights, # = "ReadAndExecute, ListDirectory, Traverse",

		[Parameter(Mandatory = $true, ParameterSetName = "Registry")]
		[Alias("RegPermission", "RegGrant")]
		[AccessControl.RegistryRights] $RegistryRights, # = "ReadKey",

		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[AccessControl.InheritanceFlags] $Inheritance = "ContainerInherit, ObjectInherit",

		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[AccessControl.PropagationFlags] $Propagation = "None",

		[Parameter(ParameterSetName = "Reset")]
		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[switch] $Protected,

		[Parameter(ParameterSetName = "Reset")]
		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[switch] $PreserveInheritance,

		[Parameter()]
		[switch] $Recurse,

		[Parameter(ParameterSetName = "Registry")]
		[Parameter(ParameterSetName = "FileSystem")]
		[Parameter(Mandatory = $true, ParameterSetName = "Reset")]
		[switch] $Reset,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$RecurseMessage = ""
	if ($Recurse)
	{
		$RecurseMessage = " recursively"
	}

	if ($Owner)
	{
		$User = $Owner
		$Message = "Grant ownership$RecurseMessage to principal: $User"
	}
	elseif ($User)
	{
		$Message = "Grant permissions$RecurseMessage to principal: $User"
	}
	else
	{
		$Message = "Reset permissions$RecurseMessage"
	}

	if (!$PSCmdlet.ShouldProcess($LiteralPath, $Message))
	{
		Write-Warning -Message "The operation has been canceled by the user"
		return $false
	}

	# TODO: This will error if access to the path is denied
	if (!(Test-Path -LiteralPath $LiteralPath))
	{
		Write-Error -Category ObjectNotFound -TargetObject $LiteralPath `
			-Message "Specified resource could not be found: '$LiteralPath'"
		return $false
	}
	elseif ($Recurse -and (Test-Path -LiteralPath $LiteralPath -PathType Leaf))
	{
		$Recurse = $false
		Write-Warning -Message "Recurse parameter ignored for leaf objects"
	}

	$Acl = Get-Acl -LiteralPath $LiteralPath

	if ($Reset)
	{
		# TODO: "-Reset -Recurse -Protected" on it's own don't work because on first attempt to recurse nobody has rights any more
		# TODO: Reset ownership if that even makes sense?
		# TODO: Test we get permissions to reset, reset fails without permissions
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
			try
			{
				Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
			}
			catch
			{
				try
				{
					Write-Warning -Message $_.Exception.Message
					Set-Privilege SeSecurityPrivilege -ErrorAction Stop | Out-Null
					Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
				}
				catch
				{
					Write-Error -ErrorRecord $_
					return $false
				}
			}

			$Acl = Get-Acl -LiteralPath $LiteralPath
		}

		# Explicit rules were all removed, inherited will now be either inherited, removed or converted to explicit rules.
		$Acl.SetAccessRuleProtection($Protected, $PreserveInheritance)

		try
		{
			Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
		}
		catch
		{
			try
			{
				Write-Warning -Message $_.Exception.Message
				Set-Privilege SeSecurityPrivilege -ErrorAction Stop | Out-Null
				Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
			}
			catch
			{
				Write-Error -ErrorRecord $_
				return $false
			}
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Reset was done on object: $LiteralPath"
	}

	if ($User)
	{
		if ($Domain)
		{
			$NTAccount = New-Object -TypeName Principal.NTAccount($Domain, $User)
		}
		else
		{
			$NTAccount = New-Object -TypeName Principal.NTAccount($User)
		}

		try
		{
			# Verify account is valid
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Verifying if principal '$User' is valid"
			$NTAccount.Translate([Principal.SecurityIdentifier]).ToString() | Out-Null
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return $false
		}
	}

	if ($Owner)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to grant ownership to principal '$User'"

		$Acl.SetOwner($NTAccount)
		try
		{
			Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
		}
		catch
		{
			try
			{
				Write-Warning -Message $_.Exception.Message
				Set-Privilege SeSecurityPrivilege, SeTakeOwnershipPrivilege -ErrorAction Stop | Out-Null
				Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
			}
			catch
			{
				Write-Error -ErrorRecord $_
				return $false
			}
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Granting ownership was done on object: $LiteralPath"
	}
	elseif ($User)
	{
		# Grant permission to principal for resource
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Attempting to grant specified permissions to principal '$User'"

		try
		{
			# Represents an abstraction of an access control entry (ACE) that defines an access rule for a file or directory
			if (Test-Path -LiteralPath $LiteralPath -PathType Leaf)
			{
				# Leaf. An element that does not contain other elements, such as a file or registry entry.
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Specified path is leaf: '$(Split-Path -Path $LiteralPath -Leaf)'"
				if ($RegistryRights)
				{
					# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryaccessrule?view=dotnet-plat-ext-3.1
					$Permission = New-Object AccessControl.RegistryAccessRule($NTAccount, $RegistryRights, $Type)
				}
				else
				{
					# https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemaccessrule?view=dotnet-plat-ext-3.1
					$Permission = New-Object AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Type)
				}
			}
			else
			{
				# Container. An element that contains other elements, such as a directory or registry key.
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Specified path is container: '$(Split-Path -Path $LiteralPath -Leaf)'"
				if ($RegistryRights)
				{
					$Permission = New-Object AccessControl.RegistryAccessRule($NTAccount, $RegistryRights, $Inheritance, $Propagation, $Type)
				}
				else
				{
					$Permission = New-Object AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Inheritance, $Propagation, $Type)
				}
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
			Write-Error -ErrorRecord $_
			return $false
		}

		try
		{
			Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
		}
		catch
		{
			try
			{
				Write-Warning -Message $_.Exception.Message
				Set-Privilege SeSecurityPrivilege -ErrorAction Stop | Out-Null
				Set-Acl -AclObject $Acl -LiteralPath $LiteralPath -ErrorAction Stop
			}
			catch
			{
				Write-Error -ErrorRecord $_
				return $false
			}
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Granting permissions was done on object: $LiteralPath"
	}

	if ($Recurse)
	{
		# TODO: Will fail with "-Reset -Recurse -Protected"
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Performing recursive action"

		try
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Attempting to recursively get target resource directory tree"
			# NOTE: -Force, Allows the cmdlet to get items that otherwise can't be accessed by the user, such as hidden or system files.
			$ChildItems = Get-ChildItem -LiteralPath $LiteralPath -Recurse -Force -ErrorAction Stop
		}
		catch
		{
			if (!$User)
			{
				Write-Warning -Message "You have no permission to finish recursive action, please specify Principal and Rights"
				Write-Error -ErrorRecord $_
				return $false
			}

			Write-Warning -Message "You have no permission to finish recursive action"
			if ($Force -or $PSCmdlet.ShouldContinue($LiteralPath, "Set required permissions to list directories and change permissions recursively"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions"

				# TODO: These minium required permissions should be removed when job is done
				# Set basic rights to change permissions on all child folders and files
				if ($Owner)
				{
					if ($RegistryRights)
					{
						[Accesscontrol.RegistryRights] $GrantContainer = "EnumerateSubKeys, ReadPermissions, TakeOwnership"
						[Accesscontrol.RegistryRights] $GrantLeaf = "EnumerateSubKeys, ReadPermissions, TakeOwnership"
					}
					else
					{
						[AccessControl.FileSystemRights] $GrantContainer = "ListDirectory, TakeOwnership"
						[AccessControl.FileSystemRights] $GrantLeaf = "TakeOwnership"
					}
				}
				else # Setting permissions
				{
					if ($RegistryRights)
					{
						[Accesscontrol.RegistryRights] $GrantContainer = "EnumerateSubKeys, ReadPermissions"
						[Accesscontrol.RegistryRights] $GrantLeaf = "EnumerateSubKeys, ReadPermissions"
					}
					else
					{
						# TODO: Why is taking ownership not required for recursive *permission* set up?
						[AccessControl.FileSystemRights] $GrantContainer = "ListDirectory, ReadPermissions, ChangePermissions"
						[AccessControl.FileSystemRights] $GrantLeaf = "ReadPermissions, ChangePermissions"
					}
				}

				# NOTE: This may be called twice for each child container which fails in "try" block above,
				# It's needed to initiate recursing on this container
				Set-Permission -LiteralPath $LiteralPath -User $User -Rights $GrantContainer -Force -Confirm:$false | Out-Null

				# TODO: Not sure if this will work without "ReadPermissions, ChangePermissions", if yes remove them
				Get-ChildItem -LiteralPath $LiteralPath -Directory -Force | ForEach-Object {
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions on child container object: $($_.FullName)"
					Set-Permission -LiteralPath $_.FullName -User $User -Rights $GrantContainer -Recurse -Force -Confirm:$false | Out-Null
				}

				Get-ChildItem -LiteralPath $LiteralPath -File -Recurse -Force | ForEach-Object {
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions for recursive actions on child leaf object: $($_.FullName)"
					Set-Permission -LiteralPath $_.FullName -User $User -Rights $GrantLeaf -Force -Confirm:$false | Out-Null
				}

				try
				{
					# Now we should be able to get it
					$ChildItems = Get-ChildItem -LiteralPath $LiteralPath -Recurse -Force
				}
				catch
				{
					Write-Warning -Message "Recursive action failed on object: $LiteralPath"
					Write-Error -ErrorRecord $_
					return $false
				}
			}
			else
			{
				Write-Warning -Message "The operation has been canceled by the user"
				return $false
			}
		}

		if ($ChildItems)
		{
			# These are manually set or not used here
			$PSBoundParameters.Remove("LiteralPath") | Out-Null
			$PSBoundParameters.Remove("Recurse") | Out-Null

			$ChildItems | ForEach-Object {
				# TODO: We end up with both inherited and explicit rules if inheritance is enabled
				# It would be preferred to avoid explicit rules if inheritance is enabled
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Setting permissions on child object: $($_.FullName)"
				Set-Permission -LiteralPath $_.FullName @PSBoundParameters | Out-Null
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Recursive action is done on object: $LiteralPath"
			return $true
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] There are no subobjects to recurse for: $LiteralPath"
			return $false
		}
	} # Recurse

	return $true
}

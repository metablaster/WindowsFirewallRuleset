
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
Take ownership or set permission of file system object

.DESCRIPTION
Set-Permission sets permission or ownership of a filesystem object such as file, folder or registry key.

.PARAMETER Path
Resource on which to set ownership or permissions.
Valid resources are files, directories, registry keys and registry key items
Environment variables are allowed.

.PARAMETER Owner
Principal who will be the new owner of a resource.
Using this parameter means taking ownership of a resource.

.PARAMETER Principal
Principal to which to grant specified permissions.
Using this parameter means setting permissions on a resource.

.PARAMETER Domain
Domain such as computer name to which principal applies

.PARAMETER Type
Access control type to either allow or deny specified request

.PARAMETER Rights
Defines the access rights to use for principal when creating access and audit rules.
The default includes:
1. Read: ReadData, ReadExtendedAttributes, ReadAttributes, and ReadPermissions.
2. ReadAndExecute: Read and ExecuteFile
3. ReadAndExecute, ListDirectory and Traverse

.PARAMETER Inheritance
Inheritance flags specify the semantics of inheritance for access control entries.
This parameter is ignored for leaf objects, such as files or or registry entries.

.PARAMETER Propagation
Specifies how Access Control Entries (ACEs) are propagated to child objects.
These flags are significant only if inheritance flags are present.
This parameter is ignored for leaf objects, such as files or or registry entries.

.PARAMETER Protected
If set, protect the specified access rules from inheritance,
The default is to allow inheritance.

.PARAMETER PreserveInheritance
If set, preserve inherited access rules.
The default is to remove inherited access rules.
This parameter is ignored if Protected is not set.

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
[System.Boolean]

.NOTES
TODO: Manage audit entries
Set-Permission function is a wrapper around *-Acl commandlets for easier ACL editing.
This function also serves as replacement for takeown.exe and icacls.exe whose syntax is strange and
using these in PowerShell is usually awkward.
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
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Set-Permission.md")]
	[OutputType([bool])]
	param (
		[Alias("File", "Directory", "Key")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Ownership")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Permission")]
		[string] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "Ownership")]
		[string] $Owner,

		[Alias("User")]
		[Parameter(Mandatory = $true, ParameterSetName = "Permission")]
		[string] $Principal,

		[Alias("Computer", "Server", "ComputerName", "Host", "Machine")]
		[Parameter(ParameterSetName = "Ownership")]
		[Parameter(ParameterSetName = "Permission")]
		[string] $Domain,

		[Parameter(ParameterSetName = "Permission")]
		[System.Security.AccessControl.AccessControlType] $Type = "Allow",

		[Alias("Permission")]
		[Parameter(ParameterSetName = "Permission")]
		[System.Security.AccessControl.FileSystemRights] $Rights = "ReadAndExecute, ListDirectory, Traverse",

		[Parameter(ParameterSetName = "Permission")]
		[Security.AccessControl.InheritanceFlags] $Inheritance = "ContainerInherit, ObjectInherit",

		[Parameter(ParameterSetName = "Permission")]
		[System.Security.AccessControl.PropagationFlags] $Propagation = "None",

		[Parameter(ParameterSetName = "Permission")]
		[switch] $Protected,

		[Parameter(ParameterSetName = "Permission")]
		[switch] $PreserveInheritance
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($Owner)
	{
		$Principal = $Owner
		$Message = "Grant ownership to principal: $Principal"
	}
	else
	{
		$Message = "Grant permissions to principal: $Principal"
	}

	if (!$PSCmdlet.ShouldProcess($Path, $Message))
	{
		Write-Warning -Message "The operation has been canceled by the user"
		return $false
	}

	if (!(Test-Path -Path $Path))
	{
		return $false
	}

	$Acl = Get-Acl -Path $Path

	if ($Domain)
	{
		$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($Domain, $Principal)
	}
	else
	{
		$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount($Principal)
	}

	try
	{
		# Verify account is valid
		Write-Information -Tags "User" -MessageData "INFO: Verifying if principal '$Principal' is valid"
		$NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).ToString() | Out-Null
	}
	catch
	{
		Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message $_.Exception.Message
		return $false
	}

	if ($Owner)
	{
		Write-Information -Tags "User" -MessageData "INFO: Attempt to grant ownership to principal '$Principal'"

		$Acl.SetOwner($NTAccount)
		Set-Acl -AclObject $Acl -Path $Path
		return $true
	}

	# Grant permission to principal for resource
	Write-Information -Tags "User" -MessageData "INFO: Attempt to grant specified permissions to principal '$Principal'"

	try
	{
		# Represents an abstraction of an access control entry (ACE) that defines an access rule for a file or directory
		if (Test-Path -Path $Path -PathType Leaf)
		{
			# Leaf. An element that does not contain other elements, such as a file or registry entry.
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Input path is leaf: $(Split-Path -Path $Path -Leaf)"
			$Permission = New-Object System.Security.AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Type)
		}
		else
		{
			# Container. An element that contains other elements, such as a directory or registry key.
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Input path is container: $(Split-Path -Path $Path -Leaf)"
			$Permission = New-Object System.Security.AccessControl.FileSystemAccessRule($NTAccount, $Rights, $Inheritance, $Propagation, $Type)
		}

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
	return $true
}

---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Permission.md
schema: 2.0.0
---

# Set-Permission

## SYNOPSIS

Take ownership or set permissions on file system or registry object

## SYNTAX

### Ownership

```powershell
Set-Permission [-LiteralPath] <String> -Owner <String> [-Domain <String>] [-Recurse] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### FileSystem

```powershell
Set-Permission [-LiteralPath] <String> -User <String> [-Domain <String>] [-Type <AccessControlType>]
 -Rights <FileSystemRights> [-Inheritance <InheritanceFlags>] [-Propagation <PropagationFlags>] [-Protected]
 [-PreserveInheritance] [-Recurse] [-Reset] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Registry

```powershell
Set-Permission [-LiteralPath] <String> -User <String> [-Domain <String>] [-Type <AccessControlType>]
 -RegistryRights <RegistryRights> [-Inheritance <InheritanceFlags>] [-Propagation <PropagationFlags>]
 [-Protected] [-PreserveInheritance] [-Recurse] [-Reset] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Reset

```powershell
Set-Permission [-LiteralPath] <String> [-Domain <String>] [-Protected] [-PreserveInheritance] [-Recurse]
 [-Reset] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Set-Permission sets permission or ownership of a filesystem or registry object such as file,
folder, registry key or registry item.

Set-Permission function is a wrapper around *-Acl commandlets for easier ACL editing.
This function also serves as replacement for takeown.exe and icacls.exe whose syntax is arcane.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-Permission -User "SomeUser" -LiteralPath "D:\SomePath"
```

Sets function defaults for user SomeUser on path D:\SomePath

### EXAMPLE 2

```powershell
Set-Permission -User "Remote Management Users" -LiteralPath "D:\SomePath" -Protected
```

Only "Remote Management Users" have permissions on "D:\SomePath", other entries are removed

### EXAMPLE 3

```powershell
Set-Permission -User "LanmanServer" -Domain "NT SERVICE" -LiteralPath "D:\SomeFolder" `
    -Type "Deny" -Rights "TakeOwnership, Delete, Modify"
```

LanmanServer service is denied specified rights for specified directory and all it's contents

### EXAMPLE 4

```powershell
Set-Permission -User SomeUser -Domain COMPUTERNAME -LiteralPath "D:\SomeFolder"
```

Allows to ReadAndExecute, ListDirectory and Traverse to "SomeFolder" and it's contents for COMPUTERNAME\SomeUser

### EXAMPLE 5

```powershell
Set-Permission -User Administrators -LiteralPath "HKLM:\$RegPath" -RegistryRight ChangePermissions -Inheritance None
```

Allows Administrators to change permissions on registry path, and the path does not inherit parent permissions

## PARAMETERS

### -LiteralPath

Resource on which to set ownership or permissions.
Valid resources are files, directories, registry keys and registry entries.
Note that for registry key you must specify PowerShell provider path, ex: HKLM:\

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: LP

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner

Principal username who will be the new owner of a resource.
Using this parameter means taking ownership of a resource.

```yaml
Type: System.String
Parameter Sets: Ownership
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User

Principal username or group name to which to grant specified permissions.
Using this parameter means setting permissions on a resource.

```yaml
Type: System.String
Parameter Sets: FileSystem, Registry
Aliases: UserName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Principal domain such as computer name or authority to which username applies

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type

Access control type to either allow or deny specified rights

```yaml
Type: System.Security.AccessControl.AccessControlType
Parameter Sets: FileSystem, Registry
Aliases:
Accepted values: Allow, Deny

Required: False
Position: Named
Default value: Allow
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rights

Defines file system access rights to use for principal when creating access and audit rules.
The default includes: ReadAndExecute, ListDirectory and Traverse
Where:
1.
ReadAndExecute: Read and ExecuteFile
2.
Read: ReadData, ReadExtendedAttributes, ReadAttributes, and ReadPermissions.

```yaml
Type: System.Security.AccessControl.FileSystemRights
Parameter Sets: FileSystem
Aliases: Permission, Grant
Accepted values: ListDirectory, ReadData, WriteData, CreateFiles, CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, Traverse, ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes, WriteAttributes, Write, Delete, ReadPermissions, Read, ReadAndExecute, Modify, ChangePermissions, TakeOwnership, Synchronize, FullControl

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RegistryRights

Defines registry access rights to use for principal when creating access and audit rules.
The default includes: ReadKey
Where, ReadKey: QueryValues, Notify, EnumerateSubKeys and ReadPermissions

```yaml
Type: System.Security.AccessControl.RegistryRights
Parameter Sets: Registry
Aliases: RegPermission, RegGrant
Accepted values: QueryValues, SetValue, CreateSubKey, EnumerateSubKeys, Notify, CreateLink, Delete, ReadPermissions, WriteKey, ExecuteKey, ReadKey, ChangePermissions, TakeOwnership, FullControl

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inheritance

Inheritance flags specify the semantics of inheritance for access control entries.
This parameter is ignored for leaf objects, such as files or or registry entries.
This parameter controls the "Applies to" column in advanced security dialog
The default is "This folder, subfolders and files"

```yaml
Type: System.Security.AccessControl.InheritanceFlags
Parameter Sets: FileSystem, Registry
Aliases:
Accepted values: None, ContainerInherit, ObjectInherit

Required: False
Position: Named
Default value: ContainerInherit, ObjectInherit
Accept pipeline input: False
Accept wildcard characters: False
```

### -Propagation

Specifies how Access Control Entries (ACEs) are propagated to child objects.
These flags are significant only if inheritance flags are present, (when Inheritance is not "None")
This parameter is ignored for leaf objects, such as files or or registry entries.
This parameter affects the "Applies to" column in advanced security dialog

```yaml
Type: System.Security.AccessControl.PropagationFlags
Parameter Sets: FileSystem, Registry
Aliases:
Accepted values: None, NoPropagateInherit, InheritOnly

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protected

If set, protect the specified access rules from inheritance.
The default is to allow inheritance.
Protected access rules cannot be modified by parent objects through inheritance.
This parameter controls the "Enable/Disable Inheritance" button in advanced security dialog

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FileSystem, Registry, Reset
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreserveInheritance

If set, preserve inherited access rules, which become explicit rules.
The default is to remove inherited access rules.
This parameter is ignored if Protected is not set.
This parameter controls choices offered after "Enable/Disable Inheritance" button.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FileSystem, Registry, Reset
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse

If specified, applies specified operations to all subobjects.
This parameter is ignored for Leaf objects, such as files or registry entries.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reset

If specified, removes all explicit access rules and keeps only inherited.
if "Protected" parameter is specified inherited rules are removed as well.
If "Protected" is specified with "PreserveInheritance", then the inherited rules become
explicit rules and everything else is removed.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: FileSystem, Registry
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Reset
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, skips prompting for confirmation to perform recursive action

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Set-Permission

## OUTPUTS

### [bool]

## NOTES

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

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Permission.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-Permission.md)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.accesscontroltype](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.accesscontroltype)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryrights](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryrights)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setaccessruleprotection](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setaccessruleprotection)

[https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registrysecurity](https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registrysecurity)

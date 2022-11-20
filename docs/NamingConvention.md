
# Naming convention

This file contains an incomplete naming convention rules for symbols such as parameters and
variables used accross code in this repository.

## Table of Contents

- [Naming convention](#naming-convention)
  - [Table of Contents](#table-of-contents)
  - [Parameters](#parameters)
    - [Unresolved](#unresolved)
  - [Registry keys](#registry-keys)
    - [Registry functions](#registry-functions)
    - [Return types](#return-types)
    - [Exceptions](#exceptions)
  - [Variables](#variables)
  - [Custom objects](#custom-objects)
    - [Ruleset.ProgramInfo](#rulesetprograminfo)
    - [Ruleset.UserInfo](#rulesetuserinfo)

## Parameters

[Standard Cmdlet Parameter Names and Types][parameters]

> Avoid using plural names for parameters
***
> Use Pascal Case for Parameter Names
***
> If a more specific name is required, use a standard parameter name,
> and then specify a more specific name as an alias.
***
> Use Standard Types for Parameters

Parameter names and aliases

- [string] `User`
  - `UserName` *
- [string] `Domain`
  - `ComputerName` *
  - `CN`
- [string] `Group`
  - `UserGroup`
- [string] `SID`
  - `UserSID`
  - `GroupSID`
  - `AppSID`
- [string] `Principal` (a unique identifiable entity for access)
  - `Account`
  - `UserAccount`
- [string] `SDDL`
- [string] `Owner` (the name of the owner of the resource)
- [string] `Name`
- [switch] `Log` (audit the actions of the cmdlet when the parameter is specified)
- [string] `LogName` (the name of the log file to process or use)
- [string] `Path` (the paths to a resource when wildcard characters are supported)
  - `FilePath`
  - `FullName`
- [string] `LiteralPath` (the path to a resource when wildcard characters are not supported)
  - `LP`
- [string] `Interface` (network interface name)
- [IPAddress] `IPAddress` (specify an IP address)
  - `LocalAddress`
  - `RemoteAddress`
- [uri] `URL`
  - `URI`
- [string] `Encoding` (ValidateSet())
- [enum] `Application` (specify an application)
  - `Program`
- [object] `InputObject` (when the cmdlet takes input from other cmdlets, ValueFromPipeline)
- [switch] `Strict` (all errors are handled as terminating errors)
- [switch] `Exact` (the resource term must match the resource name exactly)
- [string] `Privilege` (the right a cmdlet needs to perform an operation for a particular entity)
- [string] `Command` (specify a command string to run)
- [switch] `Stream` (stream multiple output objects through the pipeline)
- [int32] `Timeout` (the timeout interval (in milliseconds))
- [switch] `Wait` (wait for user input before continuing)
- [int32] `WaitTime` (the duration (in seconds) that the cmdlet will wait for user input)
- [int32] `Retry` (the number of times the cmdlet will attempt an action)
- [int32] `Count` (specify the count or specify the number of objects to be processed)
- [switch] `Recurse` (the cmdlet recursively performs its actions on resources)
- [string] `From` (specify the reference object to get information from)
- [switch] `Unique`
- [object] `Value` (specify a value to provide to the cmdlet)
- [switch] `Create` (to indicate that a resource is created if one does not already exist)
- [switch] `CaseSensitive`
- [switch] `Binary` (the cmdlet handles binary values)
- [switch] `Quiet` (the cmdlet suppresses user feedback during its actions)
- [switch] `Interactive` (Implement this parameter so that the cmdlet works interactively with the user when the parameter is specified)
- [int32] `ErrorLevel` (Implement this parameter so that the user can specify the level of errors to report)
- [switch] `Repair` (attempt to correct something from a broken state)
- [switch] `Overwrite` (the cmdlet overwrites any existing data when the parameter is specified)
- [string] `Prompt` (specify a prompt for the cmdlet)
- [array] `State` (specify the Keyword names of states)
- [switch] `Trusted` (trust levels are supported when the parameter is specified)
- [string] `TempLocation` (specify the location of temporary data that is used during operation)
- [string] `CertFile` (Name of a file that contains (PKCS) #12 or (DER) x.509 certificate and key)
- [string[]] `Include` (Implement this parameter so that the user can include something in an activity)
- [bool] `All` (true indicates that all resources should be acted upon instead of a default subset of resources)
- [string] `Type` (the user can specify the type of resource on which to operate)
- [string] `Operation` (the user can specify an action that can be performed on a protected object)

`*` Used by most commandlets as primary parameter but should be an alias instead\
ex. `PSPath` is an alias of both the `Path` and `LiteralPath` of most commandlets.

### Unresolved

No clear conventions for the following parameters

- [switch] `CIM` (Contact CIM server)
- [switch] `Disabled` (Disabled user accounts)
- [switch] `DomainName` (see: Test-UPN)
- [string] `AddressFamily` (ValidateSet())
  - `IPVersion`
- [switch] `Physical`
- [switch] `Virtual`
- [switch] `Connected`
- [switch] `Hidden`
- [switch] `Detailed`
- [string] `Message`
- `Reference*`
- `Difference*`
- [uint32] Seconds, Minutes, Hours...
- [switch] `Disable` (disable or remove setting)
- [string] `CertThumbprint`

[Table of Contents](#table-of-contents)

## Registry keys

Following is a legend and sample table for `HKEY_LOCAL_MACHINE`\
Starting with `RootKey` toward specific `key value` each subsequent sub key follows naming convention
according to this table until `key value` is reached.

1. `Key type` describes the type of a key beginning from top node downward toward target value
2. `Key path name` describes naming convention for the [string] registry path
3. `Sub keys name` describes naming convention for an [array] of sub keys
4. `Variable name` describes naming convention for the [Microsoft.Win32.RegistryKey] variable name

| Key type            | Key path name    | Sub keys name    | Variable name |
|---------------------|------------------|------------------|---------------|
| Remote key          | RegistryHive     |       -          | $RegistryHive |
| Targeted keys       | HKLM             |       -          | $HKLM         |
| Root key            | HKLMRootKey      | HKLMNames        | $RootKey      |
| Sub key             | HKLMSubKey       | HKLMSubKeyNames  | $SubKey       |
| Key                 | HKLMKey          | HKLMKeyNames     | $Key          |
| Specific key        | `<KeyName>`      | `<KeyName>`Names | $`<KeyName>`  |
| Key value           | `<KeyName>`Entry |       -          | $KeyNameEntry |

### Registry functions

1. RegistryKey.OpenSubKey
2. RegistryKey.GetValue
3. RegistryKey.OpenRemoteBaseKey
4. RegistryKey.GetSubKeyNames
5. RegistryKey.GetValueNames

### Return types

1. The subkey requested, or null if the operation failed.
2. The value associated with name, or null if name is not found.
3. The requested registry key.
4. An array of strings that contains names of the subkeys for the current key.
5. An array of strings that contains value names for the current key.

### Exceptions

ArgumentNullException

- `1` Name is null.
- `3` MachineName is null.

ArgumentException

- `3` hKey is invalid.

ObjectDisposedException

- `1, 2, 4, 5` The RegistryKey is closed (closed keys cannot be accessed).

[SecurityException][SecurityException]

- `1` The user does not have the permissions required to access the registry key in the specified mode.
- `2, 5` The user does not have the permissions required to read from the registry key.
- `3` The user does not have the proper permissions to perform this operation.
- `4` The user does not have the permissions required to read from the key.

IOException

- `2` The RegistryKey that contains the specified value has been marked for deletion.
- `3` MachineName is not found.
- `4, 5` A system error occurred, for example the current key has been deleted.

[UnauthorizedAccessException][UnauthorizedAccessException]

- `2, 3, 4, 5` The user does not have the necessary registry rights.

[Table of Contents](#table-of-contents)

## Variables

To name variables we use descriptive approach and camel case similar to recommendations on how to
name functions and parameters, ex:

`$SearchString` instead of `$str`

In for loops a variable which is about items in a collection should decriptively be declared so ex:

```powershell
foreach ($PathEntry in $SomeCollection)
# Instead of
foreach ($i in $SomeCollection)
```

## Custom objects

`[PSCustomObject]` generated by module functions must be consistent per module.

### Ruleset.ProgramInfo

Minimum properties if possible in this order:

```none
Domain = computer name
Name = program name
[version] Version = program version
Publisher = program publisher
InstallLocation = root installation directory
[PathInfo] RegistryKey = registry key that contains this data
PSTypeName = unique object type name for this module
```

### Ruleset.UserInfo

Minimum properties if possible in this order:

`Ruleset.Userinfo`

```none
Domain = computer name
User = user name
Group = group name
Principal = principal name / UPN / NetBIOS principal name
SID = security identifier of a principal
SDDL = SDDL string of a principal
[bool] LocalAccount = indicates local, roaming or MS account
PSTypeName = unique object type name for this module
```

Special custom objects:

`Ruleset.Userinfo.Principal`

```none
Domain
Principal
SID
PSTypeName
```

`Ruleset.Userinfo.Group`

```none
Domain
Group
SID
PSTypeName
```

[Table of Contents](#table-of-contents)

[parameters]: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/standard-cmdlet-parameter-names-and-types "Visit Microsoft docs"
[UnauthorizedAccessException]: https://docs.microsoft.com/en-us/dotnet/api/system.unauthorizedaccessexception?view=net-5.0 "Visit Microsoft docs"
[SecurityException]: https://docs.microsoft.com/en-us/dotnet/api/system.security.securityexception?view=net-5.0 "Visit Microsoft docs"


# Naming convention

This file contains naming convention rules for parameters and variables

- [Naming convention](#naming-convention)
  - [Parameters](#parameters)
  - [Registry keys](#registry-keys)
    - [Registry functions](#registry-functions)
    - [Return types](#return-types)
    - [Exceptions](#exceptions)

## Parameters

[Standard Cmdlet Parameter Names and Types][parameters]

Parameter names and aliases

- [string] User
  - UserName
- [string] Computer
  - ComputerName
  - Domain
- [string] Group
  - UserGroup
- [string] SID
  - UserSID
  - GroupSID
  - AppSID
- [string] Account
  - UserAccount
  - Principal
- [string] SDDL
- [string] Name
- [string] LogName
- [string] Path
- [string] LiteralPath
- [string] FilePath
- [enum] $Program
- [ValidateSet()] Encoding
- [object] InputObject
- [switch] Strict

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
4. An array of strings that contains the names of the subkeys for the current key.
5. An array of strings that contains the value names for the current key.

### Exceptions

ArgumentNullException

- `1` Name is null.
- `3` MachineName is null.

ArgumentException

- `3` hKey is invalid.

ObjectDisposedException

- `1, 2, 4, 5` The RegistryKey is closed (closed keys cannot be accessed).

SecurityException

- `1` The user does not have the permissions required to access the registry key in the specified mode.

SecurityException

- `2, 5` The user does not have the permissions required to read from the registry key.
- `3` The user does not have the proper permissions to perform this operation.
- `4` The user does not have the permissions required to read from the key.

IOException

- `2` The RegistryKey that contains the specified value has been marked for deletion.
- `3` MachineName is not found.
- `4, 5` A system error occurred, for example the current key has been deleted.

UnauthorizedAccessException

- `2, 3, 4, 5` The user does not have the necessary registry rights.

[parameters]: https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/standard-cmdlet-parameter-names-and-types "Visit Microsoft docs"

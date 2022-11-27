
# Ruleset.UserInfo

## about_Ruleset.UserInfo

## SHORT DESCRIPTION

Module to query information about Windows users and groups

## LONG DESCRIPTION

Ruleset.UserInfo module is used to query information about users and groups on local or remote
computers.

## VARIABLES

```powershell
CheckInitUserInfo
```

Serves to prevent double initialization of constants

```powershell
UsersGroupSDDL
```

SDDL string for "Users" group

```powershell
AdminGroupSDDL
```

SDDL string for "Administrators" group

```powershell
LocalSystem
```

SDDL string for "NT AUTHORITY\SYSTEM"

```powershell
LocalService
```

SDDL string for "NT AUTHORITY\LOCAL SERVICE"

```powershell
NetworkService
```

SDDL string for "NT AUTHORITY\NETWORK SERVICE"

## EXAMPLES

```powershell
ConvertFrom-SDDL
```

Convert SDDL string to Principal

```powershell
ConvertFrom-SID
```

Convert SID to principal, user and domain name

```powershell
Get-GroupPrincipal
```

Get principals of specified groups on target computers

```powershell
Get-GroupSID
```

Get SID of user groups on local or remote computers

```powershell
Get-PathSDDL
```

Get SDDL string for a path

```powershell
Get-PrincipalSID
```

Get SID for specified user account

```powershell
Get-SDDL
```

Get SDDL string of a user, group or from path

```powershell
Get-UserGroup
```

Get user groups on target computers

```powershell
Merge-SDDL
```

Merge 2 SDDL strings into one

```powershell
Split-Principal
```

Split principal to either user name or domain

```powershell
Test-Credential
```

Takes a PSCredential object and validates it

```powershell
Test-SDDL
```

Validate SDDL string

```powershell
Test-UPN
```

Validate Universal Principal Name syntax

## KEYWORDS

- Users
- UserInfo
- ComputerUsers

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.UserInfo/Help/en-US

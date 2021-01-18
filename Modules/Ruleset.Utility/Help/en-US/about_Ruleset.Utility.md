
# Ruleset.Utility

## about_Ruleset.Utility

## SHORT DESCRIPTION

PowerShell utility module for Windows Firewall Ruleset project

## LONG DESCRIPTION

Ruleset.Utility module exposes utility functions relevant for Windows Firewall Ruleset.

## VARIABLES

```powershell
ServiceHost
```

Windows service host

```powershell
CheckInitUtility
```

Serves to prevent double initialization of constants

## EXAMPLES

```powershell
Approve-Execute
```

Prompt user to continue running script

```powershell
Build-ServiceList
```

Build a list of windows services involved in script rules

```powershell
Compare-Path
```

Compare 2 paths for equality or similarity

```powershell
Confirm-FileEncoding
```

Verify file is encoded as expected

```powershell
ConvertFrom-Wildcard
```

Convert wildcard pattern to regex

```powershell
Get-FileEncoding
```

Gets the encoding of a file

```powershell
Get-TypeName
```

Get .NET outputs of a commandlet or convert to/from type accelerator

```powershell
Invoke-Process
```

Run process and optionally redirect captured output

```powershell
Out-DataTable
```

Creates a DataTable from an object

```powershell
Resolve-FileSystemPath
```

Resolve file system wildcard of a directory or file location

```powershell
Select-EnvironmentVariable
```

Select a group of system environment variables

```powershell
Set-NetworkProfile
```

Set network profile for physical network interfaces

```powershell
Set-Permission
```

Take ownership or set permissions on file system or registry object

```powershell
Set-ScreenBuffer
```

Set vertical screen buffer to recommended value

```powershell
Set-Shortcut
```

Create or set shortcut to file or online location

## ALIASES

```powershell
gt -> Get-TypeName
```

## KEYWORDS

- Utility
- FirewallUtility

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Utility/Help/en-US

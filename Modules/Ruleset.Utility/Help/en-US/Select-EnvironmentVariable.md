---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md
schema: 2.0.0
---

# Select-EnvironmentVariable

## SYNOPSIS

Select a group of system environment variables

## SYNTAX

### Scope (Default)

```powershell
Select-EnvironmentVariable [-Domain <String>] [-Credential <PSCredential>] [-Session <PSSession>]
 [-From <String>] [-Property <String>] [-Exact] [-IncludeFile] [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Name

```powershell
Select-EnvironmentVariable [-Domain <String>] [-Credential <PSCredential>] [-Session <PSSession>]
 [-From <String>] -Name <String> [-Property <String>] [-IncludeFile] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Value

```powershell
Select-EnvironmentVariable [-Domain <String>] [-Credential <PSCredential>] [-Session <PSSession>]
 [-From <String>] -Value <String> [-Property <String>] [-Exact] [-IncludeFile] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Select-EnvironmentVariable selects a specific or predefined group of system environment variables.
This is useful to compare or verify environment variables such as path patterns or to select
specific type of paths.
For example, firewall rule for an applications will include the path to to said application,
the path may contain system environment variable and we must ensure environment variable resolves
to existing file system location that is fully qualified and does not lead to userprofile.

## EXAMPLES

### EXAMPLE 1

```powershell
Select-EnvironmentVariable -From UserProfile
```

Name              Value
%APPDATA%         C:\Users\SomeUser\AppData\Roaming
%HOME%            C:\Users\SomeUser
%HOMEPATH%        \Users\SomeUser
%USERNAME%        SomeUser

### EXAMPLE 2

```powershell
Select-EnvironmentVariable -Name *user* -Property Name -From WhiteList
```

%ALLUSERSPROFILE%

### EXAMPLE 3

```powershell
Select-EnvironmentVariable -Name "LOGONSERVER" -Force
```

\\\\SERVERNAME

### EXAMPLE 4

```powershell
Select-EnvironmentVariable -Value "C:\Program Files"
```

%ProgramFiles%

### EXAMPLE 5

```powershell
Select-EnvironmentVariable -From UserProfile -Property Name
```

%APPDATA%
%HOME%
%HOMEPATH%
%LOCALAPPDATA%
%OneDrive%
%TEMP%
%TMP%
%USERPROFILE%

### EXAMPLE 6

```powershell
Select-EnvironmentVariable -From FullyQualified -Exact
```

Name                       Value
----                       -----
ALLUSERSPROFILE            C:\ProgramData
APPDATA                    C:\Users\SomeUser\AppData\Roaming
CommonProgramFiles         C:\Program Files\Common Files
CommonProgramFiles(x86)    C:\Program Files (x86)\Common Files
CommonProgramW6432         C:\Program Files\Common Files
DriverData                 C:\Windows\System32\Drivers\DriverData

## PARAMETERS

### -Domain

Computer name from which to retrieve environment variables

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From

A named group of system environment variables to get as follows:

- UserProfile: Any variables that lead to or mentions user profile
- Whitelist: Variables that are allowed to be part of firewall rules
- FullyQualified: Variables which are fully qualified paths
- Rooted: Variables for any path that has root qualifier
- FileSystem: Variables for valid paths on any of the local file system volume
- Relative: Relative file system paths
- BlackList: Variables that are not in any other group mentioned above
- All: All system environment variables

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Specify specific environment variable which to expand to value.
If there is no such environment variable the result is null.
Wildcard characters are supported.

```yaml
Type: System.String
Parameter Sets: Name
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Value

Get environment variable name for specified value if there is one.
This is equivalent to serching environment variables that expand to specified value,
the result may include multiple environment variables.
Wildcard characters are supported.

```yaml
Type: System.String
Parameter Sets: Value
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Property

Specify behavior of -Name or -Value parameters, for ex.
-Name parameter gets values for
environment variables that match -Name wildcard pattern, to instead get variable names specify -Property Name.
Same applies to -Value parameter which gets variables for matches values.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exact

If specified, retrieved environment variable names are exact, meaning not surrounded with
percentage '%' sign, ex: HOMEDRIVE instead of %HOMEDRIVE%
If previous function call was not run with same "Exact" parameter value, then the script scope cache
is updated by reformatting variable names, but the internal cache is not recreated.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Scope, Value
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeFile

If specified, algorithm will include variables and/or their values that represent files,
by default only directories are grouped and the rest is put into "blacklist" and "All" group.

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

### -Force

If specified, discards script scope cache and queries system for environment variables a new.
By default variables are queried only once per session, each subsequent function call returns
cached result.

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

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Select-EnvironmentVariable

## OUTPUTS

### [System.Collections.DictionaryEntry]

## NOTES

Fully Qualified Path Name (FQPN):

- A UNC name of any format, which always start with two backslash characters ("\\\\"), ex: "\\\\server\share\path\file"
- A disk designator with a backslash, for example "C:\" or "d:\".
- A single backslash, for example, "\directory" or "\file.txt".
This is also referred to as an absolute path.

Relative path:

If a file name begins with only a disk designator but not the backslash after the colon:

- "C:tmp.txt" refers to a file named "tmp.txt" in the current directory on drive C
- "C:tempdir\tmp.txt" refers to a file in a subdirectory to the current directory on drive C

A path is also said to be relative if it contains "double-dots":

- "..\tmp.txt" specifies a file named tmp.txt located in the parent of the current directory.
- "..\tmp.txt" specifies a file named tmp.txt located in the parent of the current directory.

Relative paths can combine both example types, for example "C:..\tmp.txt"
Path+Filename limit is 260 characters.

TODO: Need to see if UNC, single backslash and relative paths without a qualifier are valid for firewall,
a new group 'Firewall' is needed since whitelist excludes some valid variables
TODO: Implement -AsCustomObject that will give consistent output for formatting purposes
TODO: Implement -Unique switch since some variable Values may be duplicates (with different name)
TODO: Output should include domain name from which variables were retrieved
HACK: Parameter set names for ComputerName vs Session

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md)

[https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file](https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file)

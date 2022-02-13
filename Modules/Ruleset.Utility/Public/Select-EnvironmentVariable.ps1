
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Select a group of system environment variables

.DESCRIPTION
Select-EnvironmentVariable selects a specific or predefined group of system environment variables.
This is useful to compare or verify environment variables such as path patterns or to select
specific type of paths.
For example, firewall rule for an applications will include the path to to said application,
the path may contain system environment variable and we must ensure environment variable resolves
to existing file system location that is fully qualified and does not lead to userprofile.

.PARAMETER Domain
Computer name from which to retrieve environment variables

.PARAMETER Credential
Specifies the credential object to use for authentication

.PARAMETER Session
Specifies the PS session to use

.PARAMETER From
A named group of system environment variables to get as follows:
- UserProfile: Any variables that lead to or mentions user profile
- Whitelist: Variables that are allowed to be part of firewall rules
- FullyQualified: Variables which are fully qualified paths
- Rooted: Variables for any path that has root qualifier
- FileSystem: Variables for valid paths on any of the local file system volume
- Relative: Relative file system paths
- BlackList: Variables that are not in any other group mentioned above
- All: All system environment variables

.PARAMETER Name
Specify specific environment variable which to expand to value.
If there is no such environment variable the result is null.
Wildcard characters are supported.

.PARAMETER Value
Get environment variable name for specified value if there is one.
This is equivalent to serching environment variables that expand to specified value,
the result may include multiple environment variables.
Wildcard characters are supported.

.PARAMETER Property
Specify behavior of -Name or -Value parameters, for ex. -Name parameter gets values for
environment variables that match -Name wildcard pattern, to instead get variable names specify -Property Name.
Same applies to -Value parameter which gets variables for matches values.

.PARAMETER Exact
If specified, retrieved environment variable names are exact, meaning not surrounded with
percentage '%' sign, ex: HOMEDRIVE instead of %HOMEDRIVE%
If previous function call was not run with same "Exact" parameter value, then the script scope cache
is updated by reformatting variable names, but the internal cache is not recreated.

.PARAMETER IncludeFile
If specified, algorithm will include variables and/or their values that represent files,
by default only directories are grouped and the rest is put into "blacklist" and "All" group.

.PARAMETER Force
If specified, discards script scope cache and queries system for environment variables a new.
By default variables are queried only once per session, each subsequent function call returns
cached result.

.EXAMPLE
PS> Select-EnvironmentVariable -From UserProfile

Name              Value
----              -----
%APPDATA%         C:\Users\SomeUser\AppData\Roaming
%HOME%            C:\Users\SomeUser
%HOMEPATH%        \Users\SomeUser
%USERNAME%        SomeUser

.EXAMPLE
PS> Select-EnvironmentVariable -Name *user* -Property Name -From WhiteList

%ALLUSERSPROFILE%

.EXAMPLE
PS> Select-EnvironmentVariable -Name "LOGONSERVER" -Force

\\SERVERNAME

.EXAMPLE
PS> Select-EnvironmentVariable -Value "C:\Program Files"

%ProgramFiles%

.EXAMPLE
PS> Select-EnvironmentVariable -From UserProfile -Property Name

%APPDATA%
%HOME%
%HOMEPATH%
%LOCALAPPDATA%
%OneDrive%
%TEMP%
%TMP%
%USERPROFILE%

.EXAMPLE
PS> Select-EnvironmentVariable -From FullyQualified -Exact

Name                       Value
----                       -----
ALLUSERSPROFILE            C:\ProgramData
APPDATA                    C:\Users\SomeUser\AppData\Roaming
CommonProgramFiles         C:\Program Files\Common Files
CommonProgramFiles(x86)    C:\Program Files (x86)\Common Files
CommonProgramW6432         C:\Program Files\Common Files
DriverData                 C:\Windows\System32\Drivers\DriverData

.INPUTS
None. You cannot pipe objects to Select-EnvironmentVariable

.OUTPUTS
[System.Collections.DictionaryEntry]

.NOTES
Fully Qualified Path Name (FQPN):

- A UNC name of any format, which always start with two backslash characters ("\\"), ex: "\\server\share\path\file"
- A disk designator with a backslash, for example "C:\" or "d:\".
- A single backslash, for example, "\directory" or "\file.txt". This is also referred to as an absolute path.

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

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md

.LINK
https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
#>
function Select-EnvironmentVariable
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Scope",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md")]
	[OutputType([System.Collections.DictionaryEntry])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter()]
		[System.Management.Automation.Runspaces.PSSession] $Session,

		[Parameter()]
		[ValidateSet("UserProfile", "Whitelist", "FullyQualified", "Rooted", "FileSystem", "Relative", "BlackList", "All")]
		[string] $From = "All",

		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[AllowEmptyString()]
		[SupportsWildcards()]
		[string] $Name,

		[Parameter(Mandatory = $true, ParameterSetName = "Value")]
		[AllowEmptyString()]
		[SupportsWildcards()]
		[string] $Value,

		[Parameter()]
		[ValidateSet("Name", "Value")]
		[string] $Property,

		[Parameter(ParameterSetName = "Scope")]
		[Parameter(ParameterSetName = "Value")]
		[switch] $Exact,

		[Parameter()]
		[switch] $IncludeFile,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $SessionParams = @{}
	if ($Session)
	{
		$SessionParams.Session = $Session
	}
	else
	{
		# Replace localhost and dot with NETBIOS computer name
		if (($Domain -eq "localhost") -or ($Domain -eq "."))
		{
			$Domain = [System.Environment]::MachineName
		}

		$SessionParams.ComputerName = $Domain
		if ($Credential)
		{
			$SessionParams.Credential = $Credential
		}
	}

	# Make sure null or empty Name or Value arguments don't cause any overhead
	switch ($PsCmdlet.ParameterSetName)
	{
		"Name"
		{
			if ([string]::IsNullOrEmpty($Name))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Value parameter is null or empty"
				return $null
			}

			if (!$Property) { $Property = "Value" }
			break
		}
		"Value"
		{
			if ([string]::IsNullOrEmpty($Value))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Name parameter is null or empty"
				return $null
			}

			if (!$Property) { $Property = "Name" }
		}
	}

	# Check if cache needs to be updated
	$LastState = Get-Variable -Name LastExactState -Scope Script -ErrorAction Ignore

	if ($Force -or !$LastState)
	{
		if ($LastState)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Recreating environment variable cache"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Populating new environment variable cache"
		}

		# Any directory that leads to user profile either directly or indirectly, ex:
		# "C:\Users\User\AppData", "\Users\User", "User"
		# The path does not have to exist
		Set-Variable -Name UserProfile -Scope Script -Value @()

		# Indicates whether the given path is whitelisted to be included in firewall rules
		# The path must exist, be rooted, fully qualified, not relative and contain no dot notation
		Set-Variable -Name WhiteList -Scope Script -Value @()

		# Indicates whether the specified file path is fixed to a specific drive or UNC path, ex:
		# "\\COMPUTERNAME\Share\file", "C:\\Windows", "C:\", "C:\Windows\.\Help", "C:\Windows\.."
		# The path does not have to exist
		Set-Variable -Name FullyQualified -Scope Script -Value @()

		# Indicates whether the specified path string contains a root, ex:
		# "\\COMPUTERNAME\Share\file", "C:\\Windows", "C:Windows", "\Users\User", "C:", "\", "\\.\", "\Users\User"
		# The path does not have to exist
		Set-Variable -Name Rooted -Scope Script -Value @()

		# Indicates whether the given path refers to an existing directory on disk, ex:
		# "C:\\Windows", "C:Windows", ".", "..\", "C:\Windows\..", "C:\Windows\System32\..\Help", "C:\Windows\.\Help"
		Set-Variable -Name FileSystem -Scope Script -Value @()

		# Indicates whether the given path is relative, ex:
		# ".", "..\", "C:", "C:Windows", "..", ".\"
		# The path does not have to exist
		Set-Variable -Name Relative -Scope Script -Value @()

		# Any environment variable that that is not syntactically valid directory or UNC path
		Set-Variable -Name BlackList -Scope Script -Value @()

		# All system environment variables
		Set-Variable -Name AllVariables -Scope Script -Value @()

		# Preselected user profile variables
		New-Variable -Name WellKnownUserProfile -Scope Local -Option Constant -Value @(
			"%APPDATA%"
			"%HOME%"
			"%LOCALAPPDATA%"
			"%OneDrive%"
			"%TEMP%"
			"%TMP%"
			"%USERPROFILE%"
			"%OneDriveConsumer%"
			"%HOMEPATH%"
			# NOTE: Not a path or file
			# "%USERNAME%"
		)
	}

	# Check if cache needs to be updated
	$LastState = Get-Variable -Name LastExactState -Scope Script -ErrorAction Ignore

	if ($Force -or !$LastState)
	{
		if ($Exact)
		{
			$script:AllVariables = Invoke-Command @SessionParams -ScriptBlock {
				Get-ChildItem Env:
			}
		}
		else
		{
			$script:AllVariables = Invoke-Command @SessionParams -ScriptBlock {
				Get-ChildItem Env: | ForEach-Object {
					[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
				}
			}
		}

		# Make an array of (environment variable/path) name/value pair
		foreach ($Entry in $script:AllVariables)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing entry: $($Entry.Name)"

			$IsUserProfile = $false
			$FileExists = $false

			# A variable name may include any of the following characters:
			# A-Z,a-z, 0-9, # $ ' ( ) * + , - . ? @ [ ] _ ` { } ~
			# The first character of the name must not be numeric.
			# Reserved characters that must be escaped: [ ] ( ) . \ ^ $ | ? * + { }
			# NETBIOS invalid characters: " / \ [ ] : | < > + = ; ,
			# UPN name invalid characters: ~ ! # $ % ^ & * ( ) + = [ ] { } \ / | ; : " < > ? ,
			# Invalid characters to name a directory: / \ : < > ? * | "
			if ($Entry.Value -match "(;\w:\\\w)+")
			{
				# Not valid path even if it mentions userprofile
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Blacklisting path with multiple directories $($Entry.Value)"
				$script:BlackList += $Entry
				continue
			}
			elseif ($Entry.Value -match '<>\?\|":')
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Blacklisting environment variable with bad character $($Entry.Value)"
				$script:BlackList += $Entry
				continue
			}

			# Match file extension
			if ($Entry.Value -match '\.[^./\\:<>?*|"]+$')
			{
				if ($IncludeFile)
				{
					# TODO: This may include variables that are not meant to point to files
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Including file path $($Entry.Value)"
					$FileExists = Invoke-Command @SessionParams -ScriptBlock {
						[System.IO.File]::Exists($using:Entry.Value)
					}
				}
				else
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Blacklisting file path $($Entry.Value)"
					$script:BlackList += $Entry
					continue
				}
			}

			# HACK: Hardcoded, a new functioned needed to get remote shares
			[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem -CimSession $CimServer |
			Select-Object -ExpandProperty SystemDrive

			if ($WellKnownUserProfile -match $Entry.Name)
			{
				# We only care to know userprofile variables regradless if valid or not
				$IsUserProfile = $true
				$script:UserProfile += $Entry
			}
			elseif ($Entry.Value -match "^($SystemDrive\\?|\\)Users(?!\\+Public\\*)")
			{
				# Anything that mentions or leads to user profile that is not already in the UserProfile variable
				$IsUserProfile = $true
				$script:UserProfile += $Entry
			}

			$IsPathRooted = Invoke-Command @SessionParams -ScriptBlock {
				[System.IO.Path]::IsPathRooted($using:Entry.Value)
			}

			$DirectoryExists = Invoke-Command @SessionParams -ScriptBlock {
				[System.IO.Directory]::Exists($using:Entry.Value)
			}

			if ($IsPathRooted)
			{
				$script:Rooted += $Entry

				if (($Entry.Value -match "^[a-z]:"))
				{
					if (($Entry.Value -match "^[a-z]:\\"))
					{
						$script:FullyQualified += $Entry

						if ($FileExists -or $DirectoryExists)
						{
							$script:FileSystem += $Entry

							# Exclude paths containing notation for "this directory" or "parent directory"
							if (!($IsUserProfile -or $FileExists -or ($Entry.Value -match "\\+\.+\\*")))
							{
								$script:WhiteList += $Entry
							}
						}
					}
					elseif (($Entry.Value -match "^[a-z]:$"))
					{
						# Root drives without path separator are relative
						$script:Relative += $Entry

						if ($FileExists -or $DirectoryExists)
						{
							$script:FileSystem += $Entry

							if (!($IsUserProfile -or $FileExists))
							{
								# Allow to be able to format root drive
								$script:WhiteList += $Entry
							}
						}
					}
					else # Rooted but relative, ex: "C:Windows"
					{
						$script:Relative += $Entry

						if ($FileExists -or $DirectoryExists)
						{
							$script:FileSystem += $Entry
						}
					}
				}
				elseif (Test-UNC $Entry.Value -Quiet)
				{
					$script:FullyQualified += $Entry
				}
			}
			elseif ($FileExists -or $DirectoryExists)
			{
				$script:Relative += $Entry
				$script:FileSystem += $Entry
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Blacklisting entry: $($Entry.Name)"

				# Excluding anything that does not have directory syntax
				$script:BlackList += $Entry
			}
		}
	}
	elseif ($LastState.Value -ne $Exact)
	{
		# Update cache if the -Exact switch is different from what was used to create the cache
		if ($Exact)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing variable format because current exact state '$($Exact)' does not match previous state '$($LastState.Value)'"

			$script:UserProfile = $script:UserProfile | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:WhiteList = $script:WhiteList | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:FullyQualified = $script:FullyQualified | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:Rooted = $script:Rooted | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:FileSystem = $script:FileSystem | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:Relative = $script:Relative | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:BlackList = $script:BlackList | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
			$script:AllVariables = $script:AllVariables | ForEach-Object {
				[System.Collections.DictionaryEntry]::new($_.Name.Trim("%"), $_.Value)
			}
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Formatting variables because current exact state '$($Exact)' does not match previous state '$($LastState.Value)'"

			$script:UserProfile = $script:UserProfile | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:WhiteList = $script:WhiteList | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:FullyQualified = $script:FullyQualified | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:Rooted = $script:Rooted | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:FileSystem = $script:FileSystem | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:Relative = $script:Relative | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:BlackList = $script:BlackList | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
			$script:AllVariables = $script:AllVariables | ForEach-Object {
				[System.Collections.DictionaryEntry]::new("%$($_.Name)%", $_.Value)
			}
		}
	}

	Set-Variable -Name LastExactState -Scope Script -Value $Exact

	$TargetScope = switch ($From)
	{
		"UserProfile"
		{
			$script:UserProfile
			break
		}
		"WhiteList"
		{
			$script:WhiteList
			break
		}
		"FullyQualified"
		{
			$script:FullyQualified
			break
		}
		"Rooted"
		{
			$script:Rooted
			break
		}
		"FileSystem"
		{
			$script:FileSystem
			break
		}
		"Relative"
		{
			$script:Relative
			break
		}
		"BlackList"
		{
			$script:BlackList
			break
		}
		default # All
		{
			$script:AllVariables
		}
	}

	if (!$TargetScope)
	{
		Write-Error -Category ObjectNotFound -TargetObject $From `
			-Message "Environment variable group '$From' contains no entries"
		return
	}

	switch ($PsCmdlet.ParameterSetName)
	{
		"Name"
		{
			[regex] $Regex = ConvertFrom-Wildcard $Name.Trim("%") -Options "IgnoreCase" -AsRegex

			$Result = $TargetScope | Where-Object {
				$Regex.Match($_.Name.Trim("%")).Success
			} | Select-Object -ExpandProperty $Property

			if (!$Result)
			{
				Write-Error -Category ObjectNotFound -TargetObject $Name `
					-Message "Environment variable name search for '$Name' did not match anything"
				return
			}

			return $Result
		}
		"Value"
		{
			$Result = $TargetScope | Where-Object -Property Value -Like $Value |
			Select-Object -ExpandProperty $Property

			if (!$Result)
			{
				Write-Error -Category ObjectNotFound -TargetObject $Value `
					-Message "Environment variable value search for '$Value' did not match anything"
				return
			}

			return $Result
		}
		default
		{
			if ($Property)
			{
				return $TargetScope | Select-Object -ExpandProperty $Property
			}

			return $TargetScope
		}
	}
}

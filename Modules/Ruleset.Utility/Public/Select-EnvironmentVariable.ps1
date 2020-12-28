
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
Get a group of environment variables

.DESCRIPTION
Select-EnvironmentVariable gets a predefined group of environment variables.
This is useful to verify path patterns, ex. paths for firewall rules must not
contain paths with userprofile environment variable.

.PARAMETER Scope
A group of environment variables to get as follows:
- UserProfile - Environment variables that lead to valid directory in user profile
- FullyQualified - Environment variables which are valid fully qualified paths to local directory
- BlackList - All variables that don't fall into other groups
- FileSystem - All variables regardless if path qualifier is present as long as it resolves to local or network path
- All - All environment variables

.PARAMETER Force
If specified discards script scope cache and queries system for environment variables again

.EXAMPLE
PS> Select-EnvironmentVariable UserProfile

Returns all environment variables that lead to user profile

.EXAMPLE
PS> Select-EnvironmentVariable All

Returns all environment variables on computer

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

TODO: Need to see if UNC, single backslash and relative paths without a qualifier are valid for firewall
#>
function Select-EnvironmentVariable
{
	[OutputType([System.Collections.DictionaryEntry])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Select-EnvironmentVariable.md")]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet("BlackList", "FileSystem", "UserProfile", "Rooted", "FullyQualified", "Rooted", "All")]
		[string] $Scope,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($Force -or !(Get-Variable -Name BlackListEnvironment -Scope Script -ErrorAction Ignore))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Initializing environment variable groups"

		$FQPN = @()
		$UserProfileLocal = @()
		$BlackListLocal = @()
		$RootedLocal = @()
		$FileSystemLocal = @()

		New-Variable -Name UserProfileValues -Scope Local -Option Constant -Value @(
			"%APPDATA%"
			"%HOME%"
			"%LOCALAPPDATA%"
			"%OneDrive%"
			"%TEMP%"
			"%TMP%"
			"%USERPROFILE%"
			"%OneDriveConsumer%"
			# NOTE: These are in BlackList group as well, we need to list them here as well
			"%USERNAME%"
			"%HOMEPATH%"
		)

		# Make an array of (environment variable/path) name/value pair
		foreach ($Entry in @(Get-ChildItem Env:))
		{
			# TODO: For some reason % is missing in results
			$Name = "%" + $Entry.Name + "%"

			# https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing entry: $Name"

			if ($UserProfileValues -contains $Name)
			{
				$UserProfileLocal += $Entry
			}

			# TODO: testing needed
			if ([System.IO.Directory]::Exists($Entry.Value))
			{
				$FileSystemLocal += $Entry

				if ([System.IO.Path]::IsPathRooted($Entry.Value))
				{
					if (Split-Path -Path $Entry.Value -Qualifier -ErrorAction Ignore)
					{
						$FQPN += $Entry
					}

					# if it starts with drive letter
					if (($Entry.Value -match "^[a-z]:\\"))
					{
						$RootedLocal += $Entry
					}
					elseif ($Entry.Value -match "^[a-z]:$")
					{
						$RootedLocal += $Entry
					}
				}
			}
			elseif (Test-UNC $Entry.Value -Quiet)
			{
				$FQPN += $Entry
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Blacklisting entry: $($Entry.Name)"

				# Excluding anything that is not path
				$BlackListLocal += $Entry
			}
		}

		Set-Variable -Name FullyQualifiedEnvironment -Scope Script -Option ReadOnly -Force -Value $FQPN
		Set-Variable -Name UserProfileEnvironment -Scope Script -Option ReadOnly -Force -Value $UserProfileLocal
		Set-Variable -Name RootedEnvironment -Scope Script -Option ReadOnly -Force -Value $RootedLocal
		Set-Variable -Name BlackListEnvironment -Scope Script -Option ReadOnly -Force -Value $BlackListLocal
		Set-Variable -Name FileSystemEnvironment -Scope Script -Option ReadOnly -Force -Value $FileSystemLocal
	}

	switch ($Scope)
	{
		"UserProfile"
		{
			$UserProfileEnvironment
			break
		}
		"FullyQualified"
		{
			$FullyQualifiedEnvironment
			break
		}
		"BlackList"
		{
			$BlackListEnvironment
			break
		}
		"Rooted"
		{
			$RootedEnvironment
			break
		}
		"FileSystem"
		{
			$FileSystemEnvironment
			break
		}
		default # All
		{
			$FileSystemEnvironment
			$BlackListEnvironment
		}
	}
}

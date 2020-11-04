
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
Get-EnvironmentVariable gets a predefined group of environment variables.
This is useful to verify path patterns, ex. paths for firewall rules must not
contain paths with userprofile environment variable.

.PARAMETER Group
A group of environment variables to get as follows:
1. UserProfile - Environment variables that leads to valid directory in user profile
2. WhiteList - Environment variables which are valid directories
3. BlackList - The opposite of WhiteList
4. All - Whitelist and BlackList together

.EXAMPLE
PS> Get-EnvironmentVariable UserProfile

Returns all environment variables that lead to user profile

.EXAMPLE
PS> Get-EnvironmentVariable All

Returns all environment variables on computer

.INPUTS
None. You cannot pipe objects to Get-EnvironmentVariable

.OUTPUTS
[System.Collections.DictionaryEntry]

.NOTES
None.
#>
function Get-EnvironmentVariable
{
	[OutputType([System.Collections.DictionaryEntry])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-EnvironmentVariable.md")]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet("BlackList", "WhiteList", "UserProfile", "All")]
		[string] $Group
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if (!(Get-Variable -Name BlackListEnvironment -Scope Script -ErrorAction Ignore))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Initializing environment variable groups"

		$UserProfileLocal = @()
		$BlackListLocal = @()
		$WhiteListLocal = @()

		New-Variable -Name UserProfileValues -Scope Local -Option Constant -Value @(
			"%APPDATA%"
			"%HOME%"
			"%LOCALAPPDATA%"
			"%OneDrive%"
			"%TEMP%"
			"%TMP%"
			"%USERPROFILE%"
			"%OneDriveConsumer%"
			# NOTE: These are in BlackList group
			# "%USERNAME%"
			# "%HOMEPATH%"
		)

		# Make an array of (environment variable/path) name/value pair,
		foreach ($Entry in @(Get-ChildItem Env:))
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

			# if starts with drive letter and is a valid container
			if (($Entry.Value -match "^\w:.*") -and (Test-Path -Path $Entry.Value -PathType Container))
			{
				# NOTE: For some reason these are missing in results
				$Entry.Name = "%" + $Entry.Name + "%"

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting whitelist candidate: $($Entry.Name)"
				$WhiteListLocal += $Entry

				if ($UserProfileValues -contains $Entry.Name)
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting user profile candidate: $($Entry.Name)"
					$UserProfileLocal += $Entry
				}
			}
			else
			{
				# excluding non path values
				$Entry.Name = "%" + $Entry.Name + "%"

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting blacklist candidate: $($Entry.Name)"
				$BlackListLocal += $Entry
			}
		}

		New-Variable -Name UserProfileEnvironment -Scope Script -Option Constant -Value $UserProfileLocal
		New-Variable -Name WhiteListEnvironment -Scope Script -Option Constant -Value $WhiteListLocal
		New-Variable -Name BlackListEnvironment -Scope Script -Option Constant -Value $BlackListLocal
	}

	switch -Wildcard ($Group)
	{
		"UserProfile"
		{
			$UserProfileEnvironment
			break
		}
		"WhiteList"
		{
			$WhiteListEnvironment
			break
		}
		"BlackList"
		{
			$BlackListEnvironment
			break
		}
		default # All
		{
			$WhiteListEnvironment
			$BlackListEnvironment
		}
	}
}

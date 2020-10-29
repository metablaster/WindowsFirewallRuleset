
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Check if input path leads to user profile
.DESCRIPTION
User profile paths are not valid for firewall rules, this method help to check if this is true
.PARAMETER FilePath
File path to check, can be unformatted or have environment variables
.EXAMPLE
PS> Test-UserProfile "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
.INPUTS
None. You cannot pipe objects to Test-UserProfile
.OUTPUTS
[bool] true if userprofile path or false otherwise
.NOTES
TODO: is it possible to nest this into Test-Environment somehow?
TODO: This should proably be inside Utility or UserInfo module
#>
function Test-UserProfile
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Test-UserProfile.md")]
	param (
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Impossible to know what the input may be
	if ([string]::IsNullOrEmpty($FilePath))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $false
	}

	# Make an array of (environment variable/path) value pair,
	# user profile environment variables only
	$Variables = @()
	foreach ($Entry in @(Get-ChildItem Env:))
	{
		$Entry.Name = "%" + $Entry.Name + "%"
		# NOTE: Avoid spamming
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing $($Entry.Name)"

		if ($UserProfileEnvironment -contains $Entry.Name)
		{
			# NOTE: Avoid spamming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Selecting $($Entry.Name)"
			$Variables += $Entry
		}
	}

	# TODO: sorted result will have multiple same variables,
	# Sorting from longest paths which should be checked first
	$Variables = $Variables | Sort-Object -Descending { $_.Value.Length }

	# Strip away quotations from path
	$FilePath = $FilePath.Trim('"')
	$FilePath = $FilePath.Trim("'")

	# Replace double slashes with single ones
	$FilePath = $FilePath.Replace("\\", "\")

	# If input path is root drive, removing a slash would produce bad path
	# Otherwise remove trailing slash for cases where entry path is convertible to variable
	if ($FilePath.Length -gt 3)
	{
		$FilePath = $FilePath.TrimEnd('\\')
	}

	# Make a copy of file path because modification can be wrong
	$SearchString = $FilePath

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$FilePath' already contains user profile environment variable"
	foreach ($Variable in $Variables)
	{
		if ($FilePath -like "$($Variable.Name)*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path leads to user profile"
			return $true
		}
	}

	while (![string]::IsNullOrEmpty($SearchString))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to user profile environment variable"

		foreach ($Entry in $Variables)
		{
			if ($Entry.Value -like "*$SearchString")
			{
				# Environment variable found, if this is first hit, trailing slash is already removed
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path leads to user profile"
				return $true
			}
		}

		# Strip away file or last folder in path then try again (also trims trailing slash)
		$SearchString = Split-Path -Path $SearchString -Parent
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] input path does not lead to user profile"
	return $false
}

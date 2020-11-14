
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
Format path into firewall compatible path

.DESCRIPTION
Various paths drilled out of registry, and those specified by the user must be
checked and properly formatted.
Formatted paths will also help sorting rules in firewall GUI based on path.

.PARAMETER FilePath
File path to format, can have environment variables, or consists of trailing slashes.

.EXAMPLE
PS> Format-Path "C:\Program Files\\Dir\"

.INPUTS
[string] File path to format

.OUTPUTS
[string] formatted path, includes environment variables, stripped off of junk

.NOTES
TODO: This should proably be inside utility module,
it's here since only this module uses this function.
#>
function Format-Path
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Format-Path.md")]
	[OutputType([string])]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[string] $FilePath
	)

	process
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		# Impossible to know what the input may be
		if ([string]::IsNullOrEmpty($FilePath))
		{
			# TODO: why allowing empty path?
			# NOTE: Avoid spamming
			# Write-Debug -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
			return $FilePath
		}

		# Strip away quotations from path
		$FilePath = $FilePath.Trim('"')
		$FilePath = $FilePath.Trim("'")

		# Some paths may have semicolon (ie. command paths)
		$FilePath = $FilePath.TrimEnd(";")

		# Replace double slashes with single ones
		$FilePath = $FilePath.Replace("\\", "\")

		# NOTE: forward slashes while valid for firewall rule are not valid to format path into
		# environment variable.
		$FilePath = $FilePath.Replace("//", "\")

		# Replace forward slashes with backward ones
		$FilePath = $FilePath.Replace("/", "\")

		# If input path is root drive, removing a slash would produce bad path
		# Otherwise remove trailing slash for cases where entry path is convertible to variable
		if ($FilePath.Length -gt 3)
		{
			$FilePath = $FilePath.TrimEnd("\")
		}

		# TODO: sorted result will have multiple same variables,
		# Sorting from longest paths which should be checked first
		$Variables = Get-EnvironmentVariable WhiteList | Sort-Object -Descending { $_.Value.Length }

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$FilePath' already contains valid environment variable"
		foreach ($Variable in $Variables)
		{
			if ($FilePath -like "$($Variable.Name)*")
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Input path already formatted: $FilePath"
				return $FilePath
			}
			# NOTE: else if it contains bad environment variable, Test-Environment should be used
			# to show warning or error message, we'll expand bad variables anyway.
		}

		# NOTE: The path may contain invalid or multiple environment variables, ex. those previously excluded
		$FilePath = [System.Environment]::ExpandEnvironmentVariables($FilePath)

		# Make a copy of file path because modification can be wrong
		$SearchString = $FilePath

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to environment variable"
		while (![string]::IsNullOrEmpty($SearchString))
		{
			foreach ($Entry in $Variables)
			{
				if ($Entry.Value -like $SearchString)
				{
					# Environment variable found, if this is first hit, trailing slash is already removed
					$FilePath = $FilePath.Replace($SearchString, $Entry.Name)
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Formatting input path to: $FilePath"
					return $FilePath
				}
			}

			# Strip away file or last folder in path then try again (also trims trailing slash)
			$SearchString = Split-Path -Path $SearchString -Parent
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if '$SearchString' is convertible to environment variable"
		}

		# The path has been reduced to root drive so get that
		$SearchString = Split-Path -Path $FilePath -Qualifier
		Write-Debug -Message "[$($MyInvocation.InvocationName)] path has been reduced to root drive, now searching for: $SearchString"

		# Find candidate replacements for the qualifier
		$Variables = $Variables | Where-Object { $_.Value -eq $SearchString }

		if ([string]::IsNullOrEmpty($Variables))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Environment variables for input path don't exist"
			# There are no environment variables for this drive, just trim trailing slash
			# NOTE: TrimEnd, this is here for drive root paths, drive root environment variables as
			# well as all other paths returned from this function don't have ending slash either.
			return $FilePath.TrimEnd("\")
		}
		elseif (($Variables | Measure-Object).Count -gt 1)
		{
			# Since there may be duplicate entries, we grab first one
			$Replacement = $Variables.Name[0]
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Multiple matches exist for '$SearchString', selecting first one: $Replacement"
		}
		else
		{
			# If there is single match, selecting [0] would result in selecting first letter instead of env. variable!
			$Replacement = $Variables.Name
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Found exact match for '$SearchString' -> $Replacement"
		}

		# Only root drive is converted, just trim away trailing slash if this is qualifier
		$FilePath = $FilePath.Replace($SearchString, $Replacement).TrimEnd("\")

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Only root drive is formatted: $FilePath"
		return $FilePath
	}
}

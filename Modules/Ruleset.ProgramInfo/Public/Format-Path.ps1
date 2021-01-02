
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
Format file system path and fix syntax errors

.DESCRIPTION
Most path syntax errors are fixed however the path is never resolved or tested for existence.
For example, relative path will stay relative and if the path location does not exist it is not created.

Various paths drilled out of registry can be invalid and those specified manuallay may contain typos,
this algorithm will attempt to correct these problems, in addition to providing consistent path output.

If possible portion of the path is converted into system environment variable to shorten the length of a path.
Formatted paths will also help sorting rules in firewall GUI based on path.
Only file system paths are supported.

.PARAMETER LiteralPath
File system path to format, can have environment variables, or it may contain redundant or invalid characters.

.EXAMPLE
PS> Format-Path "C:\Program Files\WindowsPowerShell"
%ProgramFiles%\WindowsPowerShell

.EXAMPLE
PS> Format-Path "%SystemDrive%\Windows\System32"
%SystemRoot%\System32

.EXAMPLE
PS> Format-Path ..\dir//.\...
..\dir\.\..

.EXAMPLE
PS> Format-Path ~/\Direcotry//file.exe
~\Direcotry\file.exe

.EXAMPLE
PS> Format-Path '"C:\ProgramData\Git"'
%ALLUSERSPROFILE%\Git

.INPUTS
[string] File path to format

.OUTPUTS
[string] formatted path, includes environment variables, stripped off of junk

.NOTES
TODO: This should proably be in utility module, it's here since only this module uses this function.
#>
function Format-Path
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Format-Path.md")]
	[OutputType([string])]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $LiteralPath
	)

	begin
	{
		# NOTE: Not used
		# Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	}
	process
	{
		foreach ($PathEntry in $LiteralPath)
		{
			# Impossible to know what the input may be while drilling registry, for same reason
			# we can't implement reference to parameter
			if ([string]::IsNullOrEmpty($PathEntry))
			{
				# NOTE: Not used
				# Write-Debug -Message "[$($MyInvocation.InvocationName)] The path is null or empty"
				continue
			}

			# TODO: Trim only if both ends match same quotation character
			# Strip away quotations from path
			$NewPath = $PathEntry.Trim("'")
			$NewPath = $NewPath.Trim('"')

			# TODO: Semicolon is valid character to name a path
			# Some paths drilled out of registry may have semicolon (ie. command paths)
			$NewPath = $NewPath.TrimEnd(";")

			# NOTE: Forward slashes while possibly valid for firewall rule are not desired or valid
			# to format starting portion of the path into environment variable.
			$NewPath = $NewPath.Replace("/", "\")

			# Environment variables such as PATH or PSModulePath should not be formatted any further
			[regex] $Regex = ";+[A-Za-z]:"

			if ($Regex.Match($NewPath).Success)
			{
				[regex] $Regex = ";+"
				if ($Regex.Match($NewPath).Success)
				{
					# Remove empty entries
					$NewPath = $Regex.Replace($NewPath, ";").TrimEnd(";")
				}

				Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified path is multi directory, likely environment variable"
				Write-Output $NewPath
				continue
			}

			[regex] $Regex = "\.{3,}"
			if ($Regex.Match($NewPath).Success)
			{
				$NewPath = $Regex.Replace($NewPath, "..")
			}

			# NOTE: The path may contain invalid or multiple environment variables,
			# we'll expand any known variables to maximize the length of a path formatted into environment variable
			$NewPath = [System.Environment]::ExpandEnvironmentVariables($NewPath)

			# See if expansion resulted in multiple pats
			# Note that % is valid character to name a file or directory
			$BadData = [regex]::Match($NewPath, "([A-Za-z]:\\?){2,}?")

			if ($BadData.Success)
			{
				# Formatting such path makes no sense, it must be fixed instead
				Write-Warning -Message "Result of variable expansion resulted in multiple paths, formatting aborted"

				Write-Output $PathEntry
				continue
			}

			# File system qualifier must be single letter
			$BadData = [regex]::Match($NewPath, "([A-Za-z]{2,}:\\?)+?")

			if ($BadData.Success)
			{
				Write-Warning -Message "Path qualifier '$($BadData.Groups[1].Value)' not supported, formatting aborted"
				Write-Output $PathEntry
				continue
			}

			# Qualifier ex. "C:\" "D:", "\" or "\\"
			# Unqualified: Anything except qualifier
			$PathGroups = [regex]::Match($NewPath, "(?<Qualifier>^[A-Za-z]:\\?|^\\{1,2})?(?<Unqualified>.*)")
			$Qualifier = $PathGroups.Groups["Qualifier"]
			$Unqualified = $PathGroups.Groups["Unqualified"]

			if ($Unqualified.Success)
			{
				# Remove surplus backslashes, also trims last backslash
				$SplitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
				$PathSplit = $Unqualified.Value.Split("\", $SplitOptions)
				$NewPath = [string]::Join("\", $PathSplit)

				# Put correct(ed) qualifier back if the path isn't relative
				if ($Qualifier.Success)
				{
					if ($NewPath.Length)
					{
						$NewPath = $NewPath.Insert(0, $Qualifier.Value)
					}
					# TODO: Duplicate code
					elseif ($Qualifier.Value.StartsWith("\"))
					{
						$NewPath = $Qualifier.Value
					}
					else
					{
						$NewPath = $Qualifier.Value.TrimEnd("\")
					}
				}
			}
			elseif ($Qualifier.Success)
			{
				if ($Qualifier.Value.StartsWith("\"))
				{
					$NewPath = $Qualifier.Value
				}
				else
				{
					$NewPath = $Qualifier.Value.TrimEnd("\")
				}
			}
			else
			{
				Write-Error -Category InvalidResult -TargetObject $NewPath -Message "Unable to format path: '$NewPath'"
				Write-Output $NewPath
				continue
			}

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] The path was formatted to: '$NewPath'"

			# TODO: Sorted result will have multiple same variable values, with different name though,
			# Sorting such that longest path values start first to be able to replace maximum amount of a path into environment variable
			$WhiteList = Select-EnvironmentVariable -From WhiteList | Sort-Object -Descending { $_.Value.Length }

			# Make a starting Match object equal to full path
			$SearchString = [regex]::Match($NewPath, ".+")

			:environment while ($SearchString.Success)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Checking if '$($SearchString.Value)' is convertible to environment variable"

				foreach ($Entry in $WhiteList)
				{
					if ($Entry.Value -like $SearchString.Value)
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Inserting $($Entry.Name) in place of: '$($SearchString.Value)'"

						# Environment variable found
						$NewPath = $NewPath.Replace($SearchString.Value, $Entry.Name)
						break environment
					}
				}

				# else strip off path leaf (file or last directory) then try again
				$SearchString = [regex]::Match($SearchString.Value, ".+(?=\\.*\\*)")
			}

			if (!$SearchString.Success)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Unable to find environment variable for: '$NewPath'"
			}

			Write-Output $NewPath
		}
	}
}


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
Test if given installation directory is valid

.DESCRIPTION
Test if given installation directory is valid and if not this method will search the
system for valid path and return it via reference parameter

.PARAMETER Program
Predefined program name for which to search

.PARAMETER FilePath
Reference to variable which holds a path to program (excluding executable)

.EXAMPLE
PS> $MyProgram = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
PS> Test-Installation "Office" ([ref] $MyProgram)

.INPUTS
None. You cannot pipe objects to Test-Installation

.OUTPUTS
[bool] true if path is ok or found false otherwise,
via reference, if test OK same path, if not try to update path, else given path back is not modified

.NOTES
TODO: temporarily using ComputerName parameter
#>
function Test-Installation
{
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Test-Installation.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Program,

		[Parameter(Mandatory = $true, Position = 1)]
		[ref] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# If input path is valid just make sure it's formatted
	# NOTE: for debugging purposes we want to ignore default installation variables
	# and force searching programs
	# NOTE: this will cause "converted" path message in all cases
	if (!$Develop -and (Test-Environment $FilePath.Value))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Formatting $FilePath"
		$FilePath.Value = Format-Path $FilePath.Value

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation path for $Program well known"
		return $true # input path is correct
	}
	elseif (Find-Installation $Program)
	{
		# NOTE: the paths in installation table are supposed to be formatted
		$InstallLocation = "unknown install location"
		$Count = $InstallTable.Rows.Count

		if ($Count -gt 1)
		{
			# TODO: Duplicate of global todo, need to prompt to handle all cases or choose one,
			# TODO: Prompts should be inserted into table, ex. abort, all
			Write-Information -Tags "User" -MessageData "INFO: Found multiple candidate installation directories for $Program"

			# Sort the table by ID column in ascending order
			# NOTE: not needed if table is not modified
			$InstallTable.DefaultView.Sort = "ID asc"
			$InstallTable = $InstallTable.DefaultView.ToTable()

			# Print out all candidate rows
			Show-Table "Input '0' to abort this operation"

			# Prompt user to chose one
			[int32] $Choice = -1
			while ($Choice -lt 0 -or $Choice -gt $Count)
			{
				Write-Information -Tags "User" -MessageData "INFO: Input the ID number to choose which one is correct"
				$UserInput = Read-Host

				if ($UserInput -notmatch '^-?\d+$')
				{
					Write-Information -Tags "User" -MessageData "INFO: Digits only please!"
					continue
				}

				$Choice = $UserInput
			}

			if ($Choice -eq 0)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] User input is: $Choice, canceling operation"

				# User doesn't know the path, skip correction message
				return $false
			}

			$InstallLocation = $InstallTable.Rows[$Choice - 1].InstallLocation
		}
		else
		{
			$InstallLocation = $InstallTable | Select-Object -ExpandProperty InstallLocation
		}

		# Don't show correction the path is same, taking case sensitivity into account.
		if ($FilePath.Value -cne $InstallLocation)
		{
			# Using single quotes to make emptiness obvious when the path is empty.
			Write-Information -Tags "Project" -MessageData "INFO: Path corrected from: '$($FilePath.Value)' to: '$InstallLocation'"
		}

		$FilePath.Value = $InstallLocation

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Installation for $Program found"
		return $true # installation path found
	}
	else
	{
		return $false # installation not found
	}
}

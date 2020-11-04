
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
Test if a path is valid with additional checks

.DESCRIPTION
Similar to Test-Path but expands environment variables and performs additional checks if desired:
1. check if input path is compatible for firewall rules.
2. check if the path leads to user profile
Both of which can be limited to either container of leaf path type.

.PARAMETER Path
Path to folder, Allows null or empty since input may come from other commandlets which
can return empty or null

.PARAMETER PathType
A type of path to test, can be one of the following:
1. Leaf -The path is file or registry entry
2. Container - the path is container such as folder or registry key
3. Any - Leaf or Container

.PARAMETER Firewall
Ensures the path is valid for firewall rule

.PARAMETER UserProfile
Checks if the path leads to user profile

.EXAMPLE
PS> Test-Environment %SystemDrive%

.INPUTS
None. You cannot pipe objects to Test-Environment

.OUTPUTS
[bool] true if path exists, false otherwise

.NOTES
TODO: This should proably be part of utility module
#>
function Test-Environment
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Test-Environment.md")]
	[OutputType([bool])]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string] $Path,

		[Parameter()]
		[ValidateSet("Leaf", "Container", "Any")]
		[string] $PathType = "Container",

		[Parameter()]
		[switch] $Firewall,

		[Parameter()]
		[switch] $UserProfile
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if path is valid for firewall rule"

	if ([string]::IsNullOrEmpty($Path))
	{
		Write-Warning -Message "Path name is null or empty"
		# Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $false
	}
	elseif (Test-Path -Path $Path -IsValid)
	{
		$UserVariables = Get-EnvironmentVariable UserProfile | Select-Object -ExpandProperty Name

		# Status to check Path is valid with UserProfile and Firewall
		[bool] $Status = $true

		if ($UserProfile -or $Firewall)
		{
			if ([array]::Find($UserVariables, [System.Predicate[string]] { $Path -like "$($args[0])*" }))
			{
				if ($Firewall)
				{
					$Status = $false
					Write-Warning -Message "Paths including environment variables which lead to user profile are not valid for firewall"
				}
			}
			# TODO: We need target computer system drive instead of localmachine systemdrive
			# NOTE: This pattern is fine for firewall
			elseif ($UserProfile -and ($Path -notmatch "^$env:SystemDrive\\+Users(\\?$|\\+(?!Public\\.))"))
			{
				# NOTE: Not showing anything
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] The path does not lead to user profile"
				return $false
			}
		}

		if ($Status)
		{
			if (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Path)) -PathType $PathType)
			{
				return $true
			}

			# Why it failed:
			$BadVariables = Get-EnvironmentVariable BlackList | Select-Object -ExpandProperty Name
			if ([array]::Find($BadVariables, [System.Predicate[string]] { $Path -like "$($args[0])*" }))
			{
				Write-Warning -Message "Specified environment variable is not valid for paths"
			}
			else
			{
				Write-Warning -Message "Specified path does not exist"
			}
		}
	}
	else # -IsValid
	{
		Write-Warning -Message "The path syntax is invalid"
	}

	Write-Information -Tags "Project" -MessageData "INFO: Invalid path is: $Path"
	return $false
}

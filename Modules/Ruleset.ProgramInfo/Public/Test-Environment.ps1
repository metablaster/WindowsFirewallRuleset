
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
Validates only file system paths and expands environment variables in doing so.
Optionally checks if the path is compatible for firewall rules or if the path leads to
user profile.
Both of which can be limited to either container or leaf path type.

.PARAMETER LiteralPath
Path to directory or file which to test.
Allows null or empty since it may come from commandlets which may return empty string or null

.PARAMETER PathType
The type of path to test, can be one of the following:
1. File - The path is path to file
2. Directory - The path is path to directory
3. Any - The path is either path to file or directory, this is default

.PARAMETER Firewall
Ensures the path is valid for firewall rule

.PARAMETER UserProfile
Checks if the path leads to user profile

.PARAMETER Strict
If specified this function produces errors instead of warnings.

.PARAMETER Quiet
If specified does not write any warnings or errors, only true or false is returned.

.EXAMPLE
PS> Test-Environment "%Windir%"

True, The path is valid, and it exists

.EXAMPLE
PS> Test-Environment "'%Windir%\System32'"

False, Invalid path syntax

.EXAMPLE
PS> Test-Environment "%HOME%\AppData\Local\MicrosoftEdge" -Firewall -UserProfile

False, the path leads to userprofile and will not work for firewall

.EXAMPLE
PS> Test-Environment "%SystemDrive%\Users\USERNAME\AppData\Local\MicrosoftEdge" -Firewall -UserProfile

True, the path leads to userprofile, is good for firewall rule and it exists

.EXAMPLE
Test-Environment "%LOCALAPPDATA%\MicrosoftEdge" -UserProfile

True, the path lead to user profile, and it exists

.INPUTS
None. You cannot pipe objects to Test-Environment

.OUTPUTS
[bool] true if path exists, false otherwise

.NOTES
The result of this function should be used only to verify paths for external usage, not as input to
commandles which don't recognize system environment variables.
This function is needed in cases where the path may be a modified version of an already formatted or
verified path such as in rule scripts or to verify manually edited installation table.
TODO: This should proably be part of utility module, it's here since only this module uses this function.
#>
function Test-Environment
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "None",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Environment.md")]
	[OutputType([bool])]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string] $LiteralPath,

		[Parameter()]
		[Alias("Type")]
		[ValidateSet("File", "Directory", "Any")]
		[string] $PathType = "Any",

		[Parameter()]
		[switch] $Firewall,

		[Parameter()]
		[switch] $UserProfile,

		[Parameter(ParameterSetName = "Strict")]
		[switch] $Strict,

		[Parameter(ParameterSetName = "Quiet")]
		[switch] $Quiet
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	function Write-Conditional
	{
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
			"PSProvideCommentHelp", "", Scope = "Function", Justification = "Inner function needs no help")]
		param(
			[string] $Message
		)

		if ($Quiet)
		{
			# Make sure -Quiet switch does not make fun of us
			Write-Debug -Message "[$($MyInvocation.InvocationName)] $Message"
		}
		elseif ($Strict)
		{
			Write-Error -Category InvalidArgument -TargetObject $LiteralPath -Message $Message
		}
		else
		{
			Write-Warning -Message $Message
		}
	}

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($LiteralPath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking path: $ExpandedPath"

	if ([string]::IsNullOrEmpty($LiteralPath))
	{
		Write-Conditional "The path name is null or empty"
		return $false
	}
	elseif (Test-Path -Path $LiteralPath -IsValid)
	{
		if ($UserProfile -or $Firewall)
		{
			$UserVariables = Select-EnvironmentVariable -Scope UserProfile | Select-Object -ExpandProperty Name
			$IsUserProfile = [array]::Find($UserVariables, [System.Predicate[string]] { $LiteralPath -like "$($args[0])*" })

			if ($Firewall -and $IsUserProfile)
			{
				Write-Conditional "A Path with environment variable which leads to user profile is not valid for firewall"
				Write-Information -Tags "Project" -MessageData "INFO: Invalid path is: $LiteralPath"
				return $false
			}

			# TODO: We need target computer system drive instead of localmachine systemdrive
			# NOTE: Public folder and it's subdirectories are fine for firewall
			if (!$IsUserProfile -and $UserProfile -and ($ExpandedPath -match "^($env:SystemDrive\\?|\\)Users(?!\\+Public\\*)"))
			{
				# Not showing anything
				Write-Debug -Message "[$($MyInvocation.InvocationName)] The path does not lead to user profile"
				return $false
			}
		}

		if (($PathType -eq "Any") -and !([System.IO.Directory]::Exists($ExpandedPath) -or [System.IO.File]::Exists($ExpandedPath)))
		{
			$NotFoundMessage = "Specified file or directory does not exist"
		}
		elseif (($PathType -eq "Directory") -and ![System.IO.Directory]::Exists($ExpandedPath))
		{
			$NotFoundMessage = "Specified directory does not exist"
		}
		elseif (($PathType -eq "File") -and ![System.IO.File]::Exists($ExpandedPath))
		{
			$NotFoundMessage = "Specified file does not exist"
		}
		else
		{
			return $true
		}

		# Determine the source of a failure ...
		$RegMatch = [regex]::Matches($LiteralPath, "%+")

		if ($RegMatch.Count -eq 0)
		{
			if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($LiteralPath))
			{
				Write-Conditional "Specified path contains unresolved wildcard pattern"
			}
			elseif ((Split-Path -Path $ExpandedPath -NoQualifier) -match '[\<\>\:\"\|]')
			{
				# NOTE: back slash and forward slash is illegal too, however it will be interpreted as path separator
				Write-Conditional "Specified path contains invalid characters"
			}
			else
			{
				Write-Conditional $NotFoundMessage
			}
		}
		elseif ($RegMatch.Count -eq 2)
		{
			$BlackList = Select-EnvironmentVariable -Scope BlackList | Select-Object -ExpandProperty Name

			if ([array]::Find($BlackList, [System.Predicate[string]] { $LiteralPath -like "$($args[0])*" }))
			{
				Write-Conditional "Specified environment variable is not valid for paths"
			}
			else
			{
				Write-Conditional $NotFoundMessage
			}
		}
		else
		{
			Write-Conditional "Specified path contains invalid amount of (%) percentage characters"
		}
	}
	else # -IsValid
	{
		Write-Conditional "Specified path is not a valid path"
	}

	Write-Information -Tags "Project" -MessageData "INFO: Invalid path is: $LiteralPath"
	return $false
}

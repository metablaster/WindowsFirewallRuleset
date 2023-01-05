
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Compare two paths for equality or similarity

.DESCRIPTION
Compare-Path depending on parameters either checks if two paths lead to same location
taking into account environment variables, relative path locations and wildcards.
Or it checks if two paths are similar which depends on wildcards contained in the input

.PARAMETER Path
The path which to compare against the reference path

.PARAMETER ReferencePath
The path against which to compare

.PARAMETER Loose
If specified, perform "loose" comparison:
Does not attempt to resolve input paths, and respects wildcards all of which happens
after input paths have been expanded off environment variables

.PARAMETER CaseSensitive
If specified, performs case sensitive comparison

.EXAMPLE
PS> Compare-Path "%SystemDrive%\Windows" "C:\Win*" -Loose
True

.EXAMPLE
PS> Compare-Path "%SystemDrive%\Win*\System32\en-US\.." "C:\Wind*\System3?\" -CaseSensitive
True

.EXAMPLE
PS> Compare-Path "%SystemDrive%\" "D:\"
False

.INPUTS
None. You cannot pipe objects to Compare-Path

.OUTPUTS
[bool]

.NOTES
None.
#>
function Compare-Path
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Compare-Path.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[string] $Path,

		[Parameter(Mandatory = $true, Position = 1)]
		[string] $ReferencePath,

		[Parameter()]
		[switch] $Loose,

		[Parameter()]
		[switch] $CaseSensitive
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Expand environment variables
	[string] $ComparePath = [System.Environment]::ExpandEnvironmentVariables($Path)
	[string] $RefPath = [System.Environment]::ExpandEnvironmentVariables($ReferencePath)

	if ($Loose)
	{
		# Get rid of surplus backslashes and forwardslashes
		$ComparePath = $ComparePath.Replace("/", "\")
		$ComparePath = $ComparePath.Replace("\\", "\").TrimEnd("\")

		$RefPath = $RefPath.Replace("/", "\")
		$RefPath = $RefPath.Replace("\\", "\").TrimEnd("\")

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] TargetPath is '$ComparePath'"
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] ReferencePath is '$RefPath'"

		if ($CaseSensitive)
		{
			return  $ComparePath -clike $RefPath
		}

		return  $ComparePath -like $RefPath
	}

	# NOTE: The path must be expanded for Resolve-Path, it eliminates all but last backslash
	if (Test-Path -Path $RefPath)
	{
		$RefPath = Resolve-Path -Path $RefPath
		if ($RefPath)
		{
			$RefPath = $RefPath.TrimEnd("\")
		}
	}
	if (Test-Path -Path $ComparePath)
	{
		$ComparePath = Resolve-Path -Path $ComparePath
		if ($ComparePath)
		{
			$ComparePath = $ComparePath.TrimEnd("\")
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] TargetPath is '$ComparePath'"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] ReferencePath is '$RefPath'"

	if ($CaseSensitive)
	{
		return $ComparePath -ceq $RefPath
	}

	return $ComparePath -eq $RefPath
}

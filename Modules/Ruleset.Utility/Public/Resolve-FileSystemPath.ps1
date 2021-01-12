
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Resolve wildcard pattern of a directory or file location

.DESCRIPTION
Ensure directory or file name wildcard pattern resolves to single location.
Unlike Resolve-Path which accepts and produces paths supported by any PowerShell provider,
this function accepts only file system paths, and produces either [System.IO.DirectoryInfo] or
[System.IO.FileInfo]
Also unlike Resolve-Path the resultant path object is returned even if target file system item
does not exist, as long as portion of the specified path is resolved and as long as new path
doesn't resolve to multiple (ambiguous) locations.

.PARAMETER Path
Directory or file location to target file system item.
Wildcard characters and relative paths are supported.

.PARAMETER File
If specified, [System.IO.FileInfo] object is created instead of [System.IO.DirectoryInfo]

.PARAMETER Create
If specified, target directory or file is created if it doesn't exist

.EXAMPLE
PS> Resolve-FileSystemPath "C:\Win\Sys?em3*"

Resolves to "C:\Windows\System32" and returns System.IO.DirectoryInfo object

.EXAMPLE
PS> Resolve-FileSystemPath "..\..\MyFile" -File -Create

Creates file "MyFile" 2 directories back if it doesn't exist and returns System.IO.FileInfo object

.INPUTS
None. You cannot pipe objects to Resolve-FileSystemPath

.OUTPUTS
[System.IO.DirectoryInfo]
[System.IO.FileInfo]

.NOTES
TODO: Implement -Relative parameter, see Resolve-Path
#>
function Resolve-FileSystemPath
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Resolve-FileSystemPath.md")]
	[OutputType([System.IO.DirectoryInfo], [System.IO.FileInfo])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[string] $Path,

		[Parameter()]
		[switch] $File,

		[Parameter()]
		[switch] $Create
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving path: $Path"

	# Qualifier ex. "C:\" "D:", "\" or "\\"
	# Unqualified: Anything except qualifier
	$PathGroups = [regex]::Match($Path, "(?<Qualifier>^[A-Za-z]:\\?|^\\{1,2})?(?<Unqualified>.*)")
	$Qualifier = $PathGroups.Groups["Qualifier"]
	$Unqualified = $PathGroups.Groups["Unqualified"]

	if (!$PathGroups.Success)
	{
		# This should never be the case but can happen ex. if regex is modified
		Write-Error -Category ParserError -TargetObject $PathGroups -Message "Unable to determine path type"
		return
	}

	if ($Unqualified.Success)
	{
		# Location to report in error messages
		$TestPath = $Unqualified.Value

		# NOTE: Empty match will be "success", but this won't be the cause for qualifier
		if (![string]::IsNullOrEmpty($TestPath) -and !(Test-Path -Path $TestPath -IsValid))
		{
			# NOTE: This will pick up qualifiers that are not file system qualifiers such as HKLM:\
			Write-Error -Category SyntaxError -TargetObject $TestPath -Message "The path syntax is not valid: $TestPath"
			return
		}
	} # else dealing root path

	if ($Qualifier.Success)
	{
		$TestPath = $Qualifier.Value
		if (!(Test-Path -Path $TestPath -IsValid))
		{
			Write-Error -Category InvalidArgument -TargetObject $TestPath -Message "The path qualifier is not recognized: $TestPath\"
			return
		}
	}

	$TestPath = $Path

	# NOTE: Will error if path does not exists but only if no wildcards are present
	$PSTarget = Resolve-Path -Path $TestPath -ErrorAction Ignore
	$ItemCount = ($PSTarget | Measure-Object).Count

	if ($ItemCount -eq 1)
	{
		$ResolvedItem = $PSTarget.Path
	}
	elseif ($ItemCount -eq 0)
	{
		# If target item does not exist try to resolve closest existent portion of the path
		$MissingPart = Split-Path -Path $Path -Leaf
		$ParentPath = Split-Path -Path $Path -Parent

		while (![string]::IsNullOrEmpty($ParentPath))
		{
			$TestPath = $ParentPath
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving parent directory: $ParentPath"

			$PSTarget = Resolve-Path -Path $ParentPath -ErrorAction Ignore
			$ItemCount = ($PSTarget | Measure-Object).Count

			if ($ItemCount -eq 1)
			{
				if ([WildcardPattern]::ContainsWildcardCharacters($MissingPart))
				{
					Write-Error -Category InvalidArgument -TargetObject $MissingPart -Message "Missing part of the path must not contain wildcards: \$MissingPart"
					return
				}

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Parent directory was resolved to: $PSTarget"
				$ResolvedItem = "$($PSTarget.Path)\$MissingPart"
				break
			}
			elseif ($ItemCount -gt 1)
			{
				# Parent directory resolves to multiple locations
				break
			}

			# Go one directory up
			$MissingPart = "$(Split-Path -Path $ParentPath -Leaf)\$MissingPart"
			$ParentPath = Split-Path -Path $ParentPath -Parent
		}
	}

	# NOTE: Will be second check for multipath result
	if ($ItemCount -eq 1)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] The path was resolved to: $ResolvedItem"

		if ($File)
		{
			[System.IO.FileInfo] $TargetInfo = $ResolvedItem
		}
		else
		{
			[System.IO.DirectoryInfo] $TargetInfo = $ResolvedItem
		}

		if ($Create -and !$TargetInfo.Exists)
		{
			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating item: $TargetInfo"
				# NOTE: FileInfo::Create returns [System.IO.FileStream] object
				$TargetInfo.Create() | Out-Null
			}
			catch # IOException
			{
				Write-Error -Category $_.CategoryInfo.Category -TargetObject $_.TargetObject -Message "The item cannot be created: $($_.Exception.Message)"
				# NOTE: Not terminating operation
			}
		}

		return $TargetInfo
	}
	elseif ($ItemCount -gt 1)
	{
		Write-Error -Category InvalidResult -TargetObject $TestPath -Message "The path resolves to multiple ($ItemCount) locations: $TestPath"
		return
	}

	Write-Error -Category ParserError -TargetObject $TestPath -Message "Unable to resolve path: $TestPath"
}

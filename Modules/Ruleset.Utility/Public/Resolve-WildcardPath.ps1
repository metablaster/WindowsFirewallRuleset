
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
Resolve directory to single path

.DESCRIPTION
Ensure directory name wildcard pattern resolves to single path or fail.
Unlike Resolve-Path which produces System.Management.Automation.PathInfo
we use and produce System.IO.DirectoryInfo

.PARAMETER Path
Directory location to target path.
The parent directory of the target path must exist.

.PARAMETER File
File location to target file
The parent directory of the target path must exist.

.PARAMETER Create
If specified, target directory is created if it doesn't exist

.PARAMETER As
Specify desired output type, the default depens on input:
for directory it's System.IO.DirectoryInfo
for file it's System.IO.FileInfo

.EXAMPLE
PS> Resolve-WildcardPath "C:\Win\System3*"

.INPUTS
None. You cannot pipe objects to Resolve-WildcardPath

.OUTPUTS
[string]
[System.IO.DirectoryInfo]
[System.IO.FileInfo]

.NOTES
TODO: Implement [System.Management.Automation.PathInfo]
#>
function Resolve-WildcardPath
{
	[OutputType([System.IO.DirectoryInfo], [System.IO.FileInfo], [string])]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Resolve-WildcardPath.md")]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = "Directory")]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter(Mandatory = $true, ParameterSetName = "File")]
		[SupportsWildcards()]
		[System.IO.FileInfo] $File,

		[Parameter()]
		[switch] $Create,

		[Parameter()]
		[ValidateSet("Default", "String")]
		[string] $As = "Default"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($Path)
	{
		[string] $Item = "directory"
		[string] $Original = $Path.FullName
		[string] $Target = Resolve-Path -Path $Path.FullName
	}
	else
	{
		[string] $Item = "file"
		[string] $Original = $File.FullName
		[string] $Target = Resolve-Path -Path $File.FullName
	}

	$PathCount = ($Target | Measure-Object).Count

	if ($PathCount -eq 0)
	{
		$ParentPath = Split-Path -Path $Original -Parent
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving parent $Item $Original"

		$Target = Resolve-Path -Path $ParentPath
		$PathCount = ($Target | Measure-Object).Count

		if ($PathCount -eq 1)
		{
			$Target = "$Target\$(Split-Path -Path $Original -Leaf)"
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Parent $Item resolved to: $Target"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Failed to resolve parent $Item"
		}
	}

	if ($PathCount -eq 1)
	{
		if ($As -eq "String")
		{
			if ($Create -and !(Test-Path -Path $Target -PathType Container))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating $Item $Target"
				New-Item -ItemType Directory -Path $Target -ErrorAction Stop | Out-Null
			}

			return $Target
		}

		if ($Path)
		{
			[System.IO.DirectoryInfo] $TargetInfo = $Target
		}
		else
		{
			[System.IO.FileInfo] $TargetInfo = $Target
		}

		if ($Create -and !$TargetInfo.Exists)
		{
			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating $Item $TargetInfo"
				$TargetInfo.Create()
			}
			catch # IOException
			{
				Write-Error -Category InvalidResult -TargetObject $Path -Message "The $Item cannot be created: $TargetInfo"
				return $null
			}
		}

		return $TargetInfo
	}

	Write-Error -Category InvalidResult -TargetObject $Target -Message "The $Item was resolved to $PathCount locations"
}

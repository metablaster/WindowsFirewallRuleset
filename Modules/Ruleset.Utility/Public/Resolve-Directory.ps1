
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

.PARAMETER Create
If specified, target directory is created if it doesn't exist

.PARAMETER As
Specify desired output type, the default is System.IO.DirectoryInfo

.EXAMPLE
PS> Resolve-Directory "C:\Win\System3*"

.INPUTS
None. You cannot pipe objects to Resolve-Directory

.OUTPUTS
[string]
[System.IO.DirectoryInfo]

.NOTES
None.
#>
function Resolve-Directory
{
	[OutputType([System.IO.DirectoryInfo], [string])]
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Resolve-Directory.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[switch] $Create,

		[Parameter()]
		[ValidateSet("DirectoryInfo", "String")]
		[string] $As = "DirectoryInfo"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	[string] $PathInfo = Resolve-Path -Path $Path.FullName
	$PathCount = ($PathInfo | Measure-Object).Count

	if ($PathCount -eq 0)
	{
		$ParentPath = Split-Path -Path $Path.FullName -Parent
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving parent directory: $ParentPath"

		$PathInfo = Resolve-Path -Path $ParentPath
		$PathCount = ($PathInfo | Measure-Object).Count

		if ($PathCount -eq 1)
		{
			$PathInfo = "$PathInfo\$(Split-Path -Path $Path.FullName -Leaf)"
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Parent directory resolved to: $PathInfo"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Failed to resolve parent directory"
		}
	}

	if ($PathCount -eq 1)
	{
		if ($As -eq "String")
		{
			if ($Create -and !(Test-Path -Path $PathInfo -PathType Container))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory: $PathInfo"
				New-Item -ItemType Directory -Path $PathInfo -ErrorAction Stop | Out-Null
			}

			return $PathInfo
		}

		[System.IO.DirectoryInfo] $DirectoryInfo = $PathInfo

		if ($Create -and !$DirectoryInfo.Exists)
		{
			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating directory: $PathInfo"
				$DirectoryInfo.Create()
			}
			catch # IOException
			{
				Write-Error -Category InvalidResult -TargetObject $Path -Message "The directory cannot be created: $DirectoryInfo"
				return $null
			}
		}

		return $DirectoryInfo
	}

	Write-Error -Category InvalidResult -TargetObject $Path -Message "The path '$($Path.FullName)' was resolved to $PathCount locations"
}


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
Validate UNC path syntax

.DESCRIPTION
Test if UNC (Universal Naming Convention) path has correct path syntax

.PARAMETER LiteralPath
Universal Naming Convention path

.PARAMETER Strict
If specified, NETBIOS computer name must be all uppercase and must conform to IBM specifications.
By default NETBIOS computer name verification conforms to Microsoft specifications and is case insensitive.

.PARAMETER Quiet
If specified, path syntax errors are not shown, only true or false is returned.

.EXAMPLE
PS> Test-UNC \\SERVER\Share
True

.EXAMPLE
PS> Test-UNC \\SERVER
False

.EXAMPLE
PS> Test-UNC \\DESKTOP-PC\ShareName$
True

.EXAMPLE
PS> Test-UNC \\SERVER-01\Share\Directory DIR\file.exe
True

.EXAMPLE
PS> Test-UNC \SERVER-01\Share\Directory DIR
False

.INPUTS
[string[]]

.OUTPUTS
[bool]

.NOTES
A UNC path can be used to access network resources, and MUST be in the format specified by the
Universal Naming Convention.
"\\SERVER\Share\filename" are referred to as "pathname components" or "path components".
A valid UNC path MUST contain two or more path components.
"SERVER" is referred to as the "first pathname component", "Share" as the "second pathname component"
The size and valid characters for a path component are defined by the protocol used to access the
resource and the type of resource being accessed.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md

.LINK
https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file

.LINK
https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsc/149a3039-98ce-491a-9268-2f5ddef08192
#>
function Test-UNC
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[string[]] $LiteralPath,

		[Parameter()]
		[switch] $Strict,

		[Parameter()]
		[switch] $Quiet
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		if ($Quiet)
		{
			$WriteError = "SilentlyContinue"
		}
		else
		{
			$WriteError = $ErrorActionPreference
		}
	}
	process
	{
		foreach ($UNC in $LiteralPath)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing UNC: '$UNC'"

			if ($UNC.Length -gt 260)
			{
				# The maximum length for a path is 260 characters.
				# NOTE: Windows 10 version 1607 and later versions of Windows require changing a registry
				# key or using the Group Policy to remove the limit.
				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "The maximum length for an UNC path is 260 characters"
				return $false
			}

			if ($UNC -match "^\\\\\.\\")
			{
				# The "\\.\" prefix will access the Win32 device namespace instead of the Win32 file namespace.
				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "The specified UNC path bellongs to Win32 device namespace: $UNC"

				return $false
			}

			if (!$UNC.StartsWith("\\"))
			{
				if ([string]::IsNullOrEmpty($UNC))
				{
					Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
						-Message "The UNC path syntax verification failed for '$UNC' because it's an empty string"
					return $false
				}

				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "The UNC path syntax verification failed for '$UNC', the path must begin with 2 backslash characters"
				return $false
			}

			$PathSplit = $UNC.TrimStart("\").Split("\")

			if ($PathSplit.Count -lt 2)
			{
				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "The UNC path syntax verification failed for '$UNC', the path must be minimum in the form of \\SERVER\Share"
				return $false
			}

			# Test-NetBiosName will report errors otherwise
			if (Test-NetBiosName $PathSplit[0] -Target Domain -Strict:$Strict -Quiet:$Quiet)
			{
				# ex: \ShareName\Directory Name\FileName.exe
				$RemainingPath = "\" + [string]::Join("\", $PathSplit, 1, $PathSplit.Length - 1)

				# TODO: This path validation may be too restrictive
				if ($RemainingPath -notmatch '(\\[\w\-_\.\s]+)+\$?$')
				{
					Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
						-Message "The UNC path syntax verification failed for '$UNC'"
					return $false
				}

				return $true
			}

			return $false
		}
	}
}

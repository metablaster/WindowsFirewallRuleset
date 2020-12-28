
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
Verify UNC path is valid

.DESCRIPTION
Test if UNC (Universal Naming Convention) path is valid

.PARAMETER Name
Universal Naming Convention path

.PARAMETER Quiet
if specified errors are not shown, only true or false is returned.

.EXAMPLE
PS> Test-UNC \\SERVER\Share

True

.EXAMPLE
PS> Test-UNC \\SERVER

False

.EXAMPLE
PS> Test-UNC \\SERVER-01\Share\Directory DIR\file.exe

True

.EXAMPLE
PS> Test-UNC \SERVER-01\Share\Directory DIR

False

.INPUTS
[string]

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
	[OutputType([bool])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md")]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]] $Name,

		[Parameter()]
		[switch] $Quiet
	)

	begin
	{
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
		Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

		foreach ($UNC in $Name)
		{
			if ($UNC.Length -gt 260)
			{
				# The maximum length for a path is 260 characters.
				# NOTE: Windows 10 version 1607 and later versions of Windows require changing a registry
				# key or using the Group Policy to remove the limit.
				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "The maximum length for UNC path is 260 characters"
				return $false
			}

			if ($UNC -match "^\\\\\.\\")
			{
				# The "\\.\" prefix will access the Win32 device namespace instead of the Win32 file namespace.
				Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
					-Message "Specified UNC path bellongs to Win32 device namespace: $UNC"

				return $false
			}

			# TODO: This regex needs to be verified, ex. space and dot might not need to be present
			# "^\\\\[a-zA-Z0-9\.\-_]{1,}(\\[a-zA-Z0-9\-_\s\.]{1,}){1,}[\$]{0,1}"
			# [regex] $Regex = "^\\\\[A-Z0-9\-]+(\\[a-zA-Z0-9\-_\s\.]+)+[\$]?"
			if ($UNC -notmatch "^\\\\[\w\-_]+(\\[\w\-_]+)+[\$]?")
			{
				switch ($ErrorLevel)
				{
					0
					{
						Write-Error -Category SyntaxError -TargetObject $UNC -ErrorAction $WriteError `
							-Message "UNC path syntax verification failed for: $UNC"
					}
					default {}
				}

				return $false
			}

			return $true
		}
	}
}

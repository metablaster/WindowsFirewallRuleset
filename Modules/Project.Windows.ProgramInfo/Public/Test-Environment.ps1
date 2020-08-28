
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
Test if path is valid for firewall rule
.DESCRIPTION
Same as Test-Path but expands system environment variables, and checks if path is compatible
for firewall rules
.PARAMETER FilePath
Path to folder, Allows null or empty since input may come from other commandlets which can return empty or null
.EXAMPLE
Test-Environment %SystemDrive%
.INPUTS
None. You cannot pipe objects to Test-Environment
.OUTPUTS
[bool] true if path exists, false otherwise
.NOTES
None.
#>
function Test-Environment
{
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $FilePath = $null
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if path is valid for firewall rule"

	if ([string]::IsNullOrEmpty($FilePath))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Returning false, file path is null or empty"
		return $false
	}

	if ([array]::Find($UserProfileEnvironment, [System.Predicate[string]] { $FilePath -like "$($args[0])*" }))
	{
		Write-Warning -Message "Rules with environment variable paths that lead to user profile are not valid"
		Write-Information -Tags "Project" -MessageData "INFO: Bad path detected is: $FilePath"
		return $false
	}

	return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)) -PathType Container)
}

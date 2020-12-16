
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
Check if file such as an *.exe exists

.DESCRIPTION
In addition to Test-Path of file, message and stack trace is shown and
warning message if file not found

.PARAMETER FilePath
path to file

.EXAMPLE
PS> Test-File "C:\Users\USERNAME\AppData\Local\Google\Chrome\Application\chrome.exe"

.INPUTS
None. You cannot pipe objects to Test-File

.OUTPUTS
None. Test-File does not generate any output

.NOTES
TODO: We should attempt to fix the path if invalid here!
TODO: We should return true or false and conditionally load rule
TODO: This should probably be renamed to Test-Executable to make it less likely part of utility module
#>
function Test-File
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-File.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[string] $FilePath
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking: $ExpandedPath"

	# NOTE: or Test-Path -PathType Leaf ?
	if (!([System.IO.File]::Exists($ExpandedPath)))
	{
		# NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
		$Script = (Get-PSCallStack)[1].Command
		$SearchPath = Split-Path -Path $ExpandedPath -Parent
		$Executable = Split-Path -Path $ExpandedPath -Leaf

		Write-Warning -Message "Executable '$Executable' was not found, rules for '$Executable' won't have any effect"

		Write-Information -Tags "User" -MessageData "INFO: Searched path was: $SearchPath"
		Write-Information -Tags "User" -MessageData "INFO: To fix this problem find '$Executable', adjust the path in $Script and re-run the script"
	}
}

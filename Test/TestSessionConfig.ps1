
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Unit test to test out session configuration file

.DESCRIPTION
Test if a session configuration file contains valid keys and the values are of the correct type.
For enumerated values, the cmdlet verifies that the specified values are valid.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\TestSessionConfig.ps1

.INPUTS
None. You cannot pipe objects to TestSessionConfig.ps1

.OUTPUTS
None. TestSessionConfig.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

$ConfigFile = Get-ChildItem -Recurse -Path "$ProjectRoot\Config" -Filter *.pssc

foreach ($File in $ConfigFile)
{
	Write-Information -Tags "Project" -MessageData "INFO: Testing $File"
	if (!(Test-PSSessionConfigurationFile -Path $File.FullName))
	{
		Write-Error -Category SyntaxError -TargetObject $File `
			-Message "Session configuration file is not valid: $($File.FullName)"
	}
}

Update-Log
Exit-Test

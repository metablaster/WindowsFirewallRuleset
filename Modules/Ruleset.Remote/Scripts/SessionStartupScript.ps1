
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022-2024 metablaster zebal@protonmail.ch

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
Session startup script

.DESCRIPTION
Script runs in the new session that uses the session configuration.
You can use the script to additionally configure the session.
If the script generates an error, even a non-terminating error, the session is not created and the New-PSSession command fails.

.EXAMPLE
PS> .\SessionStartupScript.ps1

.INPUTS
None. You cannot pipe objects to SessionStartupScript.ps1

.OUTPUTS
None. SessionStartupScript.ps1 does not generate any output

.NOTES
This script is referened in Enable-WinRMServer
#>


# Load required modules in session
$ModulesDir = Resolve-Path -Path "$PSScriptRoot\..\.." | Select-Object -ExpandProperty Path

if ($PSVersionTable.PSEdition -eq "Core")
{
	Import-Module -Name "$ModulesDir\Ruleset.Compatibility"

	if ($PSVersionTable.PSVersion -ge "7.1")
	{
		Write-Verbose -Message "[SessionStartupScript.ps1] Importing 'Appx' module for compatibility session"
		# NOTE: New-PSSession for compatibility module is first time executed here and for client
		# in AppxModule.ps in ComputerInfo module
		Import-WinModule -Name Appx -ErrorAction Stop
	}
}

$ModulesToImport = @(
	"$ModulesDir\Ruleset.ComputerInfo"
	"$ModulesDir\Ruleset.Logging"
	"$ModulesDir\Ruleset.ProgramInfo"
	"$ModulesDir\Ruleset.UserInfo"
	"$ModulesDir\Ruleset.Utility"
)

Import-Module -Name $ModulesToImport

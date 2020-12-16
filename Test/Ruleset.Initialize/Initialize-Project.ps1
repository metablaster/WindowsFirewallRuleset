
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
Unit test for Initialize-Project

.DESCRIPTION
Unit test for Initialize-Project

.EXAMPLE
PS> .\Initialize-Project.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Project.ps1

.OUTPUTS
None. Initialize-Project.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe)) { exit }
#endregion

Enter-Test

if ($Force -or $PSCmdlet.ShouldContinue("Modify registry ownership", "Accept dangerous unit test"))
{
	if (!($ProjectCheck -and $ModulesCheck -and $ServicesCheck))
	{
		Write-Error -Category NotEnabled -TargetObject $ThisScript `
			-Message "This unit test requires ProjectCheck, ModulesCheck and ServicesCheck variables to be set"
		return
	}

	Start-Test "Initialize-Project -Abort"
	Initialize-Project

	Start-Test "Initialize-Project -SkipModules -SkipServices"
	Initialize-Project

	Start-Test "Initialize-Project -SkipModules"
	Initialize-Project

	Start-Test "Initialize-Project -SkipServices"
	$Result = Initialize-Project
	$Result

	Test-Output $Result -Command Initialize-Project
}

Update-Log
Exit-Test

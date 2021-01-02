
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
Unit test for Remove-FirewallRules

.DESCRIPTION
Unit test for Remove-FirewallRules

.EXAMPLE
PS> .\Remove-FirewallRules.ps1

.INPUTS
None. You cannot pipe objects to Remove-FirewallRules.ps1

.OUTPUTS
None. Remove-FirewallRules.ps1 does not generate any output

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

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe)) { exit }
#endregion

Enter-Test

if ($Force -or $PSCmdlet.ShouldContinue("Export firewall rules", "Accept slow and experimental unit test"))
{
	$Exports = "$ProjectRoot\Exports"

	# TODO: need to test failure cases, see also module todo's for more info

	Start-Test "Remove-FirewallRules"
	$Result = Remove-FirewallRules -Folder $Exports -FileName "GroupExport"
	$Result

	Start-Test "Remove-FirewallRules"
	Remove-FirewallRules -Folder $Exports -FileName "$Exports\NamedExport1.csv"

	Start-Test "Remove-FirewallRules -JSON"
	Remove-FirewallRules -JSON -Folder $Exports -FileName "$Exports\NamedExport2.json"

	Test-Output $Result -Command Remove-FirewallRules
}

Update-Log
Exit-Test

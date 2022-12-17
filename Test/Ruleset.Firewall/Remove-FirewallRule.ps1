
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Unit test for Remove-FirewallRule

.DESCRIPTION
Test correctness of Remove-FirewallRule function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Remove-FirewallRule.ps1

.INPUTS
None. You cannot pipe objects to Remove-FirewallRule.ps1

.OUTPUTS
None. Remove-FirewallRule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Remove-FirewallRule"

if ($Force -or $PSCmdlet.ShouldContinue("Remove firewall rules according to file", "Accept slow and dangerous unit test"))
{
	$Exports = "$ProjectRoot\Exports"

	# TODO: need to test failure cases, see also module todo's for more info
	if ($false)
	{
		Start-Test "custom test"
		Remove-FirewallRule -Path $Exports -FileName "InboundGPO.csv" -Confirm:$false
		Remove-FirewallRule -Path $Exports -FileName "OutboundGPO.csv" -Confirm:$false
	}
	else
	{
		Start-Test "default"
		$Result = Remove-FirewallRule -Path $Exports -FileName "RegGroupExport"
		$Result

		Start-Test "csv extension"
		Remove-FirewallRule -Path $Exports -FileName "RegNamedExport1.csv"

		Start-Test "-JSON"
		Remove-FirewallRule -JSON -Path $Exports -FileName "RegNamedExport2.json"

		Start-Test "csv extension"
		Remove-FirewallRule -Path $Exports -FileName "RegStoreAppExport.csv"

		Test-Output $Result -Command Remove-FirewallRule
	}
}

Update-Log
Exit-Test

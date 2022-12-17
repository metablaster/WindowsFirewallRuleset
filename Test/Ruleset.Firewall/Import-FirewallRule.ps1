
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
Unit test for Import-FirewallRule

.DESCRIPTION
Test correctness of Import-FirewallRule function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Import-FirewallRule.ps1

.INPUTS
None. You cannot pipe objects to Import-FirewallRule.ps1

.OUTPUTS
None. Import-FirewallRule.ps1 does not generate any output

.NOTES
TODO: Not possible to pass script parameters to debugger
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Registry,

	[Parameter()]
	[switch] $Default,

	[Parameter()]
	[switch] $StoreApp,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Import-FirewallRule"

if ($Force -or $PSCmdlet.ShouldContinue("Import firewall rules", "Accept slow or dangerous unit test"))
{
	$Exports = "$ProjectRoot\Exports"

	# TODO: Need to test failure cases, see also module todo's for more info
	if ($false)
	{
		Start-Test "-Outbound -Disabled -Allow"
		Import-FirewallRule -Path $Exports -FileName "RegOutboundExport" -Overwrite

		# Start-Test "-Inbound -Enabled -Block -JSON"
		# Import-FirewallRule -Path $Exports -JSON -FileName "RegInboundExport"
	}
	else
	{

		if ($Registry)
		{
			Start-Test "-FileName RegGroupExport.csv"
			Import-FirewallRule -Path $Exports -FileName "RegGroupExport.csv"

			Start-Test "-FileName RegNamedExport1.csv"
			Import-FirewallRule -Path $Exports -FileName "RegNamedExport1.csv" -Overwrite

			Start-Test "-JSON -FileName RegNamedExport2.json"
			$Result = Import-FirewallRule -JSON -Path $Exports -FileName "RegNamedExport2.json" -Overwrite
			$Result

			if ($StoreApp)
			{
				Start-Test "-FileName RegStoreAppExport.csv"
				Import-FirewallRule -Path $Exports -FileName "RegStoreAppExport.csv" -Overwrite
			}

			Test-Output $Result -Command Import-FirewallRule
		}

		if ($Default)
		{
			Start-Test "-FileName GroupExport.csv"
			Import-FirewallRule -Path $Exports -FileName "GroupExport.csv"

			Start-Test "-FileName NamedExport1.csv"
			Import-FirewallRule -Path $Exports -FileName "NamedExport1.csv" -Overwrite

			Start-Test "-JSON -FileName NamedExport2.json"
			$Result = Import-FirewallRule -JSON -Path $Exports -FileName "NamedExport2.json" -Overwrite
			$Result

			if ($StoreApp)
			{
				Start-Test "-FileName StoreAppExport.csv"
				Import-FirewallRule -Path $Exports -FileName "StoreAppExport.csv" -Overwrite
			}

			Test-Output $Result -Command Import-FirewallRule
		}
	}
}

Update-Log
Exit-Test

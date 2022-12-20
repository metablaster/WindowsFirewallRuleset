
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
Unit test for Export-FirewallRule

.DESCRIPTION
Test correctness of Export-FirewallRule function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Export-FirewallRule.ps1

.INPUTS
None. You cannot pipe objects to Export-FirewallRule.ps1

.OUTPUTS
None. Export-FirewallRule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Export-FirewallRule"

if ($Force -or $PSCmdlet.ShouldContinue("Export firewall rules", "Accept slow unit test"))
{
	$Exports = "$ProjectRoot\Exports"

	# TODO: need to test failure cases, see also module todo's for more info

	Start-Test "-DisplayGroup '' -Outbound"
	Export-FirewallRule -DisplayGroup "" -Outbound -Path $Exports -FileName "GroupExport"

	Start-Test "-DisplayGroup 'Broadcast' -Outbound"
	Export-FirewallRule -DisplayGroup "Broadcast" -Outbound -Path $Exports -FileName "GroupExport"

	Start-Test "-DisplayName 'Domain Name System'"
	Export-FirewallRule -DisplayName "Domain Name System" -Path $Exports -FileName "NamedExport1"

	Start-Test "-DisplayGroup 'Microsoft - Edge Chromium' -Outbound -Append"
	Export-FirewallRule -DisplayGroup "Microsoft - Edge Chromium" -Outbound -Path $Exports -Append -FileName "NamedExport1"

	Start-Test "-DisplayName 'Internet Group Management Protocol' -JSON"
	Export-FirewallRule -DisplayName "Internet Group Management Protocol" -Path $Exports -JSON -FileName "NamedExport2"

	Start-Test "-DisplayGroup 'Microsoft - One Drive' -Outbound -JSON -Append"
	Export-FirewallRule -DisplayGroup "Microsoft - One Drive" -Outbound -Path $Exports -JSON -Append -FileName "NamedExport2"

	# Start-Test "-Outbound -Disabled -Allow"
	# Export-FirewallRule -Outbound -Disabled -Allow -Path $Exports -FileName "OutboundExport"

	# Start-Test "-Inbound -Enabled -Block -JSON"
	# Export-FirewallRule -Inbound -Enabled -Block -Path $Exports -JSON -FileName "InboundExport"

	Start-Test "-DisplayName 'Microsoft.BingWeather' -Outbound"
	$Result = Export-FirewallRule -DisplayName "Microsoft.BingWeather" -Outbound -Path $Exports -FileName "StoreAppExport"
	$Result

	Test-Output $Result -Command Export-FirewallRule
}

Update-Log
Exit-Test

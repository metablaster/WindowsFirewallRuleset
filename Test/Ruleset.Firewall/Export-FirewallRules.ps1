
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
Unit test for Export-FirewallRules

.DESCRIPTION
Unit test for Export-FirewallRules

.EXAMPLE
PS> .\Export-FirewallRules.ps1

.INPUTS
None. You cannot pipe objects to Export-FirewallRules.ps1

.OUTPUTS
None. Export-FirewallRules.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

Enter-Test

$Exports = "$ProjectRoot\Exports"

# TODO: need to test failure cases, see also module todo's for more info

if ($Force -or $PSCmdlet.ShouldContinue("Export firewall rules", "Accept slow unit test"))
{
	Start-Test "Export-FirewallRules -DisplayGroup"
	Export-FirewallRules -DisplayGroup "" -Outbound -Folder $Exports -FileName "GroupExport" @Logs # -DisplayName "Gwent"

	Start-Test "Export-FirewallRules -DisplayGroup"
	Export-FirewallRules -DisplayGroup "Broadcast" -Outbound -Folder $Exports -FileName "GroupExport" @Logs

	Start-Test "Export-FirewallRules -DisplayName NONEXISTENT"
	Export-FirewallRules -DisplayName "NONEXISTENT" -Folder $Exports -FileName "NamedExport1" @Logs

	Start-Test "Export-FirewallRules -DisplayName"
	Export-FirewallRules -DisplayName "Domain Name System" -Folder $Exports -FileName "NamedExport1" @Logs

	Start-Test "Export-FirewallRules -DisplayName -JSON"
	Export-FirewallRules -DisplayName "Domain Name System" -Folder $Exports -JSON -Append -FileName "NamedExport2" @Logs

	Start-Test "Export-FirewallRules -Outbound -Disabled -Allow"
	Export-FirewallRules -Outbound -Disabled -Allow -Folder $Exports -FileName "OutboundExport" @Logs

	Start-Test "Export-FirewallRules -Inbound -Enabled -Block -JSON"
	Export-FirewallRules -Inbound -Enabled -Block -Folder $Exports -JSON -FileName "InboundExport" @Logs

	Start-Test "Export-FirewallRules -DisplayGroup"
	$Result = Export-FirewallRules -DisplayName "Microsoft.BingWeather" -Outbound -Folder $Exports -FileName "StoreAppExport" @Logs # -DisplayName "Gwent"
	$Result

	Test-Output $Result -Command Export-FirewallRules @Logs
}

Update-Log
Exit-Test

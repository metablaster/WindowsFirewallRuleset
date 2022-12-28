
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Unit test for Export-RegistryRule

.DESCRIPTION
Test correctness of Export-RegistryRule function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Export-RegistryRule.ps1

.INPUTS
None. You cannot pipe objects to Export-RegistryRule.ps1

.OUTPUTS
None. Export-RegistryRule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Export-RegistryRule"

$Exports = "$ProjectRoot\Exports"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "Remote reg export -Outbound -Disabled -Allow"
	Export-RegistryRule -Outbound -Disabled -Allow -Path $Exports -FileName "RemoteRegOutboundExport" -Domain $Domain
}
else
{
	# TODO: need to test failure cases, see also module todo's for more info
	if ($false)
	{
		Start-Test "-Outbound -Disabled -Allow"
		Export-RegistryRule -Outbound -Disabled -Allow -Path $Exports -FileName "RegOutboundExport"

		# Start-Test "-Inbound -Enabled -Block -JSON"
		# Export-RegistryRule -Inbound -Enabled -Block -Path $Exports -JSON -FileName "RegInboundExport"
	}
	else
	{
		if ($false)
		{
			Start-Test "Persistent store"
			Export-RegistryRule -DisplayGroup "" -Outbound -Path $Exports -FileName "RegNoGroupExport"
		}
		else
		{
			Start-Test "-DisplayGroup '' -Outbound"
			Export-RegistryRule -DisplayGroup "" -Outbound -Path $Exports -FileName "RegGroupExport"

			Start-Test "-DisplayGroup 'Broadcast' -Outbound"
			Export-RegistryRule -DisplayGroup "Broadcast" -Outbound -Path $Exports -FileName "RegGroupExport"

			Start-Test "-DisplayName 'Domain Name System'"
			Export-RegistryRule -DisplayName "Domain Name System" -Path $Exports -FileName "RegNamedExport1"

			Start-Test "-DisplayGroup 'Microsoft - Edge Chromium' -Outbound -Append"
			Export-RegistryRule -DisplayGroup "Microsoft - Edge Chromium" -Outbound -Path $Exports -Append -FileName "RegNamedExport1"

			Start-Test "-DisplayName 'Internet Group Management Protocol' -JSON"
			Export-RegistryRule -DisplayName "Internet Group Management Protocol" -Path $Exports -JSON -FileName "RegNamedExport2"

			Start-Test "-DisplayGroup 'Microsoft - One Drive' -Outbound -JSON -Append"
			Export-RegistryRule -DisplayGroup "Microsoft - One Drive" -Outbound -Path $Exports -JSON -Append -FileName "RegNamedExport2"

			Start-Test "-DisplayName 'Microsoft.BingWeather' -Outbound"
			$Result = Export-RegistryRule -DisplayName "Microsoft.Bingweather" -Outbound -Path $Exports -FileName "RegStoreAppExport"
			$Result

			Test-Output $Result -Command Export-RegistryRule
		}
	}
}

Update-Log
Exit-Test

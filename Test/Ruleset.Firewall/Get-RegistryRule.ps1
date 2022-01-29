
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
Unit test for Get-RegistryRule

.DESCRIPTION
Test correctness of Get-RegistryRule function

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Get-RegistryRule.ps1

.INPUTS
None. You cannot pipe objects to Get-RegistryRule.ps1

.OUTPUTS
None. Get-RegistryRule.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Get-RegistryRule"

$Group = "Test registry rule"

Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction Ignore
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction Ignore

if ($false)
{
	New-NetFirewallRule -DisplayName "Test" -Direction Outbound `
		-PolicyStore $PolicyStore -Group $Group -Enabled False `
		-IcmpType 4 -Protocol ICMPv4 -Platform "10.0" |
	Format-RuleOutput

	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"

	Start-Test "Custom test"
	Get-RegistryRule -Direction Outbound -DisplayName "Test"
}
else
{
	# Start-Test "Persistent store"
	# Get-RegistryRule -Direction Outbound -DisplayName "Xbox Game Bar" -Local

	Start-Test "Default test 1"
	Get-RegistryRule -Direction Outbound -DisplayName "Edge-Chromium HTTPS"

	Start-Test "Default test 2"
	Get-RegistryRule -Direction Outbound -DisplayName "Steam Matchmaking and HLTV"

	Start-Test "Default test 3"
	$Result = Get-RegistryRule -Direction Outbound -DisplayGroup "Broadcast"
	$Result

	Test-Output $Result -Command Get-RegistryRule
}

Update-Log
Exit-Test

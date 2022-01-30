
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

<#PSScriptInfo

.VERSION 0.12.0

.GUID d6b158fc-ac3c-4979-a3d6-a7a656db11ec

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Select hidden properties for specified firewall rule group

.DESCRIPTION
Select hidden firewall rule properties from target policy store, for given group name and traffic
direction.
For example rules of same group from different stores might not work the same way and you want to
ensure hidden properties are the same on both stores.

.PARAMETER DisplayGroup
Rule display group

.PARAMETER Direction
Traffic direction

.PARAMETER PolicyStore
Policy store from which to retrieve rules.
PersistentStore means from control panel firewall
Computer name means from GPO store.

.EXAMPLE
PS> .\Select-HiddenProperty.ps1 "Network Discovery"

.EXAMPLE
PS> .\Select-HiddenProperty.ps1 "Network Discovery" -PolicyStore ([System.Environment]::MachineName)

.INPUTS
None. You cannot pipe objects to Select-HiddenProperty.ps1

.OUTPUTS
[Selected.Microsoft.Management.Infrastructure.CimInstance]

.NOTES
TODO: This should probably be part of Ruleset.Firewall module
TODO: OutputType attribute for [Selected.Microsoft.Management.Infrastructure.CimInstance]

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false)]
param (
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $DisplayGroup,

	[Parameter()]
	[ValidateSet("Inbound", "Outbound")]
	[string] $Direction = "Outbound",

	[Parameter()]
	[string] $PolicyStore = [System.Environment]::MachineName
)

New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)
$PredefinedRules = Get-NetFirewallRule -PolicyStore $PolicyStore -DisplayGroup $DisplayGroup -Direction $Direction
$RuleCount = ($PredefinedRules | Measure-Object).Count

$PredefinedHidden = $PredefinedRules | Select-Object -Property DisplayName, StatusCode, Platforms, `
	PolicyDecisionStrategy, ConditionListType, ExecutionStrategy, SequencedActions, Profiles, `
	LocalOnlyMapping, LooseSourceMapping, EnforcementStatus

for ($Index = 0; $Index -lt $RuleCount; ++$Index)
{
	Write-Information -Tags $ThisScript -MessageData "INFO: Assembling rule output for '$($PredefinedHidden[$Index].DisplayName)'" -INFA "Continue"

	# NOTE: We can't apply filter on all rules at once, because the result won't be sorted the same way
	$Program = (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $PredefinedRules[$Index]).Program
	$Service = (Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $PredefinedRules[$Index]).ServiceName

	$PredefinedHidden[$Index] | Add-Member -MemberType NoteProperty -Name "Program" -Value $Program
	$PredefinedHidden[$Index] | Add-Member -MemberType NoteProperty -Name "Service" -Value $Service
}

Write-Output $PredefinedHidden

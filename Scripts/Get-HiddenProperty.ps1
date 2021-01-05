
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

<#PSScriptInfo

.VERSION 0.9.1

.GUID d6b158fc-ac3c-4979-a3d6-a7a656db11ec

.AUTHOR metablaster zebal@protonmail.com

.COPYRIGHT Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

.TAGS Firewall

.LICENSEURI https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE

.PROJECTURI https://github.com/metablaster/WindowsFirewallRuleset

.RELEASENOTES
https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/CHANGELOG.md
#>

<#
.SYNOPSIS
Get a list of hidden properties for specified firewall rule group

.DESCRIPTION
Get a list of firewall rule hidden properties from target policy store, for all rules of given
group name and traffic direction.
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
PS> .\Get-HiddenProperty.ps1 "Network Discovery"

.EXAMPLE
PS> .\Get-HiddenProperty.ps1 "Network Discovery" -PolicyStore ([System.Environment]::MachineName)

.INPUTS
None. You cannot pipe objects to Get-HiddenProperty.ps1

.OUTPUTS
None. Get-HiddenProperty.ps1 does not generate any output

.NOTES
TODO: This should probably be part of Ruleset.Firewall module
TODO: OutputType attribute for [Selected.Microsoft.Management.Infrastructure.CimInstance]
#>

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

#region Initialization
#Requires -Version 5.1
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
$Accept = "Generate a list of firewall rules with hidden properties"
$Deny = "Abort operation, no list of firewall rules is made"
Update-Context $ScriptContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

$PredefinedRules = Get-NetFirewallRule -PolicyStore $PolicyStore -DisplayGroup $DisplayGroup -Direction $Direction
$RuleCount = ($PredefinedRules | Measure-Object).Count

$PredefinedHidden = $PredefinedRules | Select-Object -Property DisplayName, StatusCode, Platforms, `
	PolicyDecisionStrategy, ConditionListType, ExecutionStrategy, SequencedActions, Profiles, `
	LocalOnlyMapping, LooseSourceMapping, EnforcementStatus

for ($Index = 0; $Index -lt $RuleCount; ++$Index)
{
	# NOTE: We can't apply filter on all rules at once, because the result won't be sorted the same way
	$Program = (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $PredefinedRules[$Index]).Program
	$Service = (Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $PredefinedRules[$Index]).ServiceName

	Write-Information -Tags "User" -MessageData "INFO: Assembling rule output for '$($PredefinedHidden[$Index].DisplayName)'"
	$PredefinedHidden[$Index] | Add-Member -MemberType NoteProperty -Name "Program" -Value $Program
	$PredefinedHidden[$Index] | Add-Member -MemberType NoteProperty -Name "Service" -Value $Service
}

$PredefinedHidden

Update-Log

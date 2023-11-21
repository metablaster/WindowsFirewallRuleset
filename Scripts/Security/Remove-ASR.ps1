
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2023 metablaster zebal@protonmail.ch

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

.VERSION 0.15.1

.GUID a25eb685-36f4-4bb4-b825-61cf2e737a46

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Remove all or specified ASR rules

.DESCRIPTION
Use Remove-ASR.ps1 to remove all all or specified attack surface reduction (ASR) rules

.PARAMETER Domain
Computer name which is to be queried for ASR rules

.PARAMETER Name
One or more rule GUID's which to remove
If not specified all rules are removed.

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Remove-ASR

.EXAMPLE
PS> Remove-ASR -Domain Server01

.INPUTS
None. You cannot pipe objects to Remove-ASR.ps1

.OUTPUTS
None. Remove-ASR.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md

.LINK
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = "None")]
[OutputType([void])]
param (
	[Alias("ComputerName", "CN")]
	[Parameter()]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter(ValueFromPipeline = $true)]
	[string[]] $Name,

	[Parameter()]
	[switch] $Force
)

begin
{
	#region Initialization
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
	Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	Initialize-Project
	$Domain = Format-ComputerName $Domain

	# User prompt
	$Accept = "Accpet removing ASR rules on '$Domain' computer"
	$Deny = "Abort operation, no ASR rules on '$Domain' computer will be removed"
	if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
	#endregion

	$RuleCount = (Get-MpPreference -CimSession $CimServer |
		Select-Object AttackSurfaceReductionRules_Ids -ExpandProperty AttackSurfaceReductionRules_Ids |
		Measure-Object).Count

	if ($RuleCount -eq 0)
	{
		Write-Information -MessageData "INFO: No ASR rules exist on '$Domain' computer"
	}
	elseif ($null -eq $Name)
	{
		$Name = @(
			"56a863a9-875e-4185-98a7-b882c64b5ce5"
			"7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c"
			"d4f940ab-401b-4efc-aadc-ad5f3c50688a"
			"9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"
			"be9ba2d9-53ea-4cdc-84e5-9b1eeee46550"
			"01443614-cd74-433a-b99e-2ecdc07bfc25"
			"5beb7efe-fd9a-4556-801d-275e5ffc04cc"
			"d3e037e1-3eb8-44c8-a917-57927947596d"
			"3b576869-a4ec-4529-8536-b80a7769e899"
			"75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84"
			"26190899-1602-49e8-8b27-eb1d0a1ce869"
			"e6db77e5-3df2-4cf1-b95a-636979351e5b"
			"b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4"
			"92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b"
			"c1db55ab-c21a-4637-bb3f-a12568109d35"
			"d1e49aac-8f56-4280-b9ba-993a6d77406c"
		)

		Write-Information -MessageData "INFO: Removing all ASR rules on '$Domain' computer"
	}
	else
	{
		Write-Information -MessageData "INFO: Removing specified rules on '$Domain' computer"
	}
}

process
{
	if ($RuleCount -ne 0)
	{
		foreach ($Entry in $Name)
		{
			Remove-MpPreference -AttackSurfaceReductionRules_Ids $Entry
		}
	}
}

end
{
	Disconnect-Computer -Domain $PolicyStore
	Update-Log
}

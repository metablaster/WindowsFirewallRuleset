
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

<#PSScriptInfo

.VERSION 0.13.0

.GUID a25eb685-36f4-4bb4-b825-61cf2e737a46

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize
#>

<#
.SYNOPSIS
Show ASR rules

.DESCRIPTION
Use Show-ASR.ps1 to show current configuration of attack surface reduction (ASR) rules

.PARAMETER Domain
Computer name which is to be queried for ASR rules

.EXAMPLE
PS> Show-ASR

.EXAMPLE
PS> Show-ASR -Domain Server01

.INPUTS
None. You cannot pipe objects to Show-ASR.ps1

.OUTPUTS
None. Show-ASR.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop

[CmdletBinding()]
[OutputType([void])]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

# Replace localhost and dot with NETBIOS computer name
if (($Domain -eq "localhost") -or ($Domain -eq "."))
{
	$Domain = [System.Environment]::MachineName
}
#endregion

$InformationPreference = "Continue"

[scriptblock] $Convert = {
	param([string] $Value)

	switch ($Value)
	{
		"56a863a9-875e-4185-98a7-b882c64b5ce5" { "Block abuse of exploited vulnerable signed drivers"; break }
		"7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" { "Block Adobe Reader from creating child processes"; break }
		"d4f940ab-401b-4efc-aadc-ad5f3c50688a" { "Block all Office applications from creating child processes"; break }
		"9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" { "Block credential stealing from the Windows local security authority subsystem"; break }
		"be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" { "Block executable content from email client and webmail"; break }
		"01443614-cd74-433a-b99e-2ecdc07bfc25" { "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"; break }
		"5beb7efe-fd9a-4556-801d-275e5ffc04cc" { "Block execution of potentially obfuscated scripts"; break }
		"d3e037e1-3eb8-44c8-a917-57927947596d" { "Block JavaScript or VBScript from launching downloaded executable content"; break }
		"3b576869-a4ec-4529-8536-b80a7769e899" { "Block Office applications from creating executable content"; break }
		"75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84" { "Block Office applications from injecting code into other processes"; break }
		"26190899-1602-49e8-8b27-eb1d0a1ce869" { "Block Office communication application from creating child processes"; break }
		"e6db77e5-3df2-4cf1-b95a-636979351e5b" { "Block persistence through WMI event subscription"; break }
		"b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4" { "Block untrusted and unsigned processes that run from USB"; break }
		"92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b" { "Block Win32 API calls from Office macros"; break }
		"c1db55ab-c21a-4637-bb3f-a12568109d35" { "Use advanced protection against ransomware"; break }
		"d1e49aac-8f56-4280-b9ba-993a6d77406c" { "Block process creations originating from PSExec and WMI commands" ; break }
	}
}

$MpPreference = Get-MpPreference -CimSession $CimServer |
Select-Object AttackSurfaceReductionRules_Ids, AttackSurfaceReductionRules_Actions

foreach ($Entry in $MpPreference)
{
	for ($Index = 0; $Index -lt $Entry.AttackSurfaceReductionRules_Ids.Length; ++$Index)
	{
		Write-Information -MessageData "$(& $Convert $Entry.AttackSurfaceReductionRules_Ids[$Index])"

		if ($Entry.AttackSurfaceReductionRules_Actions[$Index] -eq 1)
		{
			$Enabled = "Enabled"
		}
		else
		{
			$Enabled = "Disabled"
		}

		Write-Information -MessageData $Enabled
	}
}

Update-Log

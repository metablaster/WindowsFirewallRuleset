
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

.VERSION 0.15.0

.GUID 303c4ba1-9f8e-468b-b78d-637182d7e98d

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Deploy attack surface reduction rules

.DESCRIPTION
Use Deploy-ASR.ps1 to deploy ASR rules.
Use attack surface reduction rules to prevent malware infection.
Your organization's attack surface includes all the places where an attacker could compromise your
organization's devices or networks.
Reducing your attack surface means protecting your organization's devices and network,
which leaves attackers with fewer ways to perform attacks.

.PARAMETER Domain
Computer name onto which do deploy ASR rules

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Deploy-ASR

.EXAMPLE
PS> Deploy-ASR -Domain Server01

.INPUTS
None. You cannot pipe objects to Deploy-ASR.ps1

.OUTPUTS
None. Deploy-ASR.ps1 does not generate any output

.NOTES
To exclude folders or files from ASR use:
Add-MpPreference -AttackSurfaceReductionOnlyExclusions $ExcludePath

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md

.LINK
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

Initialize-Project
$Domain = Format-ComputerName $Domain

# User prompt
$Accept = "Accpet deploying ASR rules to '$Domain' computer"
$Deny = "Abort operation, no ASR rules to '$Domain' computer will be deployed"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if ($PSCmdlet.ShouldProcess("Microsoft Defender Antivirus", "Deploy attack surface reduction rules to '$Domain' computer"))
{
	#
	# Attack Surface Reduction
	# HACK: Set-PolicyFileEntry does not work for ASR, neither registry nor GPO isn't updated
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Microsoft Defender Antivirus\Microsoft Defender Exploit Guard\Attack Surface Reduction
	# Registry: "Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR -> ExploitGuard_ASR_Rules"
	# Registry: "Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules -> Rule Name"
	#

	$Rules = @(
		# Block abuse of exploited vulnerable signed drivers
		"56a863a9-875e-4185-98a7-b882c64b5ce5"

		# Block Adobe Reader from creating child processes
		"7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c"

		# Block all Office applications from creating child processes
		"d4f940ab-401b-4efc-aadc-ad5f3c50688a"

		# Block credential stealing from the Windows local security authority subsystem
		"9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"

		# Block executable content from email client and webmail
		"be9ba2d9-53ea-4cdc-84e5-9b1eeee46550"

		# Block executable files from running unless they meet a prevalence, age, or trusted list criterion
		"01443614-cd74-433a-b99e-2ecdc07bfc25"

		# Block execution of potentially obfuscated scripts
		"5beb7efe-fd9a-4556-801d-275e5ffc04cc"

		# Block JavaScript or VBScript from launching downloaded executable content
		"d3e037e1-3eb8-44c8-a917-57927947596d"

		# Block Office applications from creating executable content
		"3b576869-a4ec-4529-8536-b80a7769e899"

		# Block Office applications from injecting code into other processes
		"75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84"

		# Block Office communication application from creating child processes
		"26190899-1602-49e8-8b27-eb1d0a1ce869"

		# Block persistence through WMI event subscription
		"e6db77e5-3df2-4cf1-b95a-636979351e5b"

		# Block untrusted and unsigned processes that run from USB
		"b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4"

		# Block Win32 API calls from Office macros
		"92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b"

		# Use advanced protection against ransomware
		"c1db55ab-c21a-4637-bb3f-a12568109d35"

		# Block process creations originating from PSExec and WMI commands
		"d1e49aac-8f56-4280-b9ba-993a6d77406c"
	)

	# Enabled, Disabled or AuditMode
	$Actions = @(
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Enabled "
		"Disabled "
	)

	try
	{
		Set-MpPreference -AttackSurfaceReductionRules_Ids $Rules -CimSession $CimServer `
			-AttackSurfaceReductionRules_Actions $Actions -ErrorAction Stop

		Write-Information -MessageData "INFO: Successfully deployed ASR rules to '$Domain' computer"
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}

Disconnect-Computer -Domain $PolicyStore
Update-Log

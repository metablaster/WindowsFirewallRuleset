
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

.VERSION 0.14.0

.GUID 251176c4-f476-4dda-a55c-7fb06f303a09

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Validate firewall configuration and rules are in desired state

.DESCRIPTION
Confirm-Firewall validates all repository controlled firewall settings are in configured and
set to value specified by repository defaults.
Verification is performed by scanning registry and any discrepancies are reported for review.

.PARAMETER Domain
Computer name on which firewall configuration is to be tested

.EXAMPLE
PS> Confirm-Firewall

.EXAMPLE
PS> Confirm-Firewall -Domain Server01

.INPUTS
None. You cannot pipe objects to Confirm-Firewall.ps1

.OUTPUTS
None. Confirm-Firewall.ps1 does not generate any output

.NOTES
TODO: Need to check for consistency of rules as well

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding()]
[OutputType([void])]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

# User prompt
$Accept = "Verify firewall configuration is in desired state"
$Deny = "Abort operation, check will be performed"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

$HKLM = "Software\Policies\Microsoft\WindowsFirewall"
$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine

try
{
	Write-Verbose -Message "[$ThisScript] Accessing registry on computer: $Domain"
	$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)

	try
	{
		Write-Verbose -Message "[$ThisScript] Opening root key: HKLM:\$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $RegistryRights)

		if (!$RootKey)
		{
			throw [System.Data.ObjectNotFoundException]::new("Following registry key does not exist: HKLM:\$HKLM")
		}
	}
	catch
	{
		Write-Warning -Message "[$ThisScript] Failed to open registry root key: HKLM:\$HKLM"
		continue
	}
}
catch
{
	if ($RemoteKey)
	{
		$RemoteKey.Dispose()
	}

	Write-Error -ErrorRecord $_
	return
}

Write-Information -Tags $ThisScript -MessageData "INFO: Checking firewall profile settings..."
$ProfileSettings = Get-NetFirewallProfile -All -PolicyStore $PolicyStore

foreach ($Profile in $ProfileSettings)
{
	Write-Verbose -Message "[$ThisScript] Opening sub key: $($Profile.Name)"
	$ProfileKey = $RootKey.OpenSubKey("$($Profile.Name)Profile")

	$Value = $ProfileKey.GetValue("EnableFirewall")
	if ($Value -ne 1)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'Enabled' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("AllowLocalPolicyMerge")
	if ($Value -ne 0)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'AllowLocalFirewallRules' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("AllowLocalIPsecPolicyMerge")
	if ($Value -ne 0)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'AllowLocalIPsecRules' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DefaultInboundAction")
	if ($Value -ne 1) # Block
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'DefaultInboundAction' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DefaultOutboundAction")
	if ($Value -ne 1) # Block
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'DefaultOutboundAction' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DisableNotifications")
	if ($Value -ne 0)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'NotifyOnListen' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DisableUnicastResponsesToMulticastBroadcast")
	if ($Profile.Name -eq "Public") { $Setting = 1 }
	else { $Setting = 0 }

	if ($Value -ne $Setting)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'AllowUnicastResponseToMulticast' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DoNotAllowExceptions")
	if ($Value -ne 0)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'AllowInboundRules' is misconfigured"
	}

	$Value = $ProfileKey.GetValue("DisableStealthModeIPsecSecuredPacketExemption")
	if ($Value -ne 1)
	{
		Write-Warning -Message "[$ThisScript] $($Profile.Name) profile 'EnableStealthModeForIPsec' is misconfigured"
	}
}

# TODO: Not handling *AuthorizationList values
Write-Information -Tags $ThisScript -MessageData "INFO: Checking firewall global settings..."

$Value = $RootKey.GetValue("DisableStatefulFTP")
if ($Value -ne 0)
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'EnableStatefulFtp' is misconfigured"
}

$Value = $RootKey.GetValue("DisableStatefulPPTP")
if ($Value -ne 1)
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'EnableStatefulPptp' is misconfigured"
}

$Value = $RootKey.GetValue("IPSecExempt")
if ($Value -ne 0) # None
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'Exemptions' is misconfigured"
}

$Value = $RootKey.GetValue("PresharedKeyEncoding")
if ($Value -ne 1) # UTF8
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'KeyEncoding' is misconfigured"
}

$Value = $RootKey.GetValue("SAIdlTime")
if ($Value -ne 300)
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'MaxSAIdleTimeSeconds' is misconfigured"
}

$Value = $RootKey.GetValue("StrongCRLCheck")
if ($Value -ne 2) # RequireCrlCheck
{
	Write-Warning -Message "[$ThisScript] Firewall setting 'CertValidationLevel' is misconfigured"
}

Disconnect-Computer -Domain $PolicyStore
Update-Log

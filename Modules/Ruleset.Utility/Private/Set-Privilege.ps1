
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2017 Pyprohly
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

<#
.SYNOPSIS
Toggle security privileges for the current PowerShell session.

.DESCRIPTION
Toggle security privileges for the current PowerShell session.
This is needed to gain privileged access to registry ie. to be able to take ownership
or to set registry permissions to keys and values.

.PARAMETER Privilege
Privilege name which to grant or remove

.PARAMETER Disable
If specified, removes privilege instead of adding it

.EXAMPLE
PS> .\Set-Privilege.ps1 -Privilege SeSecurityPrivilege, SeTakeOwnershipPrivilege

.INPUTS
None. You cannot pipe objects to Set-Privilege.ps1

.OUTPUTS
None. Set-Privilege.ps1 does not generate any output

.NOTES
Author: Pyprohly
GUID: 84990677-60ab-4984-9de1-fcfc19f5209d

NOTE: According to "PowerShell Gallery Terms of Use - February 2020":
If third party programs are accessible on the Web Site without license terms,
then any such third party programs without license terms may be used under the terms of the MIT
License attached as Exhibit A

TODO: After runing this script, seems like some variables are removed, See Exit-Text "UnitTest" variable

Following modifications by metablaster, November 2020:
1. Format code according to project best practices
2. Added boilerplate code
3. Make function produce some informational output
4. Added comment based help
December 2020:
5. Rename parameter to standard parameter name

.LINK
https://www.powershellgallery.com/packages/Set-Privilege/1.1.2

.LINK
https://www.powershellgallery.com/policies/Terms

.COMPONENT
Security
Privilege
TokenPrivilege
#>
function Set-Privilege
{
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High")]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet(
			"SeAssignPrimaryTokenPrivilege", "AssignPrimaryToken",
			"SeAuditPrivilege", "Audit",
			"SeBackupPrivilege", "Backup",
			"SeChangeNotifyPrivilege", "ChangeNotify",
			"SeCreateGlobalPrivilege", "CreateGlobal",
			"SeCreatePagefilePrivilege", "CreatePagefile",
			"SeCreatePermanentPrivilege", "CreatePermanent",
			"SeCreateSymbolicLinkPrivilege", "CreateSymbolicLink",
			"SeCreateTokenPrivilege", "CreateToken",
			"SeDebugPrivilege", "Debug",
			"SeEnableDelegationPrivilege", "EnableDelegation",
			"SeImpersonatePrivilege", "Impersonate",
			"SeIncreaseBasePriorityPrivilege", "IncreaseBasePriority",
			"SeIncreaseQuotaPrivilege", "IncreaseQuota",
			"SeIncreaseWorkingSetPrivilege", "IncreaseWorkingSet",
			"SeLoadDriverPrivilege", "LoadDriver",
			"SeLockMemoryPrivilege", "LockMemory",
			"SeMachineAccountPrivilege", "MachineAccount",
			"SeManageVolumePrivilege", "ManageVolume",
			"SeProfileSingleProcessPrivilege", "ProfileSingleProcess",
			"SeRelabelPrivilege", "Relabel",
			"SeRemoteShutdownPrivilege", "RemoteShutdown",
			"SeRestorePrivilege", "Restore",
			"SeSecurityPrivilege", "Security",
			"SeShutdownPrivilege", "Shutdown",
			"SeSyncAgentPrivilege", "SyncAgent",
			"SeSystemEnvironmentPrivilege", "SystemEnvironment",
			"SeSystemProfilePrivilege", "SystemProfile",
			"SeSystemtimePrivilege", "SystemTime",
			"SeTakeOwnershipPrivilege", "TakeOwnership",
			"SeTcbPrivilege", "Tcb", "TrustedComputingBase",
			"SeTimeZonePrivilege", "TimeZone",
			"SeTrustedCredManAccessPrivilege", "TrustedCredManAccess",
			"SeUndockPrivilege", "Undock",
			"SeUnsolicitedInputPrivilege", "UnsolicitedInput"
		)]
		[Alias("PrivilegeName")]
		[string[]] $Privilege,

		[Parameter()]
		[switch] $Disable
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$Signature = '[DllImport("ntdll.dll", EntryPoint = "RtlAdjustPrivilege")]
        public static extern IntPtr SetPrivilege(int Privilege, bool bEnablePrivilege, bool IsThreadPrivilege, out bool PreviousValue);

        [DllImport("advapi32.dll")]
		public static extern bool LookupPrivilegeValue(string host, string name, out long pluid);'
		Add-Type -MemberDefinition $Signature -Namespace AdjPriv -Name Privilege

		[scriptblock] $GetPrivilegeConstant = {
			param ($StringParam)

			if ($StringParam -eq "TrustedComputingBase")
			{
				return "SeTcbPrivilege"
			}
			elseif ($StringParam -match '^Se.*Privilege$')
			{
				return $StringParam
			}
			else
			{
				"Se${StringParam}Privilege"
			}
		}

		[string] $StatusMessage = "Set"

		if ($Disable)
		{
			$StatusMessage = "Unset"
		}
	}
	process
	{
		foreach ($Name in $Privilege)
		{
			if ($PSCmdlet.ShouldProcess("PowerShell process", "$StatusMessage $Name privilege"))
			{
				[long] $PrivID = $null
				# https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupprivilegevaluew
				# If the function succeeds, the function returns nonzero.
				if ([AdjPriv.Privilege]::LookupPrivilegeValue($null, (& $GetPrivilegeConstant $Name), [ref] $PrivID))
				{
					[bool] $PreviousValue = $null

					# https://docs.microsoft.com/en-us/windows/win32/secauthz/enabling-and-disabling-privileges-in-c--
					# https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-adjusttokenprivileges
					if (![bool][long][AdjPriv.Privilege]::SetPrivilege($PrivID, !$Disable, $false, [ref] $PreviousValue))
					{
						Write-Information -Tags "User" -MessageData "INFO: Previous value for $Name was: $PreviousValue"
						Write-Information -Tags "User" -MessageData "INFO: Privilege $Name successfully $($StatusMessage.ToLower())"
					}
					else
					{
						Write-Information -Tags "User" -MessageData "INFO: Previous value: $PreviousValue"
						Write-Error -Category NotSpecified -TargetObject $Name -Message "Privilege '$Name' could not be set"
					}
				}
				else
				{
					Write-Error -Category InvalidArgument -TargetObject $Name -Message "Privilege '$Name' could no be resolved"
				}
			}
		}
	}
}

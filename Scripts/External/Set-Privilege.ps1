
<#
This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset
#>

<#
.SYNOPSIS
Toggle security privileges for the current PowerShell session.

.DESCRIPTION
Toggle security privileges for the current PowerShell session.
This is needed to gain privileged access to registry ie. to be able to take ownership
or to set registry permissions to keys and values.

.PARAMETER Name
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
TODO: After runing this script, seems like some variables are removed, See Exit-Text "UnitTest" variable
Following modifications by metablaster November 2020:
1. Format code according to project best practices
2. Added boilerplate code
3. Make function produce some informational output
4. Added comment based help

.LINK
https://www.powershellgallery.com/packages/Set-Privilege/1.1.2

.COMPONENT
Security
Privilege
TokenPrivilege
#>
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string[]] $Privilege
)

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\..\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
$Accept = "Add or remove privilege from current PowerShell process"
$Deny = "Abort operation, no change to PowerShell process privilege is made"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

<#
.SYNOPSIS
Toggle security privileges for the current PowerShell session.
#>
function Set-Privilege
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
	[OutputType([bool])]
	param(
		[Parameter(Mandatory = $true)]
		[ValidateSet(
			'SeAssignPrimaryTokenPrivilege', 'AssignPrimaryToken',
			'SeAuditPrivilege', 'Audit',
			'SeBackupPrivilege', 'Backup',
			'SeChangeNotifyPrivilege', 'ChangeNotify',
			'SeCreateGlobalPrivilege', 'CreateGlobal',
			'SeCreatePagefilePrivilege', 'CreatePagefile',
			'SeCreatePermanentPrivilege', 'CreatePermanent',
			'SeCreateSymbolicLinkPrivilege', 'CreateSymbolicLink',
			'SeCreateTokenPrivilege', 'CreateToken',
			'SeDebugPrivilege', 'Debug',
			'SeEnableDelegationPrivilege', 'EnableDelegation',
			'SeImpersonatePrivilege', 'Impersonate',
			'SeIncreaseBasePriorityPrivilege', 'IncreaseBasePriority',
			'SeIncreaseQuotaPrivilege', 'IncreaseQuota',
			'SeIncreaseWorkingSetPrivilege', 'IncreaseWorkingSet',
			'SeLoadDriverPrivilege', 'LoadDriver',
			'SeLockMemoryPrivilege', 'LockMemory',
			'SeMachineAccountPrivilege', 'MachineAccount',
			'SeManageVolumePrivilege', 'ManageVolume',
			'SeProfileSingleProcessPrivilege', 'ProfileSingleProcess',
			'SeRelabelPrivilege', 'Relabel',
			'SeRemoteShutdownPrivilege', 'RemoteShutdown',
			'SeRestorePrivilege', 'Restore',
			'SeSecurityPrivilege', 'Security',
			'SeShutdownPrivilege', 'Shutdown',
			'SeSyncAgentPrivilege', 'SyncAgent',
			'SeSystemEnvironmentPrivilege', 'SystemEnvironment',
			'SeSystemProfilePrivilege', 'SystemProfile',
			'SeSystemtimePrivilege', 'SystemTime',
			'SeTakeOwnershipPrivilege', 'TakeOwnership',
			'SeTcbPrivilege', 'Tcb', 'TrustedComputingBase',
			'SeTimeZonePrivilege', 'TimeZone',
			'SeTrustedCredManAccessPrivilege', 'TrustedCredManAccess',
			'SeUndockPrivilege', 'Undock',
			'SeUnsolicitedInputPrivilege', 'UnsolicitedInput'
		)]
		[Alias('PrivilegeName')]
		[string[]] $Name,

		[switch] $Disable
	)

	begin
	{
		$Signature = '[DllImport("ntdll.dll", EntryPoint = "RtlAdjustPrivilege")]
        public static extern IntPtr SetPrivilege(int Privilege, bool bEnablePrivilege, bool IsThreadPrivilege, out bool PreviousValue);

        [DllImport("advapi32.dll")]
		public static extern bool LookupPrivilegeValue(string host, string name, out long pluid);'
		Add-Type -MemberDefinition $Signature -Namespace AdjPriv -Name Privilege

		[scriptblock] $GetPrivilegeConstant = {
			param($StringParam)

			if ($StringParam -eq 'TrustedComputingBase')
			{
				return 'SeTcbPrivilege'
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
		foreach ($Item in $Name)
		{
			if ($PSCmdlet.ShouldProcess("PowerShell process", "$StatusMessage $Item privilege"))
			{
				[long] $PrivID = $null
				# https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupprivilegevaluew
				# If the function succeeds, the function returns nonzero.
				if ([AdjPriv.Privilege]::LookupPrivilegeValue($null, (& $GetPrivilegeConstant $Item), [ref] $PrivID))
				{
					[bool] $PreviousValue = $null

					# https://docs.microsoft.com/en-us/windows/win32/secauthz/enabling-and-disabling-privileges-in-c--
					# https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-adjusttokenprivileges
					if (![bool][long][AdjPriv.Privilege]::SetPrivilege($PrivID, !$Disable, $false, [ref] $PreviousValue))
					{
						Write-Information -Tags "User" -MessageData "INFO: Previous value for $Item was: $PreviousValue"
						Write-Information -Tags "User" -MessageData "INFO: Privilege $Item successfully $($StatusMessage.ToLower())"
					}
					else
					{
						Write-Information -Tags "User" -MessageData "INFO: Previous value: $PreviousValue"
						Write-Error -Category NotSpecified -TargetObject $Item -Message "Privilege '$Item' could not be set"
					}
				}
				else
				{
					Write-Error -Category InvalidArgument -TargetObject $Item -Message "Privilege '$Item' could no be resolved"
				}
			}
		}
	}
}

if ($MyInvocation.InvocationName -ne '.')
{
	Set-Privilege $Privilege @Logs
}

Update-Log

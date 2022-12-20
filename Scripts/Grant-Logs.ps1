
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

.VERSION 0.14.0

.GUID 16cf3c56-2a61-4a72-8f06-6f8165ed6115

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Grant permissions to write and read firewall logs in custom location

.DESCRIPTION
When firewall is set to write logs into custom location inside repository, neither firewall service
nor users can access them.
This script grants permissions to non administrative account to read firewall log files.
It also grants firewall service to write logs to project specified location.

However the Microsoft Protection Service will automatically reset permissions on firewall logs
on system reboot, network reconnect or firewall settings change, for security reasons, in which
case this script needs to be run again.

.PARAMETER User
Standard (non administrative) user account for which to grant logs permission

.PARAMETER Domain
Principal domain for which to grant permission.
By default specified principal gets permission from local machine

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Grant-Logs USERNAME

.EXAMPLE
PS> Grant-Logs USERNAME -Domain COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Grant-Logs.ps1

.OUTPUTS
None. Grant-Logs.ps1 does not generate any output

.NOTES
Running this script makes sense only for custom firewall log location inside repository.
The benefit is to have special syntax coloring and filtering functionality with VSCode.
Before running this script, for first time setup the following must be done:
1. Modify FirewallLogsFolder in Config\ProjectSettings to desired location
2. Run Scripts\Complete-Firewall to apply the change from point one
3. Turning off/on Windows firewall for desired network profile in order for
Windows firewall to start logging into new location.

TODO: Need to verify if gpupdate is needed for first time setup and if so update Complete-Firewall.ps1

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

using namespace System.Security
#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias("UserName")]
	[string] $User,

	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict
$Domain = Format-ComputerName $Domain

# User prompt
$Accept = "Grant permission to read firewall logs until system reboot"
$Deny = "Abort operation, no permission change is done on firewall logs"
if (!(Approve-Execute -Accept $Accept -Unsafe:(!$Develop) -Deny $Deny -Force:$Force)) { exit }
#endregion

Write-Verbose -Message "[$ThisScript] Verifying firewall log file location"

if (!(Compare-Path -Loose $FirewallLogsFolder -ReferencePath "$ProjectRoot\*"))
{
	# Continue only if firewall logs go to location inside repository
	Write-Warning -Message "[$ThisScript] Not granting permissions for $FirewallLogsFolder"
	return
}

# NOTE: FirewallLogsFolder may contain environment variable
$TargetFolder = [System.Environment]::ExpandEnvironmentVariables($FirewallLogsFolder)

if (!(Test-Path -Path $TargetFolder -PathType Container))
{
	# Create directory for firewall logs if it doesn't exist
	New-Item -Path $TargetFolder -ItemType Container | Out-Null
}

# Change in logs location will require system reboot
Write-Information -Tags $ThisScript -MessageData "INFO: Verifying if there is change in log location"
# TODO: Get-NetFirewallProfile: "An unexpected network error occurred",
# happens proably if network is down or adapter not configured?
$OldLogFiles = Get-NetFirewallProfile -PolicyStore $PolicyStore -All |
Select-Object -ExpandProperty LogFileName | Split-Path

[string[]] $OldLocation = @()
foreach ($File in $OldLogFiles)
{
	$OldLocation += [System.Environment]::ExpandEnvironmentVariables($File)
}

# Setup control rights
# NOTE: WriteData and Write are not granted because due to file encoding the logs might become corrupted
$UserControl = [AccessControl.FileSystemRights]::ReadData
$FullControl = [AccessControl.FileSystemRights]::FullControl

# Grant "FullControl" to firewall service for logs folder,
# if Develop is true system must be granted permissions without prompting to allow it
Write-Information -Tags $ThisScript -MessageData "INFO: Granting full control to firewall service for log directory"

Set-Permission $TargetFolder -Owner "System" -Confirm:$false | Out-Null
Set-Permission $TargetFolder -User "System" -Rights $FullControl -Protected -Confirm:$false | Out-Null
Set-Permission $TargetFolder -User "Administrators" -Rights $FullControl -Protected -Confirm:$false | Out-Null
Set-Permission $TargetFolder -User "mpssvc" -Domain "NT SERVICE" -Rights $FullControl -Protected -Confirm:$false | Out-Null

$StandardUser = $true
foreach ($Admin in $(Get-GroupPrincipal -Group "Administrators" -Domain $Domain))
{
	if ($Admin.User -eq $User)
	{
		Write-Warning -Message "[$ThisScript] User '$User' belongs to Administrators group, no need to grant permission"
		$StandardUser = $false
		break
	}
}

if ($StandardUser -and $PSCmdlet.ShouldProcess($TargetFolder, "Grant permissions to user '$User' to read firewall logs"))
{
	# Grant "Read & Execute" to user for firewall logs
	Write-Information -Tags $ThisScript -MessageData "INFO: Granting limited permissions to user '$User' for firewall logs"
	if (Set-Permission $TargetFolder -User $User -Domain $Domain -Rights $UserControl -Confirm:$false)
	{
		# NOTE: For -Exclude we need -Path DIRECTORY\* to get file names instead of file contents
		foreach ($LogFile in $(Get-ChildItem -Path $TargetFolder\* -Filter *.log -Exclude *.filterline.log))
		{
			Write-Verbose -Message "[$ThisScript] Processing: $LogFile"
			Set-Permission $LogFile.FullName -User $User -Domain $Domain -Rights $UserControl -Confirm:$false | Out-Null
		}
	}
}

# If there is at least one change in logs location reboot is required
foreach ($Location in $OldLocation)
{
	if (!(Compare-Path -Path $Location -ReferencePath $TargetFolder))
	{
		Write-Warning -Message "[$ThisScript] System reboot is required for firewall logging path changes"
		break
	}
}

if ($UpdateGPO)
{
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log

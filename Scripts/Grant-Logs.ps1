
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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

However, for security reasons the Microsoft Protection Service will automatically reset permissions
so that only firewall service will have access on firewall logs, which happens on system reboot,
network reconnect or firewall settings change, in which case this script needs to be run again.

.PARAMETER User
Standard (non administrative) user account for which to grant read permissions on log files

.PARAMETER Domain
Principal domain for which to grant permissions.
By default specified principal from local machine gets permissions

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Grant-Logs USERNAME

.EXAMPLE
PS> Grant-Logs USERNAME -Domain COMPUTERNAME

.EXAMPLE
PS> Grant-Logs "NETWORK SERVICE" -Domain "NT AUTHORITY"

.INPUTS
None. You cannot pipe objects to Grant-Logs.ps1

.OUTPUTS
None. Grant-Logs.ps1 does not generate any output

.NOTES
Running this script makes sense only for custom firewall log location inside repository.
The benefit is to have special syntax coloring and filtering functionality in VSCode.
Before running this script, for first time setup the following must be done:

1. Modify FirewallLogsFolder in Config\ProjectSettings to desired location
2. Run Scripts\Complete-Firewall to apply the change from point one
3. Turning off/on Windows firewall for desired network profile in order for Windows firewall to
start logging into new location.

Point 3 however is not a guarantee that all logs will be generated, system reboot is required.

TODO: Need to verify if gpupdate is needed for first time setup and if this can help to avoid reboot

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
Initialize-Project
$Domain = Format-ComputerName $Domain

# User prompt
$Accept = "Grant permission to read firewall logs until system reboot"
$Deny = "Abort operation, no permission change is done on firewall logs"
if (!(Approve-Execute -Accept $Accept -Unsafe:(!$Develop) -Deny $Deny -Force:$Force)) { exit }
#endregion

Write-Verbose -Message "[$ThisScript] Verifying firewall log file location"

if (!(Compare-Path -Path $FirewallLogsFolder -ReferencePath "$ProjectRoot\*" -Loose))
{
	# Continue only if firewall logs go to location inside repository
	Write-Warning -Message "[$ThisScript] Not settings permissions on $FirewallLogsFolder"
	return
}

# NOTE: FirewallLogsFolder may contain environment variable
$DestinationFolder = [System.Environment]::ExpandEnvironmentVariables($FirewallLogsFolder)

if (!(Test-Path -Path $DestinationFolder -PathType Container))
{
	# Create directory for firewall logs if it doesn't exist
	New-Item -Path $DestinationFolder -ItemType Container | Out-Null
}

# Setup control rights
# NOTE: WriteData and Write are not granted because due to file encoding the logs might become corrupted
$UserControl = [AccessControl.FileSystemRights]::ReadData
$FullControl = [AccessControl.FileSystemRights]::FullControl

# Grant "FullControl" to firewall service for logs folder,
# if Develop is true system must be granted permissions without prompting to allow it
Write-Information -Tags $ThisScript -MessageData "INFO: Granting full control to firewall service for log directory '$DestinationFolder'"

Set-Permission $DestinationFolder -Owner "System" -Confirm:$false | Out-Null
Set-Permission $DestinationFolder -User "System" -Rights $FullControl -Protected -Confirm:$false | Out-Null
Set-Permission $DestinationFolder -User "Administrators" -Rights $FullControl -Protected -Confirm:$false | Out-Null
Set-Permission $DestinationFolder -User "mpssvc" -Domain "NT SERVICE" -Rights $FullControl -Protected -Confirm:$false | Out-Null

# Change in logs location will require system reboot
Write-Information -Tags $ThisScript -MessageData "INFO: Verifying if there was change in log location..."

try
{
	# TODO: Get-NetFirewallProfile: "An unexpected network error occurred",
	# happens proably if network is down or adapter not configured?
	$PreviousLocation = Get-NetFirewallProfile -PolicyStore $PolicyStore -All -ErrorAction Stop |
	Select-Object -ExpandProperty LogFileName | Split-Path
}
catch
{
	Write-Error -ErrorRecord $_
	return
}

# If there is at least one change in logs location reboot is required
foreach ($Location in $PreviousLocation)
{
	if (!(Compare-Path -Path $Location -ReferencePath $DestinationFolder))
	{
		Write-Warning -Message "[$ThisScript] System reboot is required for firewall logging path changes"
		return
	}
}

Write-Verbose -Message "[$ThisScript] Verifying if all log files are present"

# NOTE: For -Exclude we need -Path DIRECTORY\* to get file names instead of file contents
$PresentLogFiles = Get-ChildItem -Path $DestinationFolder\* -Filter *.log -Exclude *.filterline.log

# If log file location is changed, log files won't be instantly generated until system reboot
# We can force firewal service to generate log files by toggling the setting on which packets
# to log, however it's not guaranteed all 3 log files will be generated, which depends on
# currently used firewal profile by configured NIC, so the safest methods is system reboot.
if (($PresentLogFiles | Measure-Object).Count -lt 3)
{
	Write-Warning -Message "[$ThisScript] System reboot is required for firewall logging path changes"
	Write-Information -Tags $ThisScript -MessageData "INFO: $ThisScript script should rerun on each reboot or firewall setting change to grant read permissions to '$User' user"
	return
}

$StandardUser = $true
foreach ($Admin in $(Get-GroupPrincipal -Group "Administrators" -Domain $Domain))
{
	if ($User -eq $Admin.User)
	{
		Write-Warning -Message "[$ThisScript] User '$User' belongs to Administrators group, no need to grant permissions"
		$StandardUser = $false
		break
	}
}

if ($StandardUser -and $PSCmdlet.ShouldProcess($DestinationFolder, "Grant permissions to user '$User' to read firewall logs"))
{
	# Grant "Read & Execute" to user for firewall logs
	Write-Information -Tags $ThisScript -MessageData "INFO: Granting limited permissions to user '$User' for firewall logs"
	if (Set-Permission $DestinationFolder -User $User -Domain $Domain -Rights $UserControl -Confirm:$false)
	{
		foreach ($LogFile in $PresentLogFiles)
		{
			Write-Verbose -Message "[$ThisScript] Processing '$LogFile'"
			Set-Permission $LogFile.FullName -User $User -Domain $Domain -Rights $UserControl -Confirm:$false | Out-Null
		}
	}
}

if ($UpdateGPO)
{
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log

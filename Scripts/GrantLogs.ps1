
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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

# For: AccessControl.FileSystemRights
using namespace System.Security

<#
.SYNOPSIS
Grant permissions to read and write firewall logs in custom location

.DESCRIPTION
When firewall is set to write logs into custom location inside repository neither firewall service
not users can access them.
Grant permissions to non administrative account to read firewall log files.
Also grants firewall service to write logs to project specified location.
The Microsoft Protection Service will automatically reset permissions on firewall logs either
on system reboot or network reconnect, for security reasons.

.PARAMETER Principal
Non administrative user account for which to grant permission

.PARAMETER ComputerName
Principal domain for which to grant permission.
By default specified principal gets permission from local machine

.EXAMPLE
PS> .\GrantLogs.ps1 USERNAME

.EXAMPLE
PS> .\GrantLogs.ps1 USERNAME -Computer COMPUTERNAME

.INPUTS
None. You cannot pipe objects to GrantLogs.ps1

.OUTPUTS
None. GrantLogs.ps1 does not generate any output

.NOTES
Running this script makes sense only for custom firewall log location inside repository.
The benefit is to have special syntax coloring and filtering functionality with VSCode.
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string] $Principal,

	[Parameter()]
	[Alias("Computer", "Server", "Domain", "Host", "Machine")]
	[string] $ComputerName = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $SkipPrompt
)

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
if (!$SkipPrompt)
{
	$Accept = "Grant permission to read firewall log files until system reboot"
	$Deny = "Abort operation, no permission change is done on firewall logs"
	Update-Context $ScriptContext $ThisScript @Logs
	if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
}

Write-Verbose -Message "[$ThisScript] Verifying firewall log file location"

if (!(Test-Environment -Path $FirewallLogsFolder) -or
	!(Compare-Path -Loose $FirewallLogsFolder -ReferencePath "$ProjectRoot\*"))
{
	# Grant permission only if firewall logs go to valid location inside repository
	Write-Warning -Message "Not granting permissions for $FirewallLogsFolder"
	exit
}

# NOTE: FirewallLogsFolder may contain environment variable
$TargetFolder = [System.Environment]::ExpandEnvironmentVariables($FirewallLogsFolder)

if (!(Test-Path -Path $TargetFolder -PathType Container @Logs))
{
	# Create directory for firewall logs if it doesn't exist
	New-Item -Path $TargetFolder -ItemType Container @Logs | Out-Null
}

# Change in logs location will require system reboot
Write-Information -Tags "Project" -MessageData "INFO: Verifying if there is change in log location"
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
$UserControl = [AccessControl.FileSystemRights] "ReadAndExecute, WriteData, Write"
$FullControl = [AccessControl.FileSystemRights]::FullControl

# Grant "FullControl" to firewall service for logs folder
Write-Information -Tags "User" -MessageData "INFO: Granting full control to firewall service for log directory"

Set-Permission $TargetFolder -Owner "System" | Out-Null
Set-Permission $TargetFolder -Principal "System" -Rights $FullControl -Protected | Out-Null
Set-Permission $TargetFolder -Principal "Administrators" -Rights $FullControl -Protected | Out-Null
Set-Permission $TargetFolder -Principal "mpssvc" -Domain "NT SERVICE" -Rights $FullControl -Protected | Out-Null

$StandardUser = $true
foreach ($Admin in $(Get-GroupPrincipal -Group "Administrators" -Computer $ComputerName @Logs))
{
	if ($Principal -eq $Admin.User)
	{
		Write-Warning -Message "User '$Principal' belongs to Administrators group, no need to grant permission"
		$StandardUser = $false
		break
	}
}

if ($StandardUser)
{
	# Grant "Read & Execute" to user for firewall logs
	Write-Information -Tags "User" -MessageData "INFO: Granting limited permissions to user '$Principal' for log directory"
	Set-Permission $TargetFolder -Principal $Principal -Computer $ComputerName -Rights $UserControl | Out-Null

	# NOTE: For -Exclude we need -Path DIRECTORY\* to get file names instead of file contents
	foreach ($LogFile in $(Get-ChildItem -Path $TargetFolder\* -Filter *.log -Exclude *.filterline.log @Logs))
	{
		Write-Verbose -Message "[$ThisScript] Processing: $LogFile"
		Set-Permission $LogFile.FullName -Principal $Principal -Computer $ComputerName -Rights $UserControl | Out-Null
	}
}

# If there is at least one change in logs location reboot is required
foreach ($Location in $OldLocation)
{
	if (!(Compare-Path $Location $TargetFolder))
	{
		Write-Warning -Message "System reboot is required for firewall logging path changes"
		break
	}
}

Update-Log

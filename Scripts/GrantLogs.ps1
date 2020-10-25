
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

<#
.SYNOPSIS
Grant permissions to read and write firewall log files
.DESCRIPTION
Grant permissions to non administrative account to read firewall log files until system reboot.
Also grants firewall service to write logs to project specified location.
The Microsoft Protection Service will automatically reset permissions on firewall logs on system boot.
.PARAMETER Principal
Non administrative user account for which to grant permission
.PARAMETER ComputerName
Principal domain for which to grant permission.
By default principal from local machine gets permission
.EXAMPLE
PS> GrantLogs.ps1 USERNAME
.EXAMPLE
PS> GrantLogs.ps1 USERNAME -Computer COMPUTERNAME
.NOTES
Running this script makes sense only for custom firewall log location inside repository
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string] $Principal,

	[Parameter()]
	[Alias("Computer", "Server", "Domain", "Host", "Machine")]
	[string] $ComputerName = [System.Environment]::MachineName
)

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
$Accept = "Grant permission to read firewall logs files until system reboot"
$Deny = "Abort operation, no permission change is don on firewall logs"
Update-Context $ScriptContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Setup local variables
$Type = [System.Security.AccessControl.AccessControlType]::Allow
$UserControl = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
$FullControl = [System.Security.AccessControl.FileSystemRights]::FullControl

$Inheritance = [Security.AccessControl.InheritanceFlags] 'ContainerInherit,ObjectInherit'
$Propagation = [System.Security.AccessControl.PropagationFlags]::None

try
{
	Write-Information -Tags "User" -MessageData "INFO: Translating domain and user account"
	$User = New-Object -TypeName System.Security.Principal.NTAccount($ComputerName, $Principal) @Logs
	$FirewallService = New-Object -TypeName System.Security.Principal.NTAccount("NT SERVICE", "mpssvc") @Logs

	# Verify user and service exist
	$User.Translate([System.Security.Principal.SecurityIdentifier]).ToString() | Out-Null
	$FirewallService.Translate([System.Security.Principal.SecurityIdentifier]).ToString() | Out-Null
}
catch
{
	$_
	Write-Warning -Message "Specified parameters could not be resolved" @Logs
	return
}

$FolderOwner = New-Object -TypeName System.Security.Principal.NTAccount("System") @Logs

# Represents an abstraction of an access control entry (ACE) that defines an access rule for a file or directory
$AdminPermission = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", $FullControl, $Inheritance, $Propagation, $Type) @Logs
$SystemPermission = New-Object System.Security.AccessControl.FileSystemAccessRule("System", $FullControl, $Inheritance, $Propagation, $Type) @Logs
$FirewallPermission = New-Object System.Security.AccessControl.FileSystemAccessRule($FirewallService, $FullControl, $Inheritance, $Propagation, $Type) @Logs

# Grant "FullControl" to firewall service for logs folder
Write-Information -Tags "User" -MessageData "INFO: Grant 'FullControl' to required principals for: $LogsFolder\Firewall"
$Acl = Get-Acl $LogsFolder\Firewall @Logs

$Acl.SetOwner($FolderOwner)
$Acl.SetAccessRuleProtection($true, $false)

# The SetAccessRule method adds the specified access control list (ACL) rule or overwrites any
# identical ACL rules that match the FileSystemRights value of the rule parameter.
$Acl.SetAccessRule($FirewallPermission)
$Acl.SetAccessRule($AdminPermission)
$Acl.SetAccessRule($SystemPermission)

Set-Acl $LogsFolder\Firewall $Acl @Logs

$StandardUser = $true
foreach ($Admin in $(Get-GroupPrincipal -Group "Administrators" -Computer $ComputerName @Logs))
{
	# NTAccount.ToString() Returns the account name, in Domain\Account format
	if ($User.ToString() -eq $Admin.Account)
	{
		Write-Warning -Message "User '$User' belongs to Administrators group, no need to grant permission"
		$StandardUser = $false
		break
	}
}

if ($StandardUser)
{
	# Grant "Read & Execute" to user for firewall logs
	Write-Information -Tags "User" -MessageData "INFO: Grant 'Read & Execute' permission to user '$User' for: $LogsFolder\Firewall\*.log"
	$UserFolderPermission = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $UserControl, $Inheritance, $Propagation, $Type) @Logs
	$UserFilePermission = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $UserControl, $Type) @Logs

	$Acl = Get-Acl $LogsFolder\Firewall @Logs
	$Acl.SetAccessRule($UserFolderPermission)
	Set-Acl $LogsFolder\Firewall $Acl @Logs

	foreach ($LogFile in $(Get-ChildItem -Path $LogsFolder\Firewall -Filter *.log @Logs))
	{
		Write-Verbose -Message "[$ThisScript] Processing: $LogFile"
		$Acl = Get-Acl $LogFile.FullName @Logs
		$Acl.SetAccessRule($UserFilePermission)
		Set-Acl $LogFile.Fullname $Acl @Logs
	}
}

Write-Information -Tags "User" -MessageData "INFO: All operations completed successfully"
Update-Log


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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

.VERSION 0.10.1

.GUID 4d694877-d0da-4ad0-8759-cec005c92bc3

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Deploy public SSH key to remote host using SSH

.DESCRIPTION
Authorize this Windows machine to connect to SSH server host by uploading
public SSH key to correct destination on remote host and adjust required permissions.
for users this is ~\.ssh\authorized_keys, for administrators it's
%ProgramData%\ssh\administrators_authorized_keys

.PARAMETER User
The user to log in as on the remote machine.

.PARAMETER Domain
Target computer or host name

.PARAMETER Admin
If specified, the key is added to system wide configuration.
Valid only if the User parameter belongs to Administrators group on remote host.

.PARAMETER Overwrite
Overwrite file on remote host instead of appending key to existing file

.EXAMPLE
PS> .\Deploy-SshKey.ps1 -User ServerAdmin -Domain Server1 -Admin

.EXAMPLE
PS> .\Deploy-SshKey.ps1 -User ServerUser -Domain Server1 -Key "$HOME\.ssh\id_ecdsa.pub"

.INPUTS
None. You cannot pipe objects to Deploy-SshKey.ps1

.OUTPUTS
None. Deploy-SshKey.ps1 does not generate any output

.NOTES
Password based authentication is needed for first time setup or
if no existing public key is ready on remote host.
TODO: Optionally deploy sshd_config to remote
TODO: Make use of certificates

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://code.visualstudio.com/docs/remote/troubleshooting#_configuring-key-based-authentication
#>

#Requires -Version 5.1

[CmdletBinding()]
[OutputType([void])]
param (
	[Parameter(Mandatory = $true)]
	[Alias("UserName")]
	[string] $User,

	[Parameter(Mandatory = $true)]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter()]
	[string] $Key = "$HOME\.ssh\id_ecdsa-remote-ssh.pub",

	[Parameter()]
	[switch] $Admin,

	[Parameter()]
	[switch] $Overwrite
)

if (!(Test-Path -Path $Key))
{
	Write-Error -Category ObjectNotFound -TargetObject $Key -Message "Specified SSH key was not found: $Key"
	return
}

# Set remote key destination
if ($Admin)
{
	$FilePath = "C:\ProgramData\ssh\administrators_authorized_keys"
}
else
{
	$FilePath = "C:\Users\$User\.ssh\authorized_keys"
}

$InformationPreference = "Continue"
Write-Information -Tags "User" -MessageData "INFO: Upload key to $Domain"

# Upload key
if ($Overwrite)
{
	Get-Content $Key | Out-String | ssh $User@$Domain "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`"; Set-Content -Force -Path $FilePath`""
}
else
{
	Get-Content $Key | Out-String | ssh $User@$Domain "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`"; Add-Content -Force -Path $FilePath`""
}

# Adjust permissions
Write-Information -Tags "User" -MessageData "INFO: Set ownership of file to user $User"
ssh $User@$Domain "cmd.exe /C icacls $FilePath /setowner $User"

Write-Information -Tags "User" -MessageData "INFO: Remove file inherited permissions"
ssh $User@$Domain "cmd.exe /C icacls $FilePath /inheritancelevel:r"

Write-Information -Tags "User" -MessageData "INFO: Grant permissions on file for user $User"
ssh $User@$Domain "cmd.exe /C icacls $FilePath /grant "$User":F"

Write-Information -Tags "User" -MessageData "INFO: Grant permissions on file for user SYSTEM"
ssh $User@$Domain "cmd.exe /C icacls $FilePath /grant SYSTEM:F"

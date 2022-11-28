
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Deploy public SSH key to remote host using SSH

.DESCRIPTION
Authorize this Windows machine to connect to SSH server host by uploading
public SSH key to default location on remote host and adjust required permissions.

For standard users this is ~\.ssh\authorized_keys, for administrators it's
%ProgramData%\ssh\administrators_authorized_keys

.PARAMETER Domain
Target computer or host name

.PARAMETER User
The user to log in as, on the remote machine.

.PARAMETER Key
Specify public SSH key with is to be transferred.
By default this is: $HOME\.ssh\id_ecdsa-remote-ssh.pub

.PARAMETER Port
Specify SSH port on which the remote server is listening.
The default is port 22

.PARAMETER System
If specified, the key is added to system wide configuration.
Valid only if the User parameter belongs to Administrators group on remote host.

.PARAMETER Force
Overwrite file on remote host instead of appending key to existing file

.EXAMPLE
PS> Deploy-SshKey -User ServerAdmin -Domain Server1 -System

.EXAMPLE
PS> Deploy-SshKey -User ServerUser -Domain Server1 -Key "$HOME\.ssh\id_ecdsa.pub"

.INPUTS
None. You cannot pipe objects to Deploy-SshKey

.OUTPUTS
None. Deploy-SshKey does not generate any output

.NOTES
Remote computer must install SSH server in optional features
Remote computer must have OpenSSH SSH server service running
Local computer must create a "config" file in $HOME\.ssh\
Sample config file can be found in Config\SSH

Password based authentication is needed for first time setup or
if no existing public SSH key is ready on remote host.

TODO: Optionally deploy sshd_config to remote
TODO: Make use of certificates
TODO: When specifying port for ssh.exe? progress bar doesn't remove it's status on completion

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Deploy-SshKey.md

.LINK
https://code.visualstudio.com/docs/remote/troubleshooting#_configuring-key-based-authentication
#>
function Deploy-SshKey
{
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Deploy-SshKey.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain,

		[Parameter(Mandatory = $true)]
		[Alias("UserName")]
		[string] $User,

		[Parameter(Mandatory = $true)]
		[string] $Key,

		[Parameter()]
		[uint32] $Port = 22,

		[Parameter()]
		[switch] $System,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$KeyFileName = Split-Path -Path $Key -Leaf

	if (!(Get-Command -Name ssh.exe -CommandType Application))
	{
		Write-Error -Category ObjectNotFound -Message "ssh.exe not found on this computer"
		return
	}

	if (!(Test-Path -Path $Key))
	{
		Write-Error -Category ObjectNotFound -TargetObject $Key -Message "Specified SSH key was not found '$KeyFileName'"
		return
	}

	if ((Split-Path -Path $KeyFileName -Extension) -ne ".pub")
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified SSH key doesn't seem to be a public key"
		return
	}

	if (!(Test-NetConnection -ComputerName $Domain -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue))
	{
		# PS might fail but SSH connection could work regardless
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to test connection to '$Domain' computer on SSH port $Port"
	}

	# Set remote key destination and command to run
	if ($System)
	{
		$FilePath = "C:\ProgramData\ssh\administrators_authorized_keys"

		if ($Force)
		{
			$Command = "powershell Set-Content -Force -Path $FilePath"
		}
		else
		{
			$Command = "powershell Add-Content -Force -Path $FilePath"
		}
	}
	else
	{
		$FilePath = "C:\Users\$User\.ssh\authorized_keys"

		if ($Force)
		{
			$Command = "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`" | Out-Null; Set-Content -Force -Path $FilePath`""
		}
		else
		{
			$Command = "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`" | Out-Null; Add-Content -Force -Path $FilePath`""
		}
	}

	if ($PSCmdlet.ShouldProcess("$Domain\$FilePath", "Deploy '$KeyFileName' key to '$Domain' computer"))
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Uploading '$KeyFileName' key to '$Domain' computer"
		Get-Content $Key | Out-String | ssh -p $Port $User@$Domain $Command | Out-Null
	}

	# Adjust permissions
	if ($PSCmdlet.ShouldProcess($FilePath, "Adjust file system permissions on '$Domain' computer"))
	{
		$RemoteFileName = Split-Path -Path $FilePath -Leaf

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Setting ownership of '$RemoteFileName' to user '$User'"
		ssh -p $Port $User@$Domain "cmd.exe /C icacls $FilePath /setowner $User"

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Removing inherited permissions on '$RemoteFileName' file"
		ssh -p $Port $User@$Domain "cmd.exe /C icacls $FilePath /inheritancelevel:r"

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Granting permissions on '$RemoteFileName' file for user '$User'"
		ssh -p $Port $User@$Domain "cmd.exe /C icacls $FilePath /grant ${User}:F"

		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Granting permissions on '$RemoteFileName' file for user 'SYSTEM'"
		ssh -p $Port $User@$Domain "cmd.exe /C icacls $FilePath /grant SYSTEM:F"
	}
}

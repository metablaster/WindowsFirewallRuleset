
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

.GUID 4ece463d-8146-4083-83cc-a60e19a0c12d

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Deploy SSH Key for Remote-SSH extension

.DESCRIPTION
Deploy public SSH Key to remote computer required for Remote-SSH extension to connect to VSCode
remotely via SSH connection.

.PARAMETER User
User name of the remote computer to which SSH key will be deployed.
This user name will also be used to connect to remote VSCode server.

.PARAMETER Domain
Remote computer name which will be used for Remote-SSH

.PARAMETER SshKey
Public SSH key which to deploy

.EXAMPLE
PS> Deploy-SshKey Admin Server -SshKey $HOME\.ssh\remote-ssh.pub

.INPUTS
None. You cannot pipe objects to Deploy-SshKey.ps1

.OUTPUTS
None. Deploy-SshKey.ps1 does not generate any output

.NOTES
Remote computer must install SSH server in optional features
Local computer must create a "config" file in $HOME\.ssh\
Sample config file can be found in Config\SSH

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
[OutputType([void])]
param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias("UserName")]
	[string] $User,

	[Parameter(Mandatory = $true, Position = 1)]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter(Mandatory = $true)]
	[string] $SshKey
)

process
{
	Write-Debug -Message "[Initialize-RemoteSSH] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ShouldProcess("$Domain computer", "Deploy SSH public key"))
	{
		if (!(Test-Path -Path $SshKey))
		{
			Write-Error -Category InvalidArgument -TargetObject $SshKey -Message "Specified SSH key not found"
			return
		}
		elseif ((Split-Path -Path $SshKey -Extension) -ne ".pub")
		{
			Write-Warning -Message "Specified SSH key doesn't seem to be public key"
			return
		}

		$PublicKey = Get-Content $SshKey | Out-String
		$Command = "powershell `"New-Item -Force -ItemType Directory -Path `"`$HOME\.ssh`" | Out-Null; Add-Content -Force -Path `"`$HOME\.ssh\authorized_keys`"`""
		$PublicKey | ssh "$User@$Domain" $Command | Out-Null
	}
}

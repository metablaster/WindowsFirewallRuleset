
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

.VERSION 0.10.0

.GUID 0390fb1d-bf61-441b-9746-63a34be384bb

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Initialize development environment

.DESCRIPTION
Configure git, gpg, set up SSH keys and initialize project.
You can choose which operations to perform by either accepting or denying specific actions.
The purpose of this script is automated development environment setup for the purpose of
testing code and firewall deployment in virtual machine with fresh installed operating system.

A clean OS environment is requirement for best test results, however setting up everything over and
over again it tedious, that's where this script is going to help.

.PARAMETER User
User name which to set into git config

.PARAMETER Email
e-mail which to set into git config

.PARAMETER SshKey
SSH key location which is to be copied to ~\ssh and then added to ssh-agent.
If not specified default SSH key locations are searched.

.PARAMETER Scope
Specifies the scope of git configuration which is to be configured.
Acceptable values are Local, Global or System.

.PARAMETER Force
If specified, skips prompt to run script and forces project initialization.

.EXAMPLE
PS> .\Initialize-Development.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Development.ps1

.OUTPUTS
None. Initialize-Development.ps1 does not generate any output

.NOTES
You might need to run this script twice or more times, ex, first time for git and gpg,
second time to resolve errors that require Administrator privileges and third time to try again
as standard user, each time confirming only required operations.
TODO: Implement generating SSH and GPG keys
TODO: Implement copying requested keys to clipboard
TODO: Implement creating a backup of keys

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter(Mandatory = $true)]
	[string] $User,

	[Parameter(Mandatory = $true)]
	[System.Net.Mail.MailAddress] $Email,

	[Parameter()]
	[System.IO.FileInfo] $SshKey,

	[Parameter(Mandatory = $true)]
	[ValidateSet("Local", "Global", "System")]
	[string] $Scope = "Local",

	[Parameter()]
	[switch] $Force
)

[bool] $YesToAll = $false
[bool] $NoToAll = $false

if ($Force -or $PSCmdlet.ShouldContinue("Set up git and SSH keys", "Initialize development environment", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	try
	{
		& $PSScriptRoot\..\Unblock-Project.ps1
		. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
	}
	catch
	{
		return
	}

	$Credential = Get-Credential -Message "Enter credentials for computer $([System.Environment]::MachineName)" -EA Stop

	$InvokeParams = [hashtable]@{
		Credential = $Credential
		NoNewWindow = $true
		WorkingDirectory = $ProjectRoot
	}

	$GitParams = [hashtable]@{
		Credential = $Credential
		NoNewWindow = $true
		WorkingDirectory = $ProjectRoot
		Path = "git.exe"
	}

	$ScopeCommand = switch ($Scope)
	{
		"Local" { "--local"; break }
		"Global" { "--global"; break }
		"System" { "--system" }
	}

	if (!(Test-Path $ProjectRoot\.git -PathType Container))
	{
		if ($YesToAll -or $PSCmdlet.ShouldProcess($ProjectRoot, "initialize repository"))
		{
			Invoke-Process @GitParams -ArgumentList "init $ProjectRoot -b init"
			Invoke-Process @GitParams -ArgumentList "add ."
			Invoke-Process @GitParams -ArgumentList 'commit -m "throw away"'
			Invoke-Process @GitParams -ArgumentList "remote add upstream git@github.com:metablaster/WindowsFirewallRuleset.git"

			Invoke-Process @GitParams -ArgumentList "fetch upstream"
			Invoke-Process @GitParams -ArgumentList "checkout develop"
			Invoke-Process @GitParams -ArgumentList "branch -D init"
		}
	}

	if ($YesToAll -or $PSCmdlet.ShouldProcess("git config", "Set ssh path"))
	{
		$SSH = Get-Command -Name ssh.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path

		if ([string]::IsNullOrEmpty($SSH))
		{
			Write-Error -Category ObjectNotFound -Message "The command ssh.exe was not found"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] SSH command is '$SSH'"

			# git config --global --replace-all core.sshCommand "'C:\Program Files\OpenSSH-Win64\ssh.exe'"
			[string] $SshCommand = "config $ScopeCommand --replace-all core.sshCommand " + "'" + '"' + $SSH + '"' + "'"

			Write-Debug -Message "[$ThisScript] SSH command argument is '$SshCommand'"
			Invoke-Process @GitParams -ArgumentList $SshCommand
		}
	}

	if ($YesToAll -or $PSCmdlet.ShouldProcess("git config", "Set gpg path"))
	{

		$GPG = Get-Command -Name gpg.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path

		if ([string]::IsNullOrEmpty($GPG))
		{
			Write-Error -Category ObjectNotFound -Message "The command gpg.exe was not found"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] GPG program is '$GPG'"

			# git config --global --replace-all gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
			[string] $GpgProgram = "config $ScopeCommand --replace-all gpg.program " + '"' + $GPG + '"'

			Write-Debug -Message "[$ThisScript] GPG program argument is '$GpgProgram'"
			Invoke-Process @GitParams -ArgumentList $GpgProgram
		}
	}

	if ($YesToAll -or $PSCmdlet.ShouldProcess("git config", "Set gpg signingkey and gpgsign"))
	{
		# gpg --list-secret-keys --keyid-format LONG
		$KeyData = Invoke-Process gpg.exe @InvokeParams -ArgumentList "--list-secret-keys --keyid-format LONG" -Raw

		# 		-----------------------------------------------
		# sec   rsa4096/3AA5C34371567BD2  2020-08-18 [SC] [expires: 2051-08-18]
		#       42B317FD4BA89E7A2D3DB3AA5C34371567BD2
		# uid                 [ultimate] username <44481081+username@users.noreply.github.com>
		# ssb   rsa4096/42B317FD4BA89E7A 2020-08-18 [E] [expires: 2025-08-18]
		$Regex = [regex]::Matches($KeyData, "sec.+(?=\/)\/(?<key>\w+)")

		if ($Regex.Success)
		{
			$KeyGroup = $Regex.Captures.Groups["key"]
			if ($KeyGroup.Success)
			{
				$Key = $KeyGroup.Value
				Write-Verbose -Message "[$ThisScript] SSH key is '$Key'"

				# git config --global user.signingkey 3AA5C34371567BD2
				Invoke-Process @GitParams -ArgumentList "config $ScopeCommand user.signingkey $Key"

				# git config --global commit.gpgsign true
				Invoke-Process @GitParams -ArgumentList "config $ScopeCommand commit.gpgsign true"
			}
			else
			{
				Write-Error -Category ParserError -TargetObject $Regex -Message "Invalid regex capture"
			}
		}
		else
		{
			Write-Error -Category ParserError -TargetObject $Regex -Message "Invalid regex"
		}
	}

	if ($YesToAll -or $PSCmdlet.ShouldProcess("ssh agent", "Add SSH key to ssh agent"))
	{
		if (!(Get-Service -Name ssh-agent -ErrorAction Ignore))
		{
			Write-Error -Category ObjectNotFound -Message "sss-agent service not found"
		}
		elseif (Initialize-Service -Name ssh-agent)
		{
			if ($SshKey)
			{
				if ($SshKey.Exists)
				{
					$SshDirectory = "$env:SystemDrive\Users\$($Credential.UserName)\.ssh"

					if (!(Test-Path $SshDirectory -PathType Container))
					{
						New-Item $SshDirectory -ItemType Directory | Out-Null
					}

					if (!(Test-Path $SshDirectory\$($SshKey.Name)))
					{
						Copy-Item $SshKey -Destination $SshDirectory
					}

					Invoke-Process ssh-add.exe @InvokeParams -ArgumentList $SshDirectory\$($SshKey.Name)
				}
				else
				{
					Write-Error -Category ObjectNotFound -TargetObject $SshKey `
						-Message "Specified SSH key could not be found '$SshKey'"
				}
			}
			else
			{
				# NOTE: ssh-add without arguments adds the default keys ~/.ssh/id_rsa, ~/.ssh/id_dsa,
				# ~/.ssh/id_ecdsa. ~/ssh/id_ed25519, and ~/.ssh/identity if they exist
				Invoke-Process ssh-add.exe @InvokeParams
			}
		}
	}

	if ($YesToAll -or $PSCmdlet.ShouldProcess("git config", "Set username and email"))
	{
		# git config --global user.name "your name or username"
		Invoke-Process @GitParams -ArgumentList "config $ScopeCommand user.name $User"

		# git config --global user.email youremail@example.com
		Invoke-Process @GitParams -ArgumentList "config $ScopeCommand user.email $($Email.Address)"
	}

	if ($Force -or $PSCmdlet.ShouldContinue("Open git config in default editor", "Verify git config file", $true, [ref] $null, [ref] $null))
	{
		# TODO: Waiting for your editor to close the file... will not be shown
		Invoke-Process @GitParams -ArgumentList "config $ScopeCommand --edit" -Timeout -1
	}

	if ($Force -or $PSCmdlet.ShouldContinue("Initialize project", "Windows Firewall Ruleset", $true, [ref] $YesToAll, [ref] $NoToAll))
	{
		Initialize-Project -Strict -Force:$Force
	}
}

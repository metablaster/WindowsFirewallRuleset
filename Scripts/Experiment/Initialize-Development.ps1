
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

<#PSScriptInfo

.VERSION 0.13.1

.GUID 0390fb1d-bf61-441b-9746-63a34be384bb

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1, Unblock-Project.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Initialize
#>

<#
.SYNOPSIS
Initialize development environment

.DESCRIPTION
Configure git, gpg, set up SSH keys and finally initialize project according to options specified
in Config\ProjectSettings.ps1
You can choose which operations to perform by either accepting or denying specific actions.
The purpose of this script is automated development environment setup for the purpose of
testing code and firewall deployment inside virtual machine with fresh installed operating system.

A clean OS environment is requirement for best test results, however setting up everything over and
over again it tedious, that's where this script is going to help.

.PARAMETER User
User name which to set into git config

.PARAMETER Email
email which to set into git config

.PARAMETER SshKey
SSH key location which is to be copied to ~\ssh and then added to ssh-agent.
If not specified default SSH key locations are searched.

.PARAMETER Force
If specified, skips prompts to run commands.

.EXAMPLE
PS> Initialize-Development

.EXAMPLE
PS> Initialize-Development -User UserName -Email mymail@mail.com

.EXAMPLE
PS> Initialize-Development -SshKey C:\Users\User\.ssh\id_pub -User UserName -Email mymail@mail.com

.INPUTS
None. You cannot pipe objects to Initialize-Development.ps1

.OUTPUTS
None. Initialize-Development.ps1 does not generate any output

.NOTES
This script must be run as Administrator because of initialization procedure, however you're
prompted to enter Windows credentials for the user for which to set up git configuration, this may
be any user.

TODO: Implement generating SSH and GPG keys
TODO: Implement copying requested keys to clipboard
TODO: Implement creating a backup of keys
TODO: Implement GpgKey parameter

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

	[Parameter()]
	[switch] $Force
)

New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

[bool] $YesToAll = $false
[bool] $NoToAll = $false

if ($Force -or $PSCmdlet.ShouldContinue("Set up git, gpg keys, SSH keys and check project requirements?", "Initialize development environment", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	$Git = Get-Command -Name git.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path

	if ([string]::IsNullOrEmpty($Git))
	{
		Write-Error -Category ObjectNotFound -Message "The command git.exe was not found"
		Write-Information -Tags $ThisScript -MessageData "Please verify git is installed and specified in PATH environment variable"
		return
	}

	try
	{
		& $PSScriptRoot\..\Unblock-Project.ps1 -ErrorAction Stop
		. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -ErrorAction Stop
	}
	catch
	{
		Write-Error -ErrorRecord $_
		return
	}

	$Credential = Get-Credential -Message "Please enter Windows credentials for user which to set up"

	if (!$Credential)
	{
		# Will happen if credential request was dismissed using ESC key.
		Write-Error -Category InvalidOperation -Message "Credentials are required to access '$Domain'"
	}
	elseif ($Credential.Password.Length -eq 0)
	{
		# Will happen when no password is specified
		Write-Error -Category InvalidData -Message "User '$($Credential.UserName)' must have a password"
		$Credential = $null
	}

	$InvokeParams = @{
		Credential = $Credential
		NoNewWindow = $true
		WorkingDirectory = $ProjectRoot
	}

	$GitParams = @{
		Credential = $Credential
		NoNewWindow = $true
		WorkingDirectory = $ProjectRoot
		Path = $Git
	}

	if ($Force -or $PSCmdlet.ShouldProcess("Setting ssh command in git config", "Set ssh command?", "git config"))
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
			[string] $SshCommand = "config --global --replace-all core.sshCommand " + "'" + '"' + $SSH + '"' + "'"

			Write-Debug -Message "[$ThisScript] SSH command argument is '$SshCommand'"
			Invoke-Process @GitParams -ArgumentList $SshCommand
		}
	}

	$GPG = Get-Command -Name gpg.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path

	if ($Force -or $PSCmdlet.ShouldProcess("Setting gpg command in git config", "Set gpg command?", "git config"))
	{
		if ([string]::IsNullOrEmpty($GPG))
		{
			Write-Error -Category ObjectNotFound -Message "The command gpg.exe was not found"
		}
		else
		{
			Write-Verbose -Message "[$ThisScript] GPG program is '$GPG'"

			# git config --global --replace-all gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
			[string] $GpgProgram = "config --global --replace-all gpg.program " + '"' + $GPG + '"'

			Write-Debug -Message "[$ThisScript] GPG program argument is '$GpgProgram'"
			Invoke-Process @GitParams -ArgumentList $GpgProgram
		}
	}

	if ($Force -or $PSCmdlet.ShouldProcess("Setting gpg signing key and gpg sign", "Set gpg signing key and gpg sign?", "git config"))
	{
		if ([string]::IsNullOrEmpty($GPG))
		{
			Write-Error -Category ObjectNotFound -Message "The command gpg.exe was not found"
		}
		else
		{
			# gpg --list-secret-keys --keyid-format LONG
			$KeyData = Invoke-Process $GPG @InvokeParams -ArgumentList "--list-secret-keys --keyid-format LONG" -Raw

			if ([string]::IsNullOrEmpty($KeyData))
			{
				Write-Error -Category InvalidResult -Message "GPG agent doesn't seem to have any associated keys"
			}
			else
			{
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
						Invoke-Process @GitParams -ArgumentList "config --global user.signingkey $Key"

						# git config --global commit.gpgsign true
						Invoke-Process @GitParams -ArgumentList "config --global commit.gpgsign true"
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
		}
	}

	if ($Force -or $PSCmdlet.ShouldProcess("Adding keys to ssh agent", "Add keys to ssh agent?", "ssh agent"))
	{
		if (!(Get-Service -Name ssh-agent -ErrorAction Ignore))
		{
			Write-Error -Category ObjectNotFound -Message "ssh-agent service not found"
		}
		elseif (Initialize-Service -Name ssh-agent)
		{
			$SshAdd = Get-Command -Name ssh-add.exe -ErrorAction Ignore | Select-Object -ExpandProperty Path

			if ([string]::IsNullOrEmpty($SshAdd))
			{
				Write-Error -Category ObjectNotFound -Message "The command ssh-add.exe was not found"
			}
			else
			{
				if ($SshKey)
				{
					if ($SshKey.Exists)
					{
						$SshDirectory = "$env:SystemDrive\Users\$($Credential.UserName)\.ssh"

						if (!(Test-Path $SshDirectory -PathType Container))
						{
							New-Item -Path $SshDirectory -ItemType Directory | Out-Null
						}

						if (!(Test-Path $SshDirectory\$($SshKey.Name)))
						{
							Copy-Item $SshKey -Destination $SshDirectory
						}

						Invoke-Process $SshAdd @InvokeParams -ArgumentList $SshDirectory\$($SshKey.Name)
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
					Invoke-Process $SshAdd @InvokeParams

					# Check if ssh agent has no keys, in which case previous command did nothing
					$Status = Invoke-Process $SshAdd @InvokeParams -ArgumentList "-l" -Raw

					# ex. The agent has no identities.
					if ($Status -like "*no identities*")
					{
						Write-Error -Category ObjectNotFound -Message "No keys were found to add to ssh agent"
						Write-Information -Tags $ThisScript -MessageData "INFO: Please specify -SshKey parameter and try again"
					}
				}
			}
		}
	}

	if ($Force -or $PSCmdlet.ShouldProcess("Setting git username and email", "Set username and email?", "git config"))
	{
		# git config --global user.name "your name or username"
		Invoke-Process @GitParams -ArgumentList "config --global user.name $User"

		# git config --global user.email youremail@example.com
		Invoke-Process @GitParams -ArgumentList "config --global user.email $($Email.Address)"
	}

	if (!$Force -and $PSCmdlet.ShouldContinue("Open git config in default code editor?", "Verify git config file", $true, [ref] $YesToAll, [ref] $NoToAll))
	{
		# TODO: Waiting for your editor to close the file... will not be shown
		Invoke-Process @GitParams -ArgumentList "config --global --edit" -Timeout -1
	}

	if ($Force -or $PSCmdlet.ShouldProcess("Checking project requirements according to existing settings", "Check project requirements according to existing settings?", "Initialize project"))
	{
		if (!(Get-Variable -Name ProjectCheck -Scope Global -EA Stop).Value)
		{
			Write-Error -Category ObjectNotFound -Message "This action requires ProjectCheck variable to be set"
			return
		}

		if (!(Get-Variable -Name ModulesCheck -Scope Global -EA Stop).Value)
		{
			Write-Error -Category ObjectNotFound -Message "This action requires ModulesCheck variable to be set"
			return
		}

		if (!(Get-Variable -Name ServicesCheck -Scope Global -EA Stop).Value)
		{
			Write-Error -Category ObjectNotFound -Message "This action requires ServicesCheck variable to be set"
			return
		}

		Initialize-Project -Strict
	}
}

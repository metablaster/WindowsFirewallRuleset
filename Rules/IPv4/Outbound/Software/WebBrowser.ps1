
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
Outbound firewall rules for web browsers

.DESCRIPTION
Outbound firewall rules for web browsers that are not from Microsoft of Google

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\WebBrowser.ps1

.INPUTS
None. You cannot pipe objects to WebBrowser.ps1

.OUTPUTS
None. WebBrowser.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Web Browser"
$Accept = "Outbound rules for 3rd party web browsers will be loaded, recommended if such browsers are installed to let them access to network"
$Deny = "Skip operation, outbound rules for web browsers will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Browser installation directories
# TODO: Update path for all users?
# TODO: Returned path will miss browser updaters
#
$FirefoxRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Mozilla Firefox"
$YandexRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Yandex"
$TorRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Tor Browser"
$BraveRoot = "C:\Program Files\BraveSoftware\Brave-Browser\Application"
# TODO: we should probably have a function for this and similar cases?
# Same problem is there for MS Edge
$BraveUpdateRoot = "C:\Program Files (x86)\BraveSoftware\Update"
# TODO: Seemingly impossible to auto detect this one, it won't work anyway, see todo on rule creation below
$BraveTorRoot = "C:\Users\$DefaultUser\AppData\Local\BraveSoftware\Brave-Browser\User Data\cpoalefficncklhjfpglfiplenlpccdb"

#
# Web browser rules
#

#
# Mozilla Firefox
#

# Test if installation exists on system
if ((Confirm-Installation "Firefox" ([ref] $FirefoxRoot)) -or $ForceLoad)
{
	$Program = "$FirefoxRoot\firefox.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Firefox HTTP\S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Firefox FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Firefox QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput

		#
		# IRC: 8605
		# Pokerist: 3103-3110
		# speedtest: 5060, 8080
		#
		New-NetFirewallRule -DisplayName "Firefox special sites" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110, 5060, 8080, 8605 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for IRC, pokerist.com and speedtest.net" | Format-RuleOutput
	}

	$Program = "$FirefoxRoot\pingsender.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Firefox Telemetry" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Pingsender ensures shutdown telemetry data is sent to mozilla after shutdown,
instead of waiting next firefox start which could take hours, days or even more." |
		Format-RuleOutput
	}
}

#
# Yandex
#

# Test if installation exists on system
if ((Confirm-Installation "Yandex" ([ref] $YandexRoot)) -or $ForceLoad)
{
	$Program = "$YandexRoot\YandexBrowser\Application\browser.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Yandex HTTP\S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Yandex FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Yandex QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput

		#
		# IRC: 8605
		# Pokerist: 3103-3110
		# speedtest: 5060, 8080
		#
		New-NetFirewallRule -DisplayName "Yandex special sites" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110, 5060, 8080, 8605 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for IRC, pokerist.com and speedtest.net" | Format-RuleOutput
	}
}

#
# Tor Browser
#

# Test if installation exists on system
# TODO: this will be true even if $false for both!
if ((Confirm-Installation "Tor" ([ref] $TorRoot)) -or $ForceLoad)
{
	$Program = "$TorRoot\Browser\TorBrowser\Tor\tor.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Tor HTTP\S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput

		#
		# IRC: 8605
		# Pokerist: 3103-3110
		# speedtest: 5060, 8080
		#
		New-NetFirewallRule -DisplayName "Tor special sites" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110, 5060, 8080, 8605 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for IRC, pokerist.com and speedtest.net" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor DNS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 53 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "DNS requests to exit relay over Tor network." | Format-RuleOutput

		# OLD: -RemotePort 9001, 9030, 9050, 9051, 9101, 9150
		New-NetFirewallRule -DisplayName "Tor Network" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 8080, 8443, 9001-9003, 9010, 9101 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Tor network specific ports" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor IMAP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 143 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor IMAP SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 993 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor POP3" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 110 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor POP3 SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 995 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor SMTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 25 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor SMTP SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 465 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

#
# Brave
#

# Test if installation exists on system
if ((Confirm-Installation "Brave" ([ref] $BraveRoot)) -or $ForceLoad)
{
	$Program = "$BraveRoot\brave.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Brave HTTP\S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Brave FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Brave QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput

		#
		# IRC: 8605
		# Pokerist: 3103-3110
		# speedtest: 5060, 8080
		#
		New-NetFirewallRule -DisplayName "Brave special sites" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110, 5060, 8080, 8605 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for IRC, pokerist.com and speedtest.net" | Format-RuleOutput
	}

	$Program = "$(Format-Path $BraveUpdateRoot)\BraveUpdate.exe"

	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# NOTE: Current user is needed but not reported in process monitor
		$UpdateAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
		Merge-SDDL ([ref] $UpdateAccounts) -From $UsersGroupSDDL

		New-NetFirewallRule -DisplayName "Brave Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UpdateAccounts `
			-InterfaceType $DefaultInterface `
			-Description "Update Brave browser" | Format-RuleOutput
	}

	#
	# Rule for Brave over Tor network
	#
	$VersionFolder = Invoke-Command -Session $SessionInstance -ScriptBlock {
		$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($using:BraveTorRoot)

		Get-ChildItem -Directory -Path $ExpandedPath -Name -ErrorAction SilentlyContinue | Where-Object {
			$_ -match "(\d+\.){1,4}"
		}
	}

	if ([string]::IsNullOrEmpty($VersionFolder))
	{
		Write-Warning -Message "[$ThisScript] Unable to find version folder in '$BraveTorRoot'"
	}
	else
	{
		$FileName = Invoke-Command -Session $SessionInstance -ScriptBlock {
			$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables("$($using:BraveTorRoot)\$($using:VersionFolder)")

			Get-ChildItem -File -Path $ExpandedPath -Name -ErrorAction SilentlyContinue | Where-Object {
				$_ -match "tor-(\d+\.?){1,4}-win32"
			}
		}

		if ([string]::IsNullOrEmpty($FileName))
		{
			Write-Warning -Message "[$ThisScript] Unable to find tor file in brave browser version folder '$BraveTorRoot\$VersionFolder'"
		}
		else
		{
			$Program = Format-Path "$BraveTorRoot\$VersionFolder\$FileName"
			# NOTE: Not using Test-ExecutableFile here because it would fail since tor file has no extension
			if ((Test-Path -Path $Program) -or $ForceLoad)
			{
				New-NetFirewallRule -DisplayName "Brave Tor" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 443, 8080, 9000-9003, 9090 `
					-LocalUser $UsersGroupSDDL `
					-InterfaceType $DefaultInterface `
					-Description "Brave browser over Tor" | Format-RuleOutput
			}
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

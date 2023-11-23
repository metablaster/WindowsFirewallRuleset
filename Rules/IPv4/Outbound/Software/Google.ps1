
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Outbound firewall rules for Google

.DESCRIPTION
Outbound firewall rules for software from Google

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
PS> .\Google.ps1

.INPUTS
None. You cannot pipe objects to Google.ps1

.OUTPUTS
None. Google.ps1 does not generate any output

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
$Group = "Software - Google"
$Accept = "Outbound rules for Google software will be loaded, recommended if Google software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Google software will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

# Chromecast IP
# Adjust to Chromecast IP in your local network
[IPAddress] $CHROMECAST_IP = "192.168.8.50"

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

#
# Google installation directories
#
$GoogleDriveRoot = "%ProgramFiles%\Google\Drive File Stream"
$GooglePlayRoot = "%ProgramFiles%\Google\Play Games"
$GoogleUpdateRoot = "%ProgramFiles% (x86)\Google\Update"
# TODO: Update path for all users?
$ChromeRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Google"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for Google software
#

#
# Google drive
#

# Test if installation exists on system
if ((Confirm-Installation "GoogleDrive" ([ref] $GoogleDriveRoot)) -or $ForceLoad)
{
	# Found path contains executable name so we remove it
	$GoogleDriveRoot = $(Split-Path -Path $GoogleDriveRoot -Parent)

	$Program = "$GoogleDriveRoot\GoogleDriveFS.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Google drive" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Google drive synchronization service" | Format-RuleOutput
	}
}

#
# Google play emulator
#

if ((Confirm-Installation "GooglePlay" ([ref] $GooglePlayRoot)) -or $ForceLoad)
{
	$Program = "$GooglePlayRoot\current\service\Service.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Google Play - service" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	$Program = "$GooglePlayRoot\current\client\client.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Google Play - client" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	New-NetFirewallRule -DisplayName "Google Play - client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-InterfaceType $DefaultInterface `
		-Description "" | Format-RuleOutput

	$Program = "$GooglePlayRoot\current\emulator\crosvm.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Google Play - crosvm" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443, 853, 5228 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	New-NetFirewallRule -DisplayName "Google Play - crosvm" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 123, 443 `
		-LocalUser $UsersGroupSDDL `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-InterfaceType $DefaultInterface `
		-Description "" | Format-RuleOutput
}

#
# Google Chrome
#

# Test if installation exists on system
if ((Confirm-Installation "Chrome" ([ref] $ChromeRoot)) -or $ForceLoad)
{
	$Program = "$ChromeRoot\chrome.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Chrome HTTP\S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome GCM" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5228 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Google cloud messaging, google services use 5228, hangouts, google play,
GCP.. etc use 5228." | Format-RuleOutput

		# TODO: removed port 80, probably not used
		New-NetFirewallRule -DisplayName "Chrome QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome XMPP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5222 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Extensible Messaging and Presence Protocol.
Google Drive (Talk), Cloud printing, Chrome Remote Desktop, Chrome Sync
(with fallback to 443 if 5222 is blocked)." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome mDNS IPv4" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 224.0.0.251 `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses
within small networks that do not include a local name server." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome mDNS IPv6" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress ff02::fb `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses
within small networks that do not include a local name server." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast SSDP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 239.255.255.250 `
			-LocalPort Any -RemotePort 1900 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Network Discovery to allow use of the Simple Service Discovery Protocol." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString `
			-LocalPort Any -RemotePort 8008, 8009 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Allow Chromecast outbound TCP data" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString `
			-LocalPort 32768-61000 -RemotePort 32768-61000 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Allow Chromecast outbound UDP data" | Format-RuleOutput

		#
		# IRC: 8605
		# Pokerist: 3103-3110
		# speedtest: 5060, 8080
		#
		New-NetFirewallRule -DisplayName "Chrome special sites" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3103-3110, 5060, 8080, 8605 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Ports needed for IRC, pokerist.com and speedtest.net" | Format-RuleOutput
	}

	# If Chrome is installed in user profile it has it's own GoogleUpdate with different user permission
	if ($ChromeRoot -like "*\Users\*")
	{
		# TODO: we should probably have a function for this and similar cases?
		$ChromeUpdateRoot = $(Split-Path -Path $(Split-Path -Path $ChromeRoot -Parent) -Parent)

		# Test if installation exists on system
		if ((Confirm-Installation "GoogleUpdate" ([ref] $GoogleUpdateRoot)) -or $ForceLoad)
		{
			$Program = "$ChromeUpdateRoot\Update\GoogleUpdate.exe"
			if ((Test-ExecutableFile $Program) -or $ForceLoad)
			{
				# TODO: Unsure is SYSTEM account is needed by Google update
				# Merge-SDDL ([ref] $UpdateAccounts) -From $UsersGroupSDDL

				New-NetFirewallRule -DisplayName "Google Update" `
					-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
					-Service Any -Program $Program -Group $Group `
					-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
					-LocalAddress Any -RemoteAddress Internet4 `
					-LocalPort Any -RemotePort 80, 443 `
					-LocalUser $UsersGroupSDDL `
					-InterfaceType $DefaultInterface `
					-Description "Update google products" | Format-RuleOutput
			}
		}
	}
}

#
# Google update
#
# This rule must the the last one in this script so that GoogleUpdateRoot is set to correct path to handle
# cases where GoogleUpdate is installed into user profile because Search-Installation set system wide path
#

# Test if installation exists on system
if ((Confirm-Installation "GoogleUpdate" ([ref] $GoogleUpdateRoot)) -or $ForceLoad)
{
	$Program = "$GoogleUpdateRoot\GoogleUpdate.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# TODO: Unsure is Users account is needed by Google update
		# Merge-SDDL ([ref] $UpdateAccounts) -From $UsersGroupSDDL

		New-NetFirewallRule -DisplayName "Google Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "Update google products" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Outbound firewall rules for sysinternals

.DESCRIPTION
Outbound firewall rules for sysinternals software suite

.EXAMPLE
PS> .\SysInternals.ps1

.INPUTS
None. You cannot pipe objects to SysInternals.ps1

.OUTPUTS
None. SysInternals.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft - SysInternals"
$SysInternalsUsers = Get-SDDL -Group "Users", "Administrators"
$Accept = "Outbound rules for SysInternals software will be loaded, recommended if SysInternals software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for SysInternals software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# SysInternals installation directories
#
$SysInternalsRoot = "Unknown path" #"%SystemDrive%\tools"

#
# Rules for SysInternals
#

# Test if installation exists on system
if ((Test-Installation "SysInternals" ([ref] $SysInternalsRoot)) -or $ForceLoad)
{
	$Program = "$SysInternalsRoot\Autoruns\Autoruns64.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals Autoruns" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "Access to VirusTotal" | Format-Output

	# TODO: It also uses port 80 but not known for what, not setting here.
	# Most likely to fetch symbols
	$Program = "$SysInternalsRoot\ProcessExplorer\procexp64.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals ProcessExplorer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "Access to VirusTotal" | Format-Output

	$Program = "$SysInternalsRoot\ProcessMonitor\Procmon.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals ProcessMonitor" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "Access to symbols server" | Format-Output

	$Program = "$SysInternalsRoot\TCPView\Tcpview.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals TcpView" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 43 `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "WhoIs access" | Format-Output

	$Program = "$SysInternalsRoot\WhoIs\whois64.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals WhoIs" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 43 `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "WhoIs performs the registration record for the domain name or IP address
that you specify" | Format-Output

	$Program = "$SysInternalsRoot\PSTools\psping.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals PSPing client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing.exe to act as a client." | Format-Output

	$Program = "$SysInternalsRoot\PSTools\psping64.exe"
	Test-File $Program
	New-NetFirewallRule -DisplayName "Sysinternals PSPing64 client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser $SysInternalsUsers `
		-InterfaceType $DefaultInterface `
		-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing64.exe to act as a client." | Format-Output
}

Update-Log

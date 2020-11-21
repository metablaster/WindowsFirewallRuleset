
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
Outbound firewall rules for

.DESCRIPTION

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
$SysInternalsRoot = "%SystemDrive%\tools"

#
# Rules for SysInternals
#

# Test if installation exists on system
if ((Test-Installation "SysInternals" ([ref] $SysInternalsRoot)) -or $ForceLoad)
{
	$Program = "$SysInternalsRoot\Autoruns\Autoruns64.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Sysinternals Autoruns" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-Description "Access to VirusTotal" | Format-Output

	# TODO: It also uses port 80 but not known for what, not setting here.
	# Most likely to fetch symbols
	$Program = "$SysInternalsRoot\ProcessExplorer\procexp64.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Sysinternals ProcessExplorer" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-Description "Access to VirusTotal" | Format-Output

	$Program = "$SysInternalsRoot\ProcessMonitor\Procmon.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Sysinternals ProcessMonitor" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $SysInternalsUsers `
		-Description "Access to symbols server" | Format-Output

	$Program = "$SysInternalsRoot\TCPView\Tcpview.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Sysinternals TcpView" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 43 `
		-LocalUser $SysInternalsUsers `
		-Description "WhoIs access" | Format-Output

	$Program = "$SysInternalsRoot\WhoIs\whois64.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Sysinternals WhoIs" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 43 `
		-LocalUser $SysInternalsUsers `
		-Description "" | Format-Output
}

Update-Log

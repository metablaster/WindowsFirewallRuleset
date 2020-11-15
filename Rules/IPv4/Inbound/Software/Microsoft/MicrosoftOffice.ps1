
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

. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft Office"
$FirewallProfile = "Private, Public"
$Accept = "Inbound rules for Microsoft Office will be loaded, recommended if Microsoft Office is installed to let it access to network"
$Deny = "Skip operation, inbound rules for Microsoft Office will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles%\Microsoft Office\root\Office16"

#
# Microsoft office rules
#

# Test if installation exists on system
if ((Test-Installation "MicrosoftOffice" ([ref] $OfficeRoot) @Logs) -or $ForceLoad)
{
	$Program = "$OfficeRoot\OUTLOOK.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Outlook" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort 6004 -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" @Logs | Format-Output @Logs

	# TODO: Skype for business has complex port requirements, see:
	# https://docs.pexip.com/sfb/ports.htm
	# https://docs.microsoft.com/en-us/skypeforbusiness/plan-your-deployment/network-requirements/ports-and-protocols
	$Program = "$OfficeRoot\lync.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Skype for business" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "Skype for business, previously lync." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Skype for business" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Skype for business, previously lync." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\UcMapi.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "UcMapi" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "Unified Communications Messaging Application Programming Interface" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "UcMapi" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $DefaultInterfaceterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Unified Communications Messaging Application Programming Interface" @Logs | Format-Output @Logs
}

Update-Log

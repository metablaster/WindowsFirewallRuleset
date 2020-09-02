
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

#
# Setup local variables
#
$Group = "Software - Adobe"
$FirewallProfile = "Private, Public"
$Accept = "Outbound rules for Adobe software will be loaded, recommended if Adobe software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Adobe software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

#
# Adobe installation directories
#
$AdobeARMRoot = "%ProgramFiles(x86)%\Common Files\Adobe\ARM\1.0"
$AcrobatRoot = "%ProgramFiles(x86)%\Adobe\Acrobat Reader DC\Reader"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Rules for Adobe
#

# Test if installation exists on system
if ((Test-Installation "AdobeAcrobat" ([ref] $AcrobatRoot) @Logs) -or $ForceLoad)
{
	$Program = "$AcrobatRoot\AcroRd32.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Acrobat Reader" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" @Logs | Format-Output @Logs
}

# Test if installation exists on system
if ((Test-Installation "AdobeARM" ([ref] $AdobeARMRoot) @Logs) -or $ForceLoad)
{
	$Program = "$AdobeARMRoot\AdobeARM.exe.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Acrobat ARM" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "" @Logs | Format-Output @Logs
}

Update-Log

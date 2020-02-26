
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Microsoft - Office"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles%\Microsoft Office\root\Office16"
$OfficeShared = "%ProgramFiles%\Common Files\microsoft shared"

#
# Microsoft office rules
#

# Test if installation exists on system
if ((Test-Installation "MicrosoftOffice" ([ref] $OfficeRoot) @Logs) -or $ForceLoad)
{
	$Program = "$OfficeRoot\MSACCESS.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Access" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	# Clicktorun.exe starts downloading the most recent version of itself.
	# After finishing the download Clicktorun.exe starts THE DOWNLOADED Version which then downloads the new office version.
	# For some odd fucking reason the downloaded clicktorun wants to communicate with ms servers directly completely ignoring the proxy.
	# https://www.reddit.com/r/sysadmin/comments/7hync7/updating_office_2016_hb_click_to_run_through/
	# TL;DR: netsh winhttp set proxy proxy-server="fubar" bypass-list="<local>"
	$Program = "$OfficeShared\ClickToRun\OfficeClickToRun.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Click to Run" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $NT_AUTHORITY_System `
	-Description "Required for updates to work. Click-to-Run is an alternative to the traditional Windows Installer-based (MSI) method
	of installing and updating Office, that utilizes streaming and virtualization technology
	to reduce the time required to install Office and help run multiple versions of Office on the same computer." @Logs | Format-Output @Logs

	$Program = "$OfficeShared\ClickToRun\OfficeC2RClient.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "ClickC2RClient" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_System `
	-Description "Allows users to check for and install updates for Office on demand." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\MSOSYNC.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Document Cache" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "The Office Document Cache is a concept used in Microsoft Office Upload Center
	to give you a way to see the state of files you are uploading to a SharePoint server. " @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\EXCEL.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Excel" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Mashup.Container.NetFX40.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Excel (Mashup Container)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "Used to query data from web in excel." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\CLVIEW.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Help" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\OUTLOOK.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (HTTP/S)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (IMAP SSL)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 993 `
	-LocalUser $UsersSDDL `
	-Description "Incoming mail server over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (IMAP)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 143 `
	-LocalUser $UsersSDDL `
	-Description "Incoming mail server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (POP3 SSL)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 110 `
	-LocalUser $UsersSDDL `
	-Description "Incoming mail server over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (POP3)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 995 `
	-LocalUser $UsersSDDL `
	-Description "Incoming mail server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Outlook (SMTP)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 25 `
	-LocalUser $UsersSDDL `
	-Description "Outgoing mail server." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\POWERPNT.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerPoint" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\WINPROJ.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Project" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\MSPUB.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Publisher" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\SDXHelper.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "sdxhelper" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "this executable is used when later Office versions are installed in parallel with an earlier version so that they can peacefully coexist." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\lync.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Skype for business" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443, 33033 `
	-LocalUser $UsersSDDL `
	-Description "Skype for business, previously lync." @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\msoia.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Telemetry Agent" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "The telemetry agent collects several types of telemetry data for Office.
	https://docs.microsoft.com/en-us/deployoffice/compat/data-that-the-telemetry-agent-collects-in-office" @Logs | Format-Output @Logs

	# TODO: Visio and Project are not part of office by default
	$Program = "$OfficeRoot\VISIO.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Visio" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs

	$Program = "$OfficeRoot\WINWORD.EXE"
	Test-File $Program @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Word" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" @Logs | Format-Output @Logs
}

Update-Logs

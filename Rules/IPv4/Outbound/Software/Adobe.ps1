
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Outbound firewall rules for Adobe

.DESCRIPTION
Outbound firewall rules for software from Adobe

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\Adobe.ps1

.INPUTS
None. You cannot pipe objects to Adobe.ps1

.OUTPUTS
None. Adobe.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - Adobe"
$Accept = "Outbound rules for Adobe software will be loaded, recommended if Adobe software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Adobe software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

#
# Adobe installation directories
#
$AdobeARMRoot = "%ProgramFiles(x86)%\Common Files\Adobe\ARM\1.0"
$AcrobatRoot = "%ProgramFiles(x86)%\Adobe\Acrobat DC"
$ReaderRoot = "%ProgramFiles(x86)%\Adobe\Acrobat Reader DC"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for Adobe
#

# Test if installation exists on system
if ((Confirm-Installation "AdobeReader" ([ref] $ReaderRoot)) -or $ForceLoad)
{
	$Program = "$ReaderRoot\Reader\AcroRd32.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Adobe Reader" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-Output
	}

	$Program = "$ReaderRoot\Reader\AcroCEF\RdrCEF.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Adobe Reader cloud services" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "RdrCEF.exe is inseparable processes of Adobe Reader.
It handles multiple integral aspects of application like network interaction and
Document Cloud services like Fill and Sign, Send For Signature, Share for view/review, and so on)" |
		Format-Output
	}
}

# Test if installation exists on system
if ((Confirm-Installation "AdobeAcrobat" ([ref] $AcrobatRoot)) -or $ForceLoad)
{
	$Program = "$AcrobatRoot\Acrobat\Acrobat.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Adobe Acrobat Pro" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-Output
	}

	$Program = "$AcrobatRoot\Acrobat\AcroCEF\AcroCEF.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Adobe Acrobat Pro cloud services" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "AcroCEF.exe is inseparable processes of Acrobat Reader.
It handles multiple integral aspects of application like network interaction and
Document Cloud services like Fill and Sign, Send For Signature, Share for view/review, and so on)" |
		Format-Output
	}

	# TODO: This is workaround, see todo comment in Programinfo.psm1, separate search needed
	$Program = "%SystemDrive%\Program Files (x86)\Common Files\Adobe\AdobeGCClient\AdobeGCClient.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Adobe Genuine Software Integrity" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Adobe Genuine Software Integrity Service" |
		Format-Output
	}
}

# Test if installation exists on system
if ((Confirm-Installation "AdobeARM" ([ref] $AdobeARMRoot)) -or $ForceLoad)
{
	$Program = "$AdobeARMRoot\AdobeARM.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Acrobat ARM" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Adobe updater is responsible for checking for, downloading, and launching the
update installer for Reader or Acrobat.
The Updater primarily keeps itself up to date and downloads and extracts needed files.
It does not actually install anything, as that job is handled by a separate installer" | Format-Output
	}
}

Update-Log

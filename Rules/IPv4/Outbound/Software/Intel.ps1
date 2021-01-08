
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
Outbound firewall rules for Intel

.DESCRIPTION
Outbound firewall rules for Intel related software

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\Intel.ps1

.INPUTS
None. You cannot pipe objects to Intel.ps1

.OUTPUTS
None. Intel.ps1 does not generate any output

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
$Group = "Software - Intel"
$Accept = "Outbound rules for Intel software will be loaded, recommended if Intel software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Intel software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

#
# Intel installation directories
#
$IntelXTURoot = "%ProgramFiles(x86)%\Intel\Intel(R) Extreme Tuning Utility\Client"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for Intel software
# NOTE: these are rules for update checks, since these are ran as Administrator they disabled by default
#

# Test if installation exists on system
if ((Confirm-Installation "XTU" ([ref] $IntelXTURoot)) -or $ForceLoad)
{
	$Program = "$IntelXTURoot\PerfTune.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Extreme tuning utility" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $AdminGroupSDDL `
			-Description "Extreme Tuning utility check for updates" | Format-Output
	}
}

# TODO: Confirm-Installation is missing
$Program = "%ProgramFiles(x86)%\Intel\Telemetry 2.0\lrio.exe"
if (Test-ExecutableFile $Program)
{
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Intel telemetry" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $LocalSystem `
		-Description "Uploader for the Intel(R) Product Improvement Program." | Format-Output
}

# TODO: port and protocol unknown for Intel PTT EK Recertification
$Program = "%ProgramFiles%\Intel\Intel(R) Management Engine Components\iCLS\IntelPTTEKRecertification.exe"
if (Test-ExecutableFile $Program)
{
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Intel PTT EK Recertification" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-LocalUser $LocalSystem `
		-Description "" | Format-Output
}

Update-Log


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Outbound rule for Bing wallpaper app

.DESCRIPTION
Outbound rule for Bing Wallpaper app

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\BingWallpaper.ps1

.INPUTS
None. You cannot pipe objects to BingWallpaper.ps1

.OUTPUTS
None. BingWallpaper.ps1 does not generate any output

.NOTES
TODO: Search algorithms can't find this program
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
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1

# Setup local variables
$Group = "Microsoft - Bing wallpaper"

# User prompt
$Accept = "Outbound rule for bing wallpaper app will be loaded"
$Deny = "Skip operation, outbound rule for bing wallpaper app will not be loaded"
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

# BingWallpaper App installation directories
$BingWallpaperRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Microsoft\BingWallpaperApp"

#
# Rules for Bing Wallpaper App
#

# Test if installation exists on system
if ((Confirm-Installation "BingWallpaper" ([ref] $BingWallpaperRoot)) -or $ForceLoad)
{
	$Program = "$BingWallpaperRoot\BingWallpaperApp.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "Bing wallpaper" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Bing wallpaper needs internet to download fresh wallpapers" |
		Format-Output
	}
}

Update-Log

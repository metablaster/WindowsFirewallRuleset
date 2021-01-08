
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
Unit test for Set-Shortcut

.DESCRIPTION
Unit test to test correctness of Set-Shortcut function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Set-Shortcut.ps1

.INPUTS
None. You cannot pipe objects to Set-Shortcut.ps1

.OUTPUTS
None. Set-Shortcut.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Strict
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\..\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test

$TestDrive = "$DefaultTestDrive\$ThisScript"
$Restricted = "$env:SystemDrive\Windows"

if (!(Test-Path -Path $TestDrive -PathType Container))
{
	New-Item -Path $TestDrive -ItemType Container | Out-Null
}

Start-Test "LNK"
Set-Shortcut -Name "Test.url" -Path $TestDrive -IconIndex -19 -Hotkey "ALT+CTRL+F" `
	-TargetPath "$ProjectRoot\Config\Windows\Firewall.msc" `
	-Description "View and modify GPO firewall" -ArgumentList "/test /args" `
	-WorkingDirectory "$ProjectRoot\Config\Windows" `
	-WindowStyle "Maximized" -IconLocation "$env:SystemDrive\Windows\System32\Shell32.dll" -Admin

Start-Test "URL"
$Result = Set-Shortcut -Name "online.lnk" -Path $TestDrive -IconIndex -19 `
	-URL "https://docs.microsoft.com" -Hotkey "ALT+CTRL+F" `
	-IconLocation "$env:SystemDrive\Windows\System32\Shell32.dll"

$Result

Start-Test "System location"
if ($Force -or $PSCmdlet.ShouldContinue("Windows folder", "Test elevation"))
{
	if ($false)
	{
		# TODO: Set restricted test drive
		if (!(Test-Path -Path $Restricted -PathType Container))
		{
			New-Item -Path $Restricted -ItemType Container | Out-Null
		}

		[System.Security.AccessControl.FileSystemRights] $Access = "FullControl"

		# Test ownership
		Start-Test "Set-Permission ownership"
		Set-Permission -Owner $TestAdmin -Path $Restricted -Recurse

		# Reset existing tree for re-test
		Start-Test "Reset existing tree"
		Set-Permission -Principal $TestAdmin -Path $Restricted -Reset -Grant $Access
	}

	Set-Shortcut -Name "Test.lnk" -Path $Restricted `
		-TargetPath "$ProjectRoot\Config\Windows\Firewall.msc"
}

Test-Output $Result -Command Set-Shortcut

Update-Log
Exit-Test

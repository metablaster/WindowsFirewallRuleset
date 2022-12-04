
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Unit test for rules with relative path

.DESCRIPTION
Unit test for adding rules based on relative paths.
Also serves to test adding rule based on application.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\RuleRelativePath.ps1

.INPUTS
None. You cannot pipe objects to RuleRelativePath.ps1

.OUTPUTS
None. RuleRelativePath.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept "Load test rule into firewall" -Deny $Deny -Force:$Force)) { exit }

# Setup local variables
$Group = "Test - Relative path"
$LocalProfile = "Any"
$TargetProgramRoot = "C:\Program Files (x86)\GnuPG\share\..\bin"

Enter-Test

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

Start-Test "Relative path"

# Test if installation exists on system
$Program = "$TargetProgramRoot\gpg.exe"
if ((Test-ExecutableFile $Program) -or $ForceLoad)
{
	New-NetFirewallRule -DisplayName "TargetProgram" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443, 26002 `
		-LocalUser $LocalService `
		-InterfaceType $DefaultInterface `
		-Description "Relative path test" |
	Format-RuleOutput
}

Update-Log
Exit-Test

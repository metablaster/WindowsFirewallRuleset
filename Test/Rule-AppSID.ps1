
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

#
# Unit test for adding rules for store apps based on computer users
#

#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# User prompt
Set-Variable -Name Accept -Scope Local -Option ReadOnly -Force -Value "Load test rule into firewall"
Update-Context $TestContext "IPv$IPVersion" $Direction
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# Setup local variables
$Group = "Test - AppSID"
$FirewallProfile = "Any"

Enter-Test $ThisScript

Start-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

Start-Test "Get-GroupPrincipal"
$Principals = Get-GroupPrincipal "Users" @Logs
$Principals

[string] $PackageSID = ""
[string] $OwnerSID = ""
foreach ($Principal in $Principals)
{
	Start-Test "Processing for: $($Principal.Account)"
	$OwnerSID = Get-AccountSID $Principal.User -Computer $Principal.Computer @Logs
	$OwnerSID

	Get-UserApps -User $Principal.User | ForEach-Object {
		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName
		$PackageSID
	} @Logs
}

Start-Test "New-NetFirewallRule"

New-NetFirewallRule -DisplayName "Get-AppSID" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Owner $OwnerSID -Package $PackageSID `
	-Description "TargetProgram test rule description" `
	@Logs | Format-Output @Logs

Update-Log
Exit-Test

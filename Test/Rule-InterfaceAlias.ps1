
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
# Unit test for interface alias rules
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

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute @Logs)) { exit }

#
# Setup local variables
#
$Group = "Test - Interface aliases"
$FirewallProfile = "Any"

Enter-Test $ThisScript

Start-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

Start-Test "Virtual adapter rule no wildcard"
$VirtualAdapter = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware

# Outbound rule to test virtual adapter rule
New-NetFirewallRule -DisplayName "Virtual adapter rule no wildcard" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $VirtualAdapter.ToWql() `
	-Description "Virtual adapter rule without WildcardPattern" `
	@Logs | Format-Output @Logs

Start-Test "Virtual adapter rule CultureInvariant"
$VirtualAdapterCultureInvariant = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware -WildCardOption CultureInvariant

# Outbound rule to test virtual adapter rule
New-NetFirewallRule -DisplayName "Virtual adapter rule CultureInvariant" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $VirtualAdapterCultureInvariant `
	-Description "Virtual adapter rule using WildcardPattern" `
	@Logs | Format-Output @Logs

Start-Test "Virtual adapter rule IgnoreCase"
$VirtualAdapterIgnoreCase = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware -WildCardOption IgnoreCase

# Outbound rule to test virtual adapter rule
New-NetFirewallRule -DisplayName "Virtual adapter rule IgnoreCase" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $VirtualAdapterIgnoreCase `
	-Description "Virtual adapter rule using WildcardPattern" `
	@Logs | Format-Output @Logs

Start-Test "Virtual adapter rule None"
$VirtualAdapterNone = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware -WildCardOption None

# Outbound rule to test virtual adapter rule
New-NetFirewallRule -DisplayName "Virtual adapter rule None" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $VirtualAdapterNone `
	-Description "Virtual adapter rule using WildcardPattern" `
	@Logs | Format-Output @Logs

Start-Test "Virtual adapter rule Compiled"
$VirtualAdapterCompiled = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware -WildCardOption Compiled

# Outbound rule to test virtual adapter rule
New-NetFirewallRule -DisplayName "Virtual adapter rule Compiled" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $VirtualAdapterCompiled `
	-Description "Virtual adapter rule using WildcardPattern" `
	@Logs | Format-Output @Logs

Start-Test "Hardware adapter rule"
$HardwareAdapter = Get-InterfaceAlias IPv4

# Outbound rule to test hardware adapter rule
New-NetFirewallRule -DisplayName "Hardware adapter rule" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $HardwareAdapter `
	-Description "Hardware test rule description" `
	@Logs | Format-Output @Logs

Start-Test "Multiple adapters rule"
$MultipleAdapters = Get-InterfaceAlias IPv4 -IncludeAll

# Outbound rule to test hardware adapter rule
New-NetFirewallRule -DisplayName "Multiple adapters rule" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $MultipleAdapters `
	-Description "Multiple test rule description" `
	@Logs | Format-Output @Logs

Start-Test "Bad adapter rule FAILURE TEST"
$BadAdapters = Get-InterfaceAlias IPv4 -IncludeAll
$BadAdapters += [WildcardPattern]("Local Area Connection* 644")

# Outbound rule to test nonexistent adapter rule
New-NetFirewallRule -DisplayName "Bad adapter rule" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceAlias $BadAdapters `
	-Description "Bad adapter test rule description" `
	@Logs -ErrorAction SilentlyContinue | Format-Output @Logs

Update-Log
Exit-Test

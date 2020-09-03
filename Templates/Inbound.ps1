
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Script for inbound rule set
.DESCRIPTION
Use Inbound.ps1 as a template for inbound firewall rule set
.INPUTS
None. You cannot pipe objects to Inbound.ps1.
.OUTPUTS
None. Inbound.ps1 does not generate any output.
.NOTES
None.
TODO: Update Copyright and start writing test code
.LINK
None.
#>

# Initialization
# TODO: Adjust path to project settings
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
# TODO: adjust paths
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Setup local variables
$Group = "Template - TargetProgram"
$FirewallProfile = "Private, Public"
$PackageSID = "*"

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Skip operation, template deny help message"
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

# TargetProgram installation directories
$TargetProgramRoot = "%ProgramFiles%\TargetProgram"

#
# Rules for TargetProgram
#

# Test if installation exists on system
if ((Test-Installation "TargetProgram" ([ref] $TargetProgramRoot) @Logs) -or $ForceLoad)
{
	$Program = "$TargetProgramRoot\Steam.exe"
	Test-File $Program @Logs

	# Following lines/options are not used:
	# -Name (if used then on first line, DisplayName should be adjusted for 100 col. line)
	# -RemoteUser $RemoteUser -RemoteMachine $RemoteMachine
	# -Authentication NotRequired -Encryption NotRequired -OverrideBlockRules False
	# -InterfaceAlias "loopback" (if used, goes on line with InterfaceType)

	# Following lines/options are used only where appropriate:
	# LocalOnlyMapping $false -LooseSourceMapping $false
	# -Owner $PrincipalSID -Package $PackageSID

	# Inbound TCP template
	New-NetFirewallRule -DisplayName "Inbound TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $Interface `
		-Description "Inbound TCP template description" `
		@Logs | Format-Output @Logs

	# Inbound UDP template
	New-NetFirewallRule -DisplayName "Inbound UDP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Inbound UDP template description" `
		@Logs | Format-Output @Logs

	# Inbound ICMP template
	New-NetFirewallRule -DisplayName "Inbound ICMP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
		-LocalAddress Any -RemoteAddress Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $Interface `
		-Description "Inbound ICMP template description" `
		@Logs | Format-Output @Logs

	# Inbound StoreApp TCP template
	New-NetFirewallRule -DisplayName "Inbound StoreApp TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $Interface `
		-Owner $PrincipalSID -Package $PackageSID `
		-Description "Inbound StoreApp TCP template description" `
		@Logs | Format-Output @Logs
}

Update-Log

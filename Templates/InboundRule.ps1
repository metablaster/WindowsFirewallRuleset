
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
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
Inbound firewall rules template

.DESCRIPTION
Detailed descritpion of this inbound rule group and involved programs and services including
their networking requirements.

.PARAMETER Force
If specified, the script runs without prompt to allow execute

.EXAMPLE
PS> .\InboundRule.ps1

.INPUTS
None. You cannot pipe objects to InboundRule.ps1

.OUTPUTS
None. InboundRule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
# TODO: Adjust path to project settings
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Strict

# Imports
# TODO: adjust path
. $PSScriptRoot\DirectionSetup.ps1

# Setup local variables
$Group = "Template - TargetProgram"
$PackageSID = "*"
$PrincipalSID = Get-PrincipalSID $DefaultUser

# User prompt
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Skip operation, template deny help message"
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

# TargetProgram installation directories
$TargetProgramRoot = "%ProgramFiles%\TargetProgram"

#
# Rules for TargetProgram
#

# Test if installation exists on system
if ((Confirm-Installation "TargetProgram" ([ref] $TargetProgramRoot)) -or $ForceLoad)
{
	# Following lines/options are not used:
	# -Name (if used then on first line, DisplayName should be adjusted for 100 col. line)
	# -RemoteUser $RemoteUser -RemoteMachine $RemoteMachine
	# -Authentication NotRequired -Encryption NotRequired -OverrideBlockRules False
	# -InterfaceAlias "loopback" (if used, goes on line with InterfaceType)

	# Following lines/options are used only where appropriate:
	# LocalOnlyMapping $false -LooseSourceMapping $false
	# -Owner $PrincipalSID -Package $PackageSID

	$Program = "$TargetProgramRoot\TargetProgram.exe"
	if (Test-ExecutableFile $Program)
	{
		# Inbound TCP template
		New-NetFirewallRule -DisplayName "Inbound TCP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Inbound TCP template description" |
		Format-Output

		# Inbound UDP template
		New-NetFirewallRule -DisplayName "Inbound UDP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Inbound UDP template description" |
		Format-Output

		# Inbound ICMP template
		New-NetFirewallRule -DisplayName "Inbound ICMP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Inbound ICMP template description" |
		Format-Output
	}

	# Inbound StoreApp TCP template
	New-NetFirewallRule -DisplayName "Inbound StoreApp TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-Owner $PrincipalSID -Package $PackageSID `
		-Description "Inbound StoreApp TCP template description" |
	Format-Output
}

Update-Log

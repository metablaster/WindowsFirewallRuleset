
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
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
Outbound firewall rules template

.DESCRIPTION
Detailed descritpion of this outbound rule group and involved programs and services including
their networking requirements.

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> OutboundRule

.INPUTS
None. You cannot pipe objects to OutboundRule.ps1

.OUTPUTS
None. OutboundRule.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
# TODO: Adjust paths to ProjectSettings and DirectionSetup
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\DirectionSetup.ps1

# Setup local variables
$Group = "Template - TargetProgram"
$PackageSID = "*"
$PrincipalSID = (Get-PrincipalSID $DefaultUser).SID
# TODO: Update command line help messages
$Accept = "Template accept help message"
$Deny = "Skip operation, template deny help message"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
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
	# The following lines/options are not used:
	# -Name (if used then on first line, DisplayName should be adjusted for 100 col. line)
	# -RemoteUser $RemoteUser -RemoteMachine $RemoteMachine
	# -Authentication NotRequired -Encryption NotRequired -OverrideBlockRules False
	# -InterfaceAlias "loopback" (if used, goes on line with InterfaceType)

	# The following lines/options are used only where appropriate:
	# LocalOnlyMapping $false -LooseSourceMapping $false
	# -Owner $PrincipalSID -Package $PackageSID

	$Program = "$TargetProgramRoot\TargetProgram.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# Outbound TCP template
		New-NetFirewallRule -DisplayName "Outbound TCP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-Description "Outbound TCP template description" |
		Format-RuleOutput

		# Outbound UDP template
		New-NetFirewallRule -DisplayName "Outbound UDP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Outbound UDP template description" |
		Format-RuleOutput

		# Outbound ICMP template
		New-NetFirewallRule -DisplayName "Outbound ICMP template" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-Description "Outbound ICMP template description" |
		Format-RuleOutput
	}

	# Outbound StoreApp TCP template
	New-NetFirewallRule -DisplayName "Outbound StoreApp TCP template" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Owner $PrincipalSID -Package $PackageSID `
		-Description "Outbound StoreApp TCP template description" |
	Format-RuleOutput
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

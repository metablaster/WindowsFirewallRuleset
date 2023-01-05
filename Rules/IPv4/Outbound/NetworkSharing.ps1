
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Outbound firewall rules for File and Printer sharing predefined rules

.DESCRIPTION
Outbound rules for File and Printer sharing predefined rules
Rules which apply to network sharing on LAN

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\NetworkSharing.ps1

.INPUTS
None. You cannot pipe objects to NetworkSharing.ps1

.OUTPUTS
None. NetworkSharing.ps1 does not generate any output

.NOTES
HACK: Due to some magic with predefines rules these rules here don't work for home network setup (WORKGROUP)
Same applies to "Network Discovery" predefined rules.
See exported rules, possible cause is rule name and rule display name.
Current workaround for home networks is to apply predefined "File and Printer sharing" rules into GPO.

NOTE: NETBIOS Name and datagram, LLMNR and ICMP rules required for network sharing which are part
of predefined rules are duplicate of Network Discovery equivalent rules

TODO: Intranet4 and Intranet4, removed IPv4 restriction to troubleshoot homegroup
HACK: Changing network profile in UI will not enable required rules as it is the case with CP fireall
A possible solution is have a function which sets firewall profile and togles rules as needed.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "@FirewallAPI.dll,-28502"
$DisplayGroup = "File and Printer Sharing"
$Accept = "Outbound rules for network sharing will be loaded, required to share resources in local networks"
$Deny = "Skip operation, outbound network sharing rules will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $DisplayGroup -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $Group -Direction $Direction -NewPolicyStore $PolicyStore

# Enable\disable rules depending on network profiles currently used on target computer
$CurrentProfile = Invoke-Command -Session $SessionInstance -ScriptBlock {
	@(Get-NetConnectionProfile | Select-Object -ExpandProperty NetworkCategory) -replace "DomainAuthenticated", "Domain"
}

Get-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction | ForEach-Object {
	$_ | Format-RuleOutput -Label Modify
	[hashtable] $Params = @{
		InputObject = $_
		Enabled = "False"
		LocalUser = "Any"
		# NOTE: Requires allowing loopback and multicast elsewhere
		InterfaceType = $DefaultInterface
	}

	# If profile defined in rule matches currently used profiles used enable rule
	# [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Profile]
	foreach ($RuleProfile in $_.Profile.ToString().Split(", "))
	{
		if ($RuleProfile -in $CurrentProfile)
		{
			$Params["Enabled"] = "True"
			break
		}
	}

	if ((Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_).Program -eq "System")
	{
		$Params["LocalUser"] = $LocalSystem
	}

	Set-NetFirewallRule @Params
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

# NOTE: The following rules are no longer relevant
return

#
# File and Printer sharing predefined rules
# TODO: separate custom rules with comment
#

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort Any -RemotePort 139 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort Any -RemotePort 139 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort Any -RemotePort 139 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort Any -RemotePort 445 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort Any -RemotePort 445 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort Any -RemotePort 445 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

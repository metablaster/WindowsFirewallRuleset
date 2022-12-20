
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Inbound firewall rules for File and Printer sharing predefined rules

.DESCRIPTION
Inbound rules for File and Printer sharing predefined rules
Rules which apply to network sharing on LAN

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
Same applies to "Network Discovery" predefined rules
See exported rules, possible cause is rule name and rule display name.

NOTE: Current workaround for home networks is to apply predefined "File and Printer sharing" rules into GPO.
NOTE: NETBIOS Name and datagram, LLMNR and ICMP rules required for network sharing which are part
of predefined rules are duplicate of Network Discovery equivalent rules

TODO: Intranet4 and Intranet4 removed IPv4 restriction to troubleshoot homegroup
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "@FirewallAPI.dll,-28502"
$DisplayGroup = "File and Printer Sharing"
# $LocalProfile = "Private, Domain"
$Accept = "Inbound rules for network sharing will be loaded, required to share resources in local networks"
$Deny = "Skip operation, inbound network sharing rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $DisplayGroup -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $Group -Direction $Direction -NewPolicyStore $PolicyStore

Get-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction | ForEach-Object {
	$_ | Format-RuleOutput -Label Modify
	[hashtable] $Params = @{
		InputObject = $_
		Enabled = "True"
		LocalUser = "Any"
		# NOTE: Requires allowing loopback and multicast elsewhere
		InterfaceType = $DefaultInterface
	}

	if ($_.Profile -eq "Domain")
	{
		$Params["Enabled"] = "False"
	}

	if ((Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_).Program -eq "System")
	{
		$Params["LocalUser"] = $LocalSystem
	}

	Set-NetFirewallRule @Params
}

# NOTE: The following rules are no longer relevant
return

#
# File and Printer sharing predefined rules
# TODO: separate custom rules with comment
#

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 139 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 139 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "NetBIOS Session" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 139 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow NetBIOS Session Service connections." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMB" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow Server Message Block transmission and
reception via Named Pipes." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC)" `
	-Service Spooler -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort RPC -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow the Print Spooler Service to
communicate via TCP/RPC.
Spooler service spools print jobs and handles interaction with the printer.
If you disable this rule, you won't be able to print or see your printers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC)" `
	-Service Spooler -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort RPC -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow the Print Spooler Service to
communicate via TCP/RPC.
Spooler service spools print jobs and handles interaction with the printer.
If you disable this rule, you won't be able to print or see your printers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC)" `
	-Service Spooler -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet `
	-LocalPort RPC -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing to allow the Print Spooler Service to
communicate via TCP/RPC.
Spooler service spools print jobs and handles interaction with the printer.
If you disable this rule, you won't be able to print or see your printers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC-EPMAP)" `
	-Service RpcSs -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort RPCEPMap -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for the RPCSS service to allow RPC/TCP traffic for the Spooler Service.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC-EPMAP)" `
	-Service RpcSs -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort RPCEPMap -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for the RPCSS service to allow RPC/TCP traffic for the Spooler Service.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Spooler Service (RPC-EPMAP)" `
	-Service RpcSs -Program $ServiceHost -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet `
	-LocalPort RPCEPMap -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-Description "Rule for the RPCSS service to allow RPC/TCP traffic for the Spooler Service.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMBDirect (iWARP)" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing over SMBDirect to allow iWARP.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMBDirect (iWARP)" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet, LocalSubnet `
	-LocalPort 5445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing over SMBDirect to allow iWARP.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "SMBDirect (iWARP)" `
	-Service Any -Program System -Group $Group `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet `
	-LocalPort 5445 -RemotePort Any `
	-InterfaceType $DefaultInterface `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-Description "Rule for File and Printer Sharing over SMBDirect to allow iWARP.
The RPCSS service is the Service Control Manager for COM and DCOM servers.
It performs object activations requests, object exporter resolutions and distributed garbage
collection for COM and DCOM servers." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log

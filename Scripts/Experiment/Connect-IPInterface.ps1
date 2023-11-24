
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.16.0

.GUID fb0514d5-daaf-4cd4-b072-21daddbeb10e

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.ComputerInfo
#>

<#
.SYNOPSIS
Connect NIC to network using DHCP

.DESCRIPTION
Force all available NIC's to contact DHCP for an IP until one of them become connected.
If you reset network or release NIC IP a network icon on the taskbar might say "No Network",
indicating that computer is not connected to network, this might be false positive and this
script forces renewal of NIC IP and clears the DNS cache needed to resolve the taskbar icon
false positive indicator.
This issue can be present when hardware NIC is shared with virtual switch in Hyper-V.

.PARAMETER Name
Optionally specify one or more interface alias (name) of the NIC which is to be connected via DHCP

.EXAMPLE
PS> Connect-IPInterface

.EXAMPLE
PS> Connect-IPInterface -Name

.INPUTS
None. You cannot pipe objects to Connect-IPInterface.ps1

.OUTPUTS
None. Connect-IPInterface.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Parameter()]
	[Alias("InterfaceAlias")]
	[string[]] $Name
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

Write-Verbose -Message "[$ThisScript] Checking if already connected to network"
$Profiles = Get-NetConnectionProfile

$NameSplating = @{}
if ($Name) { $NameSplating.Name = $Name }

$Interface = Get-NetAdapter @NameSplating | ForEach-Object {
	$Adapter = $PSItem

	$Profiles | Where-Object {
		$Adapter.ifIndex -eq $_.InterfaceIndex
	} | Select-Object @{ Name = "Name"; Expression = { $Adapter.Name } }, IPv4Connectivity
}

if ($Interface.IPv4Connectivity -eq "Internet")
{
	Write-Information -Tags $ThisScript -MessageData "INFO: Interface '$($Interface.Name)' already connected to network"
}
else
{
	if (!$Name)
	{
		$Name = Select-IPInterface -Visible | Select-Object -ExpandProperty InterfaceAlias
	}

	foreach ($InterfaceAlias in $Name)
	{
		if ($PSCmdlet.ShouldProcess($InterfaceAlias, "Connect NIC using DHCP"))
		{
			ipconfig /release $InterfaceAlias | Out-Null
			Clear-DnsClientCache
			ipconfig /renew $InterfaceAlias | Out-Null

			if (Select-IPInterface -Connected)
			{
				Write-Information -Tags $ThisScript -MessageData "INFO: Interface '$InterfaceAlias' was connected to network"
				return
			}
			else
			{
				Write-Warning -Message "[$ThisScript] Unable to connect '$InterfaceAlias' to network"
			}
		}
	}
}

Update-Log

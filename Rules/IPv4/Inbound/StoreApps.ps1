
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
Inbound firewall rules for store apps

.DESCRIPTION
Inbound firewall rules for store apps

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\StoreApps.ps1

.INPUTS
None. You cannot pipe objects to StoreApps.ps1

.OUTPUTS
None. StoreApps.ps1 does not generate any output

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
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Store Apps"
$SystemGroup = "Store Apps - System"
$Accept = "Inbound rules for store apps will be loaded, required for Windows store apps network access"
$Deny = "Skip operation, inbound rules for store apps will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $SystemGroup -Direction $Direction -ErrorAction Ignore

#
# Block Administrators by default
#

$Principals = Get-GroupPrincipal "Administrators" -CimSession $CimServer
foreach ($Principal in $Principals)
{
	New-NetFirewallRule -DisplayName "Store apps for $($Principal.User)" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Block -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-Owner (Get-PrincipalSID $Principal.User).SID -Package * `
		-Description "$($Principal.User) is administrative account,
block $($Principal.User) from network activity for all store apps.
Administrators should have limited or no connectivity at all for maximum security." |
	Format-RuleOutput
}

#
# Create rules for all network apps for each standard user
#

$Principals = Get-GroupPrincipal "Users" -CimSession $CimServer
foreach ($Principal in $Principals)
{
	#
	# Create rules for apps installed by user
	#

	Get-UserApp -User $Principal.User -Session $SessionInstance | ForEach-Object -Process {
		$NetworkCapabilities = $_ | Get-AppCapability -User $Principal.User -Session $SessionInstance -Networking

		if (!$NetworkCapabilities)
		{
			return
		}

		[string[]] $RemoteAddress = @()

		foreach ($Capability in $NetworkCapabilities)
		{
			switch ($Capability)
			{
				"Your Internet connection, including incoming connections from the Internet"
				{
					$RemoteAddress += "Internet4"
					break
				}
				"Your home or work networks"
				{
					$RemoteAddress += "LocalSubnet4"
					break
				}
				"runFullTrust"
				{
					$RemoteAddress += "Internet4"
					$RemoteAddress += "LocalSubnet4"
					break
				}
			}
		}

		if ($RemoteAddress.Count -eq 0)
		{
			return
		}

		$PackageSID = Get-AppSID -FamilyName $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			$DisplayName = $DefaultUICulture.TextInfo.ToTitleCase($_.Name)

			New-NetFirewallRule -DisplayName $DisplayName `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program Any -Group $Group `
				-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress $RemoteAddress `
				-LocalPort 80, 443 -RemotePort Any `
				-LocalUser Any -EdgeTraversalPolicy Block `
				-InterfaceType $DefaultInterface `
				-Owner $Principal.SID -Package $PackageSID `
				-Description "Auto generated rule for $DisplayName used by $($Principal.User)" |
			Format-RuleOutput

			Update-Log
		}
	}

	#
	# Create rules for system apps
	#

	Get-SystemApp -User $Principal.User -Session $SessionInstance | ForEach-Object -Process {
		$NetworkCapabilities = $_ | Get-AppCapability -User $Principal.User -Session $SessionInstance -Networking

		if (!$NetworkCapabilities)
		{
			return
		}

		[string[]] $RemoteAddress = @()

		foreach ($Capability in $NetworkCapabilities)
		{
			switch ($Capability)
			{
				"Your Internet connection, including incoming connections from the Internet"
				{
					$RemoteAddress += "Internet4"
					break
				}
				"Your home or work networks"
				{
					$RemoteAddress += "LocalSubnet4"
					break
				}
				"runFullTrust"
				{
					$RemoteAddress += "Internet4"
					$RemoteAddress += "LocalSubnet4"
					break
				}
			}
		}

		if ($RemoteAddress.Count -eq 0)
		{
			return
		}

		$PackageSID = Get-AppSID -FamilyName $_.PackageFamilyName

		# Possible package not found
		if ($PackageSID)
		{
			$DisplayName = $DefaultUICulture.TextInfo.ToTitleCase($_.Name)

			New-NetFirewallRule -DisplayName $DisplayName `
				-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
				-Service Any -Program Any -Group $SystemGroup `
				-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress $RemoteAddress `
				-LocalPort 80, 443 -RemotePort Any `
				-LocalUser Any -EdgeTraversalPolicy Block `
				-InterfaceType $DefaultInterface `
				-Owner $Principal.SID -Package $PackageSID `
				-Description "Auto generated rule for $DisplayName installed system wide and used by $($Principal.User)" |
			Format-RuleOutput

			Update-Log
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log

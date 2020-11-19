
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

<#
.SYNOPSIS
Inbound firewall rules for  broadcast traffic

.DESCRIPTION
Inbound firewall rules for  broadcast traffic

.EXAMPLE
PS> .\Broadcast.ps1

.INPUTS
None. You cannot pipe objects to Broadcast.ps1

.OUTPUTS
None. Broadcast.ps1 does not generate any output

.NOTES
There is no point to create separate rule for virtual adapters, since virtual adapter may be the
only one if physical adapter is shared with ex. Hyper-V
Also virtual adapters even though not connected to internet produce network traffic
TODO: currently handling only UDP, also broadcast falls into multicast space
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$LocalProfile = "Private, Domain"
$Group = "Broadcast"
$Accept = "Inbound broadcast rules will be loaded, recommended for proper local network functioning"
$Deny = "Skip operation, inbound broadcast rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# NOTE: Don't run if execute not approved
$BroadcastAddress = Get-Broadcast -IncludeAll

# First remove all existing rules matching grou-Group $Group p
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Broadcast rules
#

# NOTE: Limited broadcast can be used by DHCP
New-NetFirewallRule -DisplayName "Limited Broadcast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress $LimitedBroadcast -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" |
Format-Output

# TODO: unsure if Intranet makes sense here
New-NetFirewallRule -DisplayName "Limited Broadcast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress $LimitedBroadcast -RemoteAddress LocalSubnet4, Intranet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Explicitly deny broadcast traffic on public subnets" |
Format-Output

New-NetFirewallRule -DisplayName "LAN Broadcast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress $BroadcastAddress -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" |
Format-Output

Update-Log

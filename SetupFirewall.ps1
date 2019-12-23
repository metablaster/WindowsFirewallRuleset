
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

# Print Powershell version
Write-Host ""
Write-Host "Powershell version: $($PSVersionTable.PSVersion)"

# Find current script path
$ScriptPath = Split-Path $MyInvocation.InvocationName

# Set up Firewall profile
#& .\FirewallProfile.ps1

#
# Execute IPv4 rules
#

#
# Load Inbound rules
#
if(Approve-Execute "Yes" "Applying Inbound IPv4 Rules...")
{
    # Common rules
    & "$ScriptPath\IPv4\Inbound\AdditionalNetworking.ps1"
    & "$ScriptPath\IPv4\Inbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv4\Inbound\Broadcast.ps1"
    & "$ScriptPath\IPv4\Inbound\ICMP.ps1"
    & "$ScriptPath\IPv4\Inbound\InternetBrowser.ps1"
    & "$ScriptPath\IPv4\Inbound\MicrosoftOffice.ps1"
    & "$ScriptPath\IPv4\Inbound\Multicast.ps1"
    & "$ScriptPath\IPv4\Inbound\NetworkDiscovery.ps1"
    & "$ScriptPath\IPv4\Inbound\NetworkSharing.ps1"
    & "$ScriptPath\IPv4\Inbound\RemoteWindows.ps1"
    & "$ScriptPath\IPv4\Inbound\StoreApps.ps1"
    & "$ScriptPath\IPv4\Inbound\WindowsServices.ps1"
    & "$ScriptPath\IPv4\Inbound\WirelessNetworking.ps1"

    if(Approve-Execute "Yes" "Applying Rules for developers...")
    {
        # Rules for developers
        & "$ScriptPath\IPv4\Inbound\Development\EpicGames.ps1"
    }

    if(Approve-Execute "Yes" "Applying Rules for 3rd party programs...")
    {
        # rules for programs
        & "$ScriptPath\IPv4\Inbound\Software\Steam.ps1"
        & "$ScriptPath\IPv4\Inbound\Software\TeamViewer.ps1"
        & "$ScriptPath\IPv4\Inbound\Software\uTorrent.ps1"
    }
}

#
# Load Outbound rules
#
if(Approve-Execute "Yes" "Applying Outbound IPv4 Rules...")
{
    # Common rules
    & "$ScriptPath\IPv4\Outbound\AdditionalNetworking.ps1"
    & "$ScriptPath\IPv4\Outbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv4\Outbound\Broadcast.ps1"
    & "$ScriptPath\IPv4\Outbound\ICMP.ps1"
    & "$ScriptPath\IPv4\Outbound\InternetBrowser.ps1"
    & "$ScriptPath\IPv4\Outbound\MicrosoftOffice.ps1"
    & "$ScriptPath\IPv4\Outbound\MicrosoftSoftware.ps1"
    & "$ScriptPath\IPv4\Outbound\Multicast.ps1"
    & "$ScriptPath\IPv4\Outbound\NetworkDiscovery.ps1"
    & "$ScriptPath\IPv4\Outbound\NetworkSharing.ps1"
    & "$ScriptPath\IPv4\Outbound\RemoteWindows.ps1"
    & "$ScriptPath\IPv4\Outbound\StoreApps.ps1"
    & "$ScriptPath\IPv4\Outbound\Temporary.ps1"
    & "$ScriptPath\IPv4\Outbound\WindowsServices.ps1"
    & "$ScriptPath\IPv4\Outbound\WindowsSystem.ps1"
    & "$ScriptPath\IPv4\Outbound\WirelessNetworking.ps1"

    if(Approve-Execute "Yes" "Applying Rules for developers...")
    {
        # Rules for developers
        & "$ScriptPath\IPv4\Outbound\Development\EpicGames.ps1"
        & "$ScriptPath\IPv4\Outbound\Development\Github.ps1"
        & "$ScriptPath\IPv4\Outbound\Development\MSYS2.ps1"
        & "$ScriptPath\IPv4\Outbound\Development\VisualStudio.ps1"
    }

    if(Approve-Execute "Yes" "Applying Rules for games...")
    {
        # Rules for games
        & "$ScriptPath\IPv4\Outbound\Games\PokerStars.ps1"
        & "$ScriptPath\IPv4\Outbound\Games\WarThunder.ps1"
    }

    if(Approve-Execute "Yes" "Applying Rules for 3rd party programs...")
    {
        # rules for programs
        & "$ScriptPath\IPv4\Outbound\Software\Nvidia.ps1"
        & "$ScriptPath\IPv4\Outbound\Software\Steam.ps1"
        & "$ScriptPath\IPv4\Outbound\Software\TeamViewer.ps1"
        & "$ScriptPath\IPv4\Outbound\Software\Thunderbird.ps1"
        & "$ScriptPath\IPv4\Outbound\Software\uTorrent.ps1"
    }
}

#
# Execute IPv6 rules
#

#
# Load Inbound rules
#
if(Approve-Execute "Yes" "Applying Inbound IPv6 Rules...")
{
    # Common rules
    & "$ScriptPath\IPv6\Inbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv6\Inbound\ICMP.ps1"
    & "$ScriptPath\IPv6\Inbound\Multicast.ps1"
}

#
# Load Outbound rules
#
if(Approve-Execute "Yes" "Applying Outbound IPv6 Rules...")
{
    # Common rules
    & "$ScriptPath\IPv6\Outbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv6\Outbound\ICMP.ps1"
    & "$ScriptPath\IPv6\Outbound\Multicast.ps1"
}

Write-Host "All operations completed successfuly!"

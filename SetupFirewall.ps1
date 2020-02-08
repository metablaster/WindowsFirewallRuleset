
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\..\..\..\Modules\FirewallModule
Test-PowershellVersion $VersionCheck
Set-Variable -Name VersionCheck -Scope Global -Value $false


# Includes
Import-Module -Name $PSScriptRoot\Modules\ProgramInfo

# Clear errors and warning status
$Error.Clear()
Set-Variable -Name WarningStatus -Scope Global -Value $false

# Prompt to set screen buffer to recommended value
Set-ScreenBuffer

# Check all rules that apply to windows services
Test-File $ServiceHost
Get-NetworkServices $PSScriptRoot\Rules
Get-Content -Path $PSScriptRoot\Rules\NetworkServices.txt | ForEach-Object {
    Test-Service $_
}

#
# Execute IPv4 rules
#

#
# Load Inbound rules
#

Update-Context 4 "Inbound"

if(Approve-Execute "Yes" "Applying: Inbound IPv4 Rules")
{
    if(Approve-Execute "Yes" "Applying: Common rules")
    {
        # Common rules
        & "$PSScriptRoot\Rules\IPv4\Inbound\AdditionalNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\BasicNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\Broadcast.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\ICMP.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\InternetBrowser.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\MicrosoftOffice.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\Multicast.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\NetworkDiscovery.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\NetworkSharing.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\RemoteWindows.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\StoreApps.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\WindowsServices.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\WirelessNetworking.ps1"
    }

    Update-Context 4 "Outbound"
    if(Approve-Execute "Yes" "Applying: Rules for developers")
    {
        # Rules for developers
        & "$PSScriptRoot\Rules\IPv4\Inbound\Development\EpicGames.ps1"
    }

    Update-Context 4 "Outbound"
    if(Approve-Execute "Yes" "Applying: Rules for 3rd party programs")
    {
        # rules for programs
        & "$PSScriptRoot\Rules\IPv4\Inbound\Software\Steam.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\Software\TeamViewer.ps1"
        & "$PSScriptRoot\Rules\IPv4\Inbound\Software\uTorrent.ps1"
    }
}

#
# Load Outbound rules
#
Update-Context 4 "Outbound"

if(Approve-Execute "Yes" "Applying: Outbound IPv4 Rules")
{
    if(Approve-Execute "Yes" "Applying: Common rules")
    {
        # Common rules
        & "$PSScriptRoot\Rules\IPv4\Outbound\AdditionalNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\BasicNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Broadcast.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\ICMP.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\InternetBrowser.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\MicrosoftOffice.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\MicrosoftSoftware.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Multicast.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\NetworkDiscovery.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\NetworkSharing.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\RemoteWindows.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\StoreApps.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Temporary.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\WindowsServices.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\WindowsSystem.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\WirelessNetworking.ps1"
    }

    Update-Context 4 "Outbound"
    if(Approve-Execute "Yes" "Applying: Rules for developers")
    {
        # Rules for developers
        & "$PSScriptRoot\Rules\IPv4\Outbound\Development\EpicGames.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Development\Github.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Development\MSYS2.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Development\VisualStudio.ps1"
    }

    Update-Context 4 "Outbound"
    if(Approve-Execute "Yes" "Applying: Rules for games")
    {
        # Rules for games
        & "$PSScriptRoot\Rules\IPv4\Outbound\Games\PokerStars.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Games\WarThunder.ps1"
    }

    Update-Context 4 "Outbound"
    if(Approve-Execute "Yes" "Applying: Rules for 3rd party programs")
    {
        # rules for programs
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\DnsCrypt.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\Greenshot.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\Nvidia.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\OBSStudio.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\OpenSSH.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\PasswordSafe.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\Steam.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\TeamViewer.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\Thunderbird.ps1"
        & "$PSScriptRoot\Rules\IPv4\Outbound\Software\uTorrent.ps1"
    }
}

#
# Execute IPv6 rules
#

#
# Load Inbound rules
#
Update-Context 6 "Inbound"

if(Approve-Execute "Yes" "Applying: Inbound IPv6 Rules")
{
    if(Approve-Execute "Yes" "Applying: Common rules")
    {
        # Common rules
        & "$PSScriptRoot\Rules\IPv6\Inbound\BasicNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv6\Inbound\ICMP.ps1"
        & "$PSScriptRoot\Rules\IPv6\Inbound\Multicast.ps1"
    }
}

#
# Load Outbound rules
#
Update-Context 6 "Outbound"

if(Approve-Execute "Yes" "Applying: Outbound IPv6 Rules")
{
    if(Approve-Execute "Yes" "Applying: Common rules")
    {
        # Common rules
        & "$PSScriptRoot\Rules\IPv6\Outbound\BasicNetworking.ps1"
        & "$PSScriptRoot\Rules\IPv6\Outbound\ICMP.ps1"
        & "$PSScriptRoot\Rules\IPv6\Outbound\Multicast.ps1"
    }
}

Write-Host ""

# Set up Firewall profile
& .\FirewallProfile.ps1

# Show status of execution
$ErrorCount = $Error.Count -gt 0

if ($ErrorCount)
{
    Write-Host ""
    Write-Warning "Errors were generated"
    Save-Errors

    Write-Host ""
    Write-Note "If module is edited don't forget to restart Powershell"
}

if ($WarningStatus)
{
    Write-Host ""
    Write-Warning "Warnings were generated"
    Write-Note "All warnings were saved to:", "$("$RepoDir\Logs")", "you can review these logs to see if you want to resolve some of them"
}

if (!$ErrorCount -and !$WarningStatus)
{
    Write-Host ""
    Write-Note "All operations completed successfuly!"
}

Write-Host ""
Write-Note "Make sure you visit Local Group Policy and adjust your rules as needed."
Write-Host ""

# Clear warning status
Set-Variable -Name WarningStatus -Scope Global -Value $false

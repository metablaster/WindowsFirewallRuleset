
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
Write-Host "";
Write-Host "PSVersion: $($PSVersionTable.PSVersion)";

# Import needed functions
. "$PSScriptRoot\Modules\Functions.ps1"

# Find current script path
$ScriptPath = Split-Path $MyInvocation.InvocationName

# PSScriptRoot is automatic variable introduced in Powershell 3
if(!$PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

#
# Execute IPv4 rules
#

if(RunThis("Applying Inbound Rules..."))
{
    # Load Inbound rules
    & "$ScriptPath\IPv4\Inbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv4\Inbound\ICMP.ps1"
    & "$ScriptPath\IPv4\Inbound\InternetBrowser.ps1"
    & "$ScriptPath\IPv4\Inbound\Multicast.ps1"
    & "$ScriptPath\IPv4\Inbound\WirelessNetworking.ps1"
}

if(RunThis("Applying Outbound Rules..."))
{
    # Load Outbound rules
    & "$ScriptPath\IPv4\Outbound\BasicNetworking.ps1"
    & "$ScriptPath\IPv4\Outbound\ICMP.ps1"
    & "$ScriptPath\IPv4\Outbound\InternetBrowser.ps1"
    & "$ScriptPath\IPv4\Outbound\MicrosoftOffice.ps1"
    & "$ScriptPath\IPv4\Outbound\MicrosoftSoftware.ps1"
    & "$ScriptPath\IPv4\Outbound\Multicast.ps1"
    & "$ScriptPath\IPv4\Outbound\VisualStudio.ps1"
    & "$ScriptPath\IPv4\Outbound\WindowsServices.ps1"
    & "$ScriptPath\IPv4\Outbound\WindowsSystem.ps1"
    & "$ScriptPath\IPv4\Outbound\WirelessNetworking.ps1"
}

Write-Host "All operations completed successfuly!"

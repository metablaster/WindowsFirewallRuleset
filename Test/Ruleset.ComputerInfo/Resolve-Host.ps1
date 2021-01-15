
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for Resolve-Host

.DESCRIPTION
Test correctness of Resolve-Host function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Resolve-Host.ps1

.INPUTS
None. You cannot pipe objects to Resolve-Host.ps1

.OUTPUTS
None. Resolve-Host.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Resolve-Host"

# Prepare test IP
Start-Test "Get google IP"
$NSLookup = Invoke-Process nslookup.exe -ArgumentList "google.com" -Raw -EA Ignore
[System.Text.RegularExpressions.Match[]] $Regex = [regex]::Matches($NSLookup, "(?<=\D)(?<IPAddress>([0-9]{1,3}\.){3}[0-9]{1,3})")
if ($Regex.Count)
{
	[IPAddress] $GoogleIP = $Regex.Captures[$Regex.Count - 1].Value
	Write-Information -Tags "Test" -MessageData "INFO: Google IP is $($GoogleIP.IPAddressToString)"
}

Start-Test "IPv4 LocalHost"
Resolve-Host -AddressFamily IPv4 -Physical

Start-Test "Virtual"
Resolve-Host -Virtual

Start-Test "LocalHost"
Resolve-Host -Domain ([System.Environment]::MachineName)

Start-Test "pipeline FlushDNS"
Select-IPInterface -Physical | Resolve-Host -FlushDNS

Start-Test "IPv4 microsoft.com"
Resolve-Host -AddressFamily IPv4 -Domain "microsoft.com"

Start-Test "GoogleIP"
$Result = Resolve-Host -IPAddress $GoogleIP
$Result

Test-Output $Result -Command Resolve-Host

Start-Test "microsoft.com FlushDNS"
$Result = Resolve-Host -FlushDNS -Domain "microsoft.com"
$Result

Test-Output $Result -Command Resolve-Host

Start-Test "GoogleIP FlushDNS"
Resolve-Host -FlushDNS -IPAddress $GoogleIP

Update-Log
Exit-Test

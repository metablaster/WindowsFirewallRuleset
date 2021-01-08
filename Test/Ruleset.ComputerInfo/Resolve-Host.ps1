
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
If specified, no prompt to run script is shown.

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
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

# Prepare test IP
Start-Test "Get google IP"
$NSLookup = Invoke-Process nslookup.exe -ArgumentList "google.com" -EA Ignore
if ($NSLookup -and $NSLookup -match "(?<!\s)([0-9]{1,3}\.){3}[0-9]{1,3}")
{
	[IPAddress] $GoogleIP = $Matches[0]
	$GoogleIP.IPAddressToString
}

Start-Test "Resolve-Host IPv4 LocalHost"
Resolve-Host -AddressFamily IPv4 -Physical

Start-Test "Resolve-Host Virtual"
Resolve-Host -Virtual

Start-Test "Resolve-Host LocalHost"
Resolve-Host -Domain ([System.Environment]::MachineName)

Start-Test "Resolve-Host pipeline FlushDNS"
Select-IPInterface -Physical | Resolve-Host -FlushDNS

Start-Test "Resolve-Host IPv4 microsoft.com"
Resolve-Host -AddressFamily IPv4 -Domain "microsoft.com"

Start-Test "Resolve-Host GoogleIP"
$Result = Resolve-Host -IPAddress $GoogleIP
$Result

Test-Output $Result -Command Resolve-Host

Start-Test "Resolve-Host microsoft.com FlushDNS"
Resolve-Host -FlushDNS -Domain "microsoft.com"

Start-Test "Resolve-Host GoogleIP FlushDNS"
Resolve-Host -FlushDNS -IPAddress $GoogleIP

Test-Output $Result -Command Resolve-Host

Update-Log
Exit-Test

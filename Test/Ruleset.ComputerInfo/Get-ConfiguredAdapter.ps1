
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
Unit test for Get-ConfiguredAdapter

.DESCRIPTION
Unit test for Get-ConfiguredAdapter

.EXAMPLE
PS> .\Get-ConfiguredAdapter.ps1

.INPUTS
None. You cannot pipe objects to Get-ConfiguredAdapter.ps1

.OUTPUTS
None. Get-ConfiguredAdapter.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }
#endregion

Enter-Test

Start-Test "Get-ConfiguredAdapter IPv4"
Get-ConfiguredAdapter IPv4 @Logs

Start-Test "Get-ConfiguredAdapter IPv6 FAILURE TEST"
Get-ConfiguredAdapter IPv6 -ErrorAction SilentlyContinue @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeDisconnected"
Get-ConfiguredAdapter IPv4 -IncludeDisconnected @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeVirtual"
Get-ConfiguredAdapter IPv4 -IncludeVirtual @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeVirtual -IncludeDisconnected"
Get-ConfiguredAdapter IPv4 -IncludeVirtual -IncludeDisconnected @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware"
Get-ConfiguredAdapter IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeHidden"
Get-ConfiguredAdapter IPv4 -IncludeHidden @Logs

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeAll"
$Result = Get-ConfiguredAdapter IPv4 -IncludeAll @Logs
$Result

Start-Test "Get-ConfiguredAdapter IPv4 -IncludeAll -ExcludeHardware"
Get-ConfiguredAdapter IPv4 -IncludeAll -ExcludeHardware @Logs

Start-Test "Get-ConfiguredAdapter binding"
Get-ConfiguredAdapter IPv4 @Logs | Select-Object -ExpandProperty IPv4Address @Logs

Test-Output $Result -Command Get-ConfiguredAdapter @Logs

Update-Log
Exit-Test


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

#
# Unit test for Get-SystemSKU
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Get-SystemSKU -ComputerName $([System.Environment]::MachineName)"
Get-SystemSKU -ComputerName $([System.Environment]::MachineName) @Logs | Format-Table

Start-Test "Get-SystemSKU -SKU 4"
$Result = Get-SystemSKU -SKU 48 @Logs
$Result | Format-Table

Start-Test "34 | Get-SystemSKU"
34 | Get-SystemSKU @Logs | Format-Table

Start-Test '@($([System.Environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU'
@($([System.Environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU @Logs | Format-Table

Start-Test '$Result = @($([System.Environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU'
$Result = @($([System.Environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU @Logs | Format-Table
$Result

Start-Test 'Get-SystemSKU -ComputerName @($([System.Environment]::MachineName), "INVALID_COMPUTER")'
Get-SystemSKU -ComputerName @($([System.Environment]::MachineName), "INVALID_COMPUTER") @Logs | Format-Table

try
{
	Start-Test "Get-SystemSKU -SKU 4 -ComputerName $([System.Environment]::MachineName)"
	Get-SystemSKU -SKU 4 -ComputerName $([System.Environment]::MachineName) -ErrorAction Stop
}
catch
{
	Write-Information -Tags "Test" -MessageData "Failure test success"
}

Start-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

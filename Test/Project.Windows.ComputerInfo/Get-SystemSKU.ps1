
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

# Check requirements for this project
Test-SystemRequirements

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

New-Test "Get-SystemSKU -ComputerName $([environment]::MachineName)"
Get-SystemSKU -ComputerName $([environment]::MachineName) @Logs | Format-Table

New-Test "Get-SystemSKU -SKU 4"
$Result = Get-SystemSKU -SKU 48 @Logs
$Result | Format-Table

New-Test "34 | Get-SystemSKU"
34 | Get-SystemSKU @Logs | Format-Table

New-Test '@($([environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU'
@($([environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU @Logs | Format-Table

New-Test '$Result = @($([environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU'
$Result = @($([environment]::MachineName), "INVALID_COMPUTER") | Get-SystemSKU @Logs | Format-Table
$Result

New-Test 'Get-SystemSKU -ComputerName @($([environment]::MachineName), "INVALID_COMPUTER")'
Get-SystemSKU -ComputerName @($([environment]::MachineName), "INVALID_COMPUTER") @Logs | Format-Table

try
{
	New-Test "Get-SystemSKU -SKU 4 -ComputerName $([environment]::MachineName)"
	Get-SystemSKU -SKU 4 -ComputerName $([environment]::MachineName) -ErrorAction Stop
}
catch
{
	Write-Information -Tags "Test" -MessageData "Failure test success"
}

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test


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
# Unit test for ConvertFrom-SID
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name Project.AllPlatforms.System
Test-SystemRequirements

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.AllPlatforms.Test @Logs
Import-Module -Name Project.Windows.UserInfo @Logs
Import-Module -Name Project.AllPlatforms.Utility @Logs
Import-Module -Name Project.Windows.ProgramInfo @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

$VerbosePreference = "Continue"
$DebugPreference = "Continue"

Start-Test

New-Test "Get-GroupPrincipal 'Users', 'Administrators', NT SYSTEM, NT LOCAL SERVICE"
$UserAccounts = Get-GroupPrincipal "Users", "Administrators" @Logs
$UserAccounts

New-Test "Get-AccountSID NT SYSTEM, NT LOCAL SERVICE"
$NTAccounts = Get-AccountSID -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE" @Logs
$NTAccounts

New-Test "ConvertFrom-SID users and admins"
$AccountSIDs = @()
foreach ($Account in $UserAccounts)
{
	$AccountSIDs += $Account.SID
}
$AccountSIDs | ConvertFrom-SID @Logs | Format-Table

New-Test "ConvertFrom-SID NT AUTHORITY users"
foreach ($Account in $NTAccounts)
{
	ConvertFrom-SID $Account @Logs | Format-Table
}

New-Test "ConvertFrom-SID Unknown domain"
ConvertFrom-SID "S-1-5-21-0000-0000-1111-1111" -ErrorAction Ignore | Format-Table

New-Test "ConvertFrom-SID App SID"
$AppSID = "S-1-15-2-2967553933-3217682302-2494645345-2077017737-3805576244-585965800-1797614741"
$AppResult = ConvertFrom-SID $AppSID @Logs
$AppResult | Format-Table

New-Test "ConvertFrom-SID nonexistent App SID"
$AppSID = "S-1-15-2-2967553933-3217682302-0000000000000000000-2077017737-3805576244-585965800-1797614741"
$AppResult = ConvertFrom-SID $AppSID -ErrorAction Ignore @Logs
$AppResult | Format-Table

New-Test "ConvertFrom-SID APPLICATION PACKAGE AUTHORITY"
$AppSID = "S-1-15-2-2"
$PackageResult = ConvertFrom-SID $AppSID @Logs
$PackageResult | Format-Table

New-Test "ConvertFrom-SID Capability"
$AppSID = "S-1-15-3-12345"
$PackageResult = ConvertFrom-SID $AppSID @Logs
$PackageResult | Format-Table

New-Test "Get-TypeName AppSID"
$AppResult | Get-TypeName @Logs

New-Test "Get-TypeName UserAccounts"
$UserAccounts[0] | Get-TypeName @Logs

Update-Log
Exit-Test

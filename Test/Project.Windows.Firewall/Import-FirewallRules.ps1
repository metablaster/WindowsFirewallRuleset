
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
# Unit test for Import-FirewallRules
#
#Requires -RunAsAdministrator
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
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

$Exports = "$ProjectRoot\Exports"

# TODO: need to test failure cases, see also module todo's for more info
# TODO: need to test store apps import for "Any" and "*" owner/package

# Start-Test "Import-FirewallRules -FileName GroupExport.csv"
# Import-FirewallRules -Folder $Exports -FileName "GroupExport.csv" @Logs

# Start-Test "Import-FirewallRules -FileName NamedExport1.csv"
# Import-FirewallRules -Folder $Exports -FileName "$Exports\NamedExport1.csv" @Logs

# Start-Test "Import-FirewallRules -JSON -FileName NamedExport2.json"
# Import-FirewallRules -JSON -Folder $Exports -FileName "$Exports\NamedExport2.json" @Logs

Start-Test "Import-FirewallRules -FileName StoreAppExport.csv"
Import-FirewallRules -Folder $Exports -FileName "StoreAppExport.csv" @Logs

Update-Log
Exit-Test

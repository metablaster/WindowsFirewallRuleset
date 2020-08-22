
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

# TODO: Include modules you need, update Copyright and start writing test code

#
# Unit test for ConvertFrom-OSBuild
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
# Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

New-Test "ConvertFrom-OSBuild 17763 = 1809"
ConvertFrom-OSBuild 17763 @Logs

New-Test "ConvertFrom-OSBuild 19041.450 = 2004"
ConvertFrom-OSBuild 19041.450 @Logs

New-Test "ConvertFrom-OSBuild 11111.1 = unknown"
ConvertFrom-OSBuild 11111.133 -ErrorAction Ignore @Logs

New-Test "ConvertFrom-OSBuild 16299.2045 = 1079"
$Result = ConvertFrom-OSBuild 16299.2045 @Logs
$Result

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

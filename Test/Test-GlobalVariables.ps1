
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
# Unit test for Test-GlobalVariables
#
. $PSScriptRoot\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "Project.AllPlatforms.Logs - Logs:"
$Logs

Start-Test "Project.AllPlatforms.Utility - ServiceHost:"
$ServiceHost

if ($Develop)
{
	Start-Test "Project.Windows.ProgramInfo - InstallTable:"
	$InstallTable
}

Start-Test "Project.Windows.UserInfo - NT_AUTHORITY_UserModeDrivers:"
$NT_AUTHORITY_UserModeDrivers

Start-Test "Project.Windows.UserInfo - NT_AUTHORITY_NetworkService:"
$NT_AUTHORITY_NetworkService

Start-Test "Project.Windows.UserInfo - NT_AUTHORITY_LocalService:"
$NT_AUTHORITY_LocalService

Start-Test "Project.Windows.UserInfo - NT_AUTHORITY_System:"
$NT_AUTHORITY_System

Start-Test "Project.Windows.UserInfo - AdministratorsGroupSDDL:"
$AdministratorsGroupSDDL

Start-Test "Project.Windows.UserInfo - UsersGroupSDDL:"
$UsersGroupSDDL

Exit-Test

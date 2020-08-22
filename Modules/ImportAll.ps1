
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

# Imports
. $PSScriptRoot\..\Config\ProjectSettings.ps1

#
# Import all modules into current session, useful for debugging, ie. running individual functions
#

Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.AllPlatforms.Initialize @Logs
Import-Module -Name Project.AllPlatforms.Test @Logs
Import-Module -Name Project.AllPlatforms.Utility @Logs

Import-Module -Name Project.Windows.UserInfo @Logs
Import-Module -Name Project.Windows.ComputerInfo @Logs
Import-Module -Name Project.Windows.ProgramInfo @Logs

Import-Module -Name Project.Windows.Firewall @Logs
Import-Module -Name Indented.Net.IP @Logs
Import-Module -Name VSSetup @Logs

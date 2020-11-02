
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

<#
.SYNOPSIS
Unit test for ConvertFrom-OSBuild

.DESCRIPTION
Unit test for ConvertFrom-OSBuild

.EXAMPLE
PS> .\ConvertFrom-OSBuild.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-OSBuild.ps1

.OUTPUTS
None. ConvertFrom-OSBuild.ps1 does not generate any output

.NOTES
None.
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

Start-Test "ConvertFrom-OSBuild 17763 = 1809"
ConvertFrom-OSBuild 17763 @Logs

Start-Test "ConvertFrom-OSBuild 19041.450 = 2004"
ConvertFrom-OSBuild 19041.450 @Logs

# TODO: -ErrorAction Ignore doesn't work in Windows PowerShell (all tests)
Start-Test "ConvertFrom-OSBuild 11111.1 = unknown"
ConvertFrom-OSBuild 11111.133 -ErrorAction SilentlyContinue @Logs

Start-Test "ConvertFrom-OSBuild 16299.2045 = 1079"
$Result = ConvertFrom-OSBuild 16299.2045 @Logs
$Result

Test-Output $Result -Command ConvertFrom-OSBuild

Update-Log
Exit-Test

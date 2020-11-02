
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
Unit test for Format-Path

.DESCRIPTION
Unit test for Format-Path

.EXAMPLE
PS> .\Format-Path.ps1

.INPUTS
None. You cannot pipe objects to Format-Path.ps1

.OUTPUTS
None. Format-Path.ps1 does not generate any output

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

$TestPath = "C:\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\Windows\System32"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\Windows\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Program Files (x86)\Windows Defender\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Program Files\WindowsPowerShell"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = '"C:\ProgramData\Git"'
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\PerfLogs"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Windows\Microsoft.NET\Framework64\v3.5\\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "D:\\microsoft\\windows"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "D:\"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Users\$UnitTester\AppData\Local\OneDrive"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "%SystemDrive%"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Users\Public\Public Downloads"
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = ""
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = $null
Start-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

Start-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

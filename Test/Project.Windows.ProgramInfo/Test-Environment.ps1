
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
# Unit test for Test-Environment
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

$Result = "C:\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\\Windows\System32"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\\Windows\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\Program Files (x86)\Windows Defender\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\Program Files\WindowsPowerShell"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = '"C:\ProgramData\Git"'
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\PerfLogs"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\Windows\Microsoft.NET\Framework64\v3.5\\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "D:\\microsoft\\windows"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "D:\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "C:\\"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "%LOCALAPPDATA%\OneDrive"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "%HOME%\AppData\Local\OneDrive"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = "%SystemDrive%"
New-Test "Test-Environment: $Result"
$Status = Test-Environment $Result @Logs
$Status

$Result = ""
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

$Result = $null
New-Test "Test-Environment: $Result"
Test-Environment $Result @Logs

New-Test "Get-TypeName"
$Status | Get-TypeName @Logs

Update-Log
Exit-Test

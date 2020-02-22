
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
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

Start-Test

New-Test "Test-Environment"

$Result = "C:\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\\Windows\System32"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\\Windows\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\Program Files (x86)\Windows Defender\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\Program Files\WindowsPowerShell"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = '"C:\ProgramData\Git"'
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\PerfLogs"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\Windows\Microsoft.NET\Framework64\v3.5\\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "D:\\microsoft\\windows"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "D:\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "C:\\"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "%LOCALAPPDATA%\OneDrive"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "%HOME%\AppData\Local\OneDrive"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = "%SystemDrive%"
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = ""
$Result
Test-Environment $Result @Logs
Update-Logs

$Result = $null
$Result
Test-Environment $Result @Logs
Update-Logs

Exit-Test

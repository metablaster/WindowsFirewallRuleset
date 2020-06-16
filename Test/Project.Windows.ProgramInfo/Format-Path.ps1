
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
# Unit test for Format-Path
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

$TestPath = "C:\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\Windows\System32"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\Windows\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Program Files (x86)\Windows Defender\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Program Files\WindowsPowerShell"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = '"C:\ProgramData\Git"'
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\PerfLogs"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Windows\Microsoft.NET\Framework64\v3.5\\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "D:\\microsoft\\windows"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "D:\"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "C:\Users\haxor\AppData\Local\OneDrive"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = "%SystemDrive%"
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = ""
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

$TestPath = $null
New-Test $TestPath
$Result = Format-Path $TestPath @Logs
$Result
Test-Environment $Result @Logs

New-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

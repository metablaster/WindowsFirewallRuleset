
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\..\Modules\System
Test-SystemRequirements $VersionCheck

# Includes
. $PSScriptRoot\IPSetup.ps1
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

Write-Host ""
Write-Host "Format-Path"
Write-Host "***************************"
Write-Host ""

$Result = Format-Path "C:\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\\Windows\System32"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Program Files (x86)\Windows Defender\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Program Files\WindowsPowerShell"
$Result
Test-Environment $Result

$Result = Format-Path '"C:\ProgramData\Git"'
$Result
Test-Environment $Result

$Result = Format-Path "C:\PerfLogs"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Windows\Microsoft.NET\Framework64\v3.5"
$Result
Test-Environment $Result

$Result = Format-Path "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
$Result
Test-Environment $Result

$Result = Format-Path "D:\\microsoft\\windows"
$Result
Test-Environment $Result

$Result = Format-Path "D:\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Users\haxor\AppData\Local\OneDrive"
$Result
Test-Environment $Result

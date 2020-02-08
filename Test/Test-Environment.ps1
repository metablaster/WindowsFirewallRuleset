
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
# Unit test for Test-Environment
#

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule
Test-PowershellVersion $VersionCheck

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo

# Includes
. $PSScriptRoot\IPSetup.ps1
. $PSScriptRoot\DirectionSetup.ps1

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

$path1 = "%ProgramFiles%\Common Files\microsoft shared"
$path2 = "%ProgramFiles(x86)%\Microsoft Visual Studio"

Write-Host ""
Write-Host "Test-Environment '$path1'"
Test-Environment "$path1"

Write-Host ""
Write-Host "Test-Environment '$path2'"
Test-Environment "$path2"

Write-Host ""

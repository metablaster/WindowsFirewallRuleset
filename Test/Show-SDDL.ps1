
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
# Unit test for Show-SDDL
#

# Includes
. $PSScriptRoot\IPSetup.ps1
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule

# Test Powershell version required for this project
Test-PowershellVersion $VersionCheck

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# Experiment with different path values to see what the ACL objects do
$TestPath = "C:\Users\" #Not inherited
# $TestPath = "C:\users\Public\desktop\" #Inherited
# $TestPath = "HKCU:\" #Not Inherited
# $TestPath = "HKCU:\Software" #Inherited
# $TestPath = "HKLM:\" #Not Inherited

Write-Host ""
Write-Host "Path:"
Write-Host "************************"
$TestPath

Write-Host ""
Write-Host "ACL.AccessToString:"
Write-Host "************************"

$ACL = Get-ACL $TestPath
$ACL.AccessToString

Write-Host ""
Write-Host "Access entry details:"
Write-Host "************************"

$ACL.Access | Format-list *

Write-Host ""
Write-Host "SDDL:"
Write-Host "************************"

$ACL.SDDL

# Call with named parameter binding 
# $ACL | Show-SDDL

# Or call with parameter string
Show-SDDL $ACL.SDDL

Write-Host ""

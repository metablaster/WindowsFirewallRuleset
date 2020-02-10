
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
# Unit test for Get-AccountSID
#

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\IPSetup.ps1
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name $PSScriptRoot\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts "Users"
$UserAccounts += Get-UserAccounts "Administrators"
$UserAccounts

Write-Host ""
Write-Host "Get-AccountSID:"
Write-Host "***************************"

foreach($Account in $UserAccounts)
{
    $(Get-AccountSID $Account)
}

Write-Host ""

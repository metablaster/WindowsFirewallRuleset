
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
# Unit test for Get-AppSID
#

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\IPSetup.ps1
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name $PSScriptRoot\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[string[]] $UserAccounts = Get-UserAccounts "Users"
[string[]] $AdminAccounts = Get-UserAccounts "Administrators"
$UserAccounts
$AdminAccounts

Write-Host ""
Write-Host "Get-UserNames:"
Write-Host "***************************"

$Users = Get-UserNames $UserAccounts
$Admins = Get-UserNames $AdminAccounts

$Users
$Admins

Write-Host ""
Write-Host "Get-UserSID:"
Write-Host "***************************"

foreach($User in $Users)
{
    Get-UserSID $User
}

foreach($Admin in $Admins)
{
    Get-UserSID $Admin
}

Write-Host ""
Write-Host "Get-AppSID: foreach User"
Write-Host "***************************"

foreach($User in $Users) {
    Write-Host "Processing for: $User"
    Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {
        Get-AppSID $User $_.PackageFamilyName
    }
}

Write-Host ""
Write-Host "Get-AppSID: foreach Admin"
Write-Host "***************************"

foreach($Admin in $Admins) {
    Write-Host "Processing for: $Admin"
    Get-AppxPackage -User $Admin -PackageTypeFilter Bundle | ForEach-Object {
        Get-AppSID $Admin $_.PackageFamilyName
    }
}

Write-Host ""

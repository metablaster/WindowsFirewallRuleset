
#
# Unit test for Get-UserNames
#

Import-Module -Name $PSScriptRoot\..\Modules\UserInfo

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts "Users"
$UserAccounts += Get-UserAccounts "Administrators"
$UserAccounts

Write-Host ""
Write-Host "Get-UserNames:"
Write-Host "***************************"

$UserNames = Get-UserNames $UserAccounts
$UserNames

Write-Host ""

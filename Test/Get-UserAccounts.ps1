
#
# Unit test for Get-UserAccounts
#

. "$PSScriptRoot\..\Modules\Functions.ps1"

Write-Host ""
Write-Host "Get-UserAccounts(Users):"
Write-Host "***************************"

[string[]] $Users = Get-UserAccounts("Users")
$Users

Write-Host ""
Write-Host "Get-UserAccounts(Administrators):"
Write-Host "***************************"

[string[]] $Administrators = Get-UserAccounts("Administrators")
$Administrators

Write-Host ""
Write-Host "Join arrays:"
Write-Host "***************************"

$UserAccounts = $Users + $Administrators
$UserAccounts

Write-Host ""

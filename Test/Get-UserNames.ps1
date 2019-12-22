
#
# Unit test for Get-UserNames
#

. "$PSScriptRoot\..\Modules\Functions.ps1"

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts("Users")
$UserAccounts = $UserAccounts += (Get-UserAccounts("Administrators"))
$UserAccounts

Write-Host ""
Write-Host "Get-UserNames:"
Write-Host "***************************"

$UserNames = Get-UserNames($UserAccounts)
$UserNames

Write-Host ""

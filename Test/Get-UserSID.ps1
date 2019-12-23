
#
# Unit test for Get-UserSID
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

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
Write-Host "Get-UserSID:"
Write-Host "***************************"

foreach($User in $UserNames)
{
    $(Get-UserSID($User))
}

Write-Host ""

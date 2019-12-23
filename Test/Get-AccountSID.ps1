
#
# Unit test for Get-AccountSID
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts("Users")
$UserAccounts = $UserAccounts += (Get-UserAccounts("Administrators"))
$UserAccounts

Write-Host ""
Write-Host "Get-AccountSID:"
Write-Host "***************************"

foreach($Account in $UserAccounts)
{
    $(Get-AccountSID($Account))
}

Write-Host ""

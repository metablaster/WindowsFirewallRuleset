
#
# Unit test for Get-AccountSDDL
#

Import-Module -Name $PSScriptRoot\..\Modules\UserInfo

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts "Users"
$UserAccounts += Get-UserAccounts "Administrators"
$UserAccounts

Write-Host ""
Write-Host "Get-AccountSDDL: (separated)"
Write-Host "***************************"

foreach($Account in $UserAccounts)
{
    $(Get-AccountSDDL $Account)
}

Write-Host ""
Write-Host "Get-AccountSDDL: (combined)"
Write-Host "***************************"

Get-AccountSDDL $UserAccounts

Write-Host ""
Write-Host "Get-AccountSDDL: (from array)"
Write-Host "***************************"

Get-AccountSDDL @("NT AUTHORITY\SYSTEM", "NT AUTHORITY\NETWORK SERVICE")

Write-Host ""

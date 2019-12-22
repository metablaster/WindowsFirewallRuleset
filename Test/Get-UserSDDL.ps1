
#
# Unit test for Get-UserSDDL
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
Write-Host "Get-UserSDDL: (separated)"
Write-Host "***************************"

foreach($User in $UserNames)
{
    $(Get-UserSDDL($User))
}

Write-Host ""
Write-Host "Get-UserSDDL: (combined)"
Write-Host "***************************"

$(Get-UserSDDL($UserNames))

Write-Host ""
Write-Host "Get-UserSDDL: (from array)"
Write-Host "***************************"

$(Get-UserSDDL @("MSIDESKTOP\User", "MSIDESKTOP\Admin"))

Write-Host ""

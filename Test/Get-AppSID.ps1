
#
# Unit test for Get-AppSID
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[string[]] $UserAccounts = Get-UserAccounts("Users")
[string[]] $AdminAccounts = Get-UserAccounts("Administrators")
$UserAccounts
$AdminAccounts

Write-Host ""
Write-Host "Get-UserNames:"
Write-Host "***************************"

$Users = Get-UserNames($UserAccounts)
$Admins = Get-UserNames($AdminAccounts)

$Users
$Admins

Write-Host ""
Write-Host "Get-UserSID:"
Write-Host "***************************"

foreach($User in $Users)
{
    $(Get-UserSID($User))
}

foreach($Admin in $Admins)
{
    $(Get-UserSID($Admin))
}

Write-Host ""
Write-Host "Get-AppSID: foreach User"
Write-Host "***************************"

foreach($User in $Users) {
    Write-Host "Processing for: $User"
    Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {
        $(Get-AppSID $User $_.PackageFamilyName)
    }    
}

Write-Host ""
Write-Host "Get-AppSID: foreach Admin"
Write-Host "***************************"

foreach($Admin in $Admins) {
    Write-Host "Processing for: $Admin"
    Get-AppxPackage -User $Admin -PackageTypeFilter Bundle | ForEach-Object {
        $(Get-AppSID $Admin $_.PackageFamilyName)
    }    
}

Write-Host ""


#
# Unit test for Get-AppSID
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

$Platform = "10.0+" #Windows 10 and above
$PolicyStore = "localhost" #Local Group Policy
$OnError = "Stop" #Stop executing if error
$Debug = $false #To add rules to firewall for real set to false
$Execute = $false #To prompt for each rule set to true
$Group = "Test"
$Direction = "Outbound"

Write-Host ""
Write-Host "Remove-NetFirewallRule"
Write-Host "***************************"

# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[string[]] $UserAccounts = Get-UserAccounts("Users")
$UserAccounts

Write-Host ""
Write-Host "Get-UserNames:"
Write-Host "***************************"

$Users = Get-UserNames($UserAccounts)
$Users

Write-Host ""
Write-Host "Get-UserSID:"
Write-Host "***************************"

foreach($User in $Users)
{
    $(Get-UserSID($User))
}

Write-Host ""
Write-Host "Get-AppSID: foreach User"
Write-Host "***************************"

[string] $PackageSID = ""
[string] $OwnerSID = ""
foreach($User in $Users) {
    Write-Host "Processing for: $User"
    $OwnerSID = Get-UserSID($User)

    Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {
        $PackageSID = (Get-AppSID $User $_.PackageFamilyName)
        $PackageSID
    }    
}

Write-Host ""
Write-Host "New-NetFirewallRule"
Write-Host "***************************"

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Get-AppSID" -Program Any -Service Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Any -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -Owner $OwnerSID -Package $PackageSID `
-Description ""

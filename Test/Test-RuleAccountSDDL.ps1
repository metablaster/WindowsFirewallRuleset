
#
# Unit test for adding rules based on computer accounts
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
Write-Host "Get-UserAccounts(Users)"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts("Users")
$UserAccounts

Write-Host ""
Write-Host "Users + Get-UserAccounts(Administrators) + NT SYSTEM"
Write-Host "***************************"

$UserAccounts = $UserAccounts += (Get-UserAccounts("Administrators"))
$UserAccounts = $UserAccounts += "NT AUTHORITY\SYSTEM"
$UserAccounts

Write-Host ""
Write-Host "Get-AccountSDDL:"
Write-Host "***************************"

$LocalUser = Get-AccountSDDL($UserAccounts)
$LocalUser

Write-Host ""
Write-Host "New-NetFirewallRule"
Write-Host "***************************"

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Get-AccountSDDL" -Program Any -Service Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Any -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser $LocalUser `
-Description ""

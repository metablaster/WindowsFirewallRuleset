
#
# Unit test for Convert-SDDLToACL
#

. "$PSScriptRoot\..\Modules\Functions.ps1"

Write-Host ""
Write-Host "Get-UserAccounts:"
Write-Host "***************************"

[String[]]$UserAccounts = Get-UserAccounts("Users")
$UserAccounts = $UserAccounts += (Get-UserAccounts("Administrators"))
$UserAccounts

Write-Host ""
Write-Host "Get-AccountSDDL: (user accounts)"
Write-Host "***************************"

$SDDL1 = Get-AccountSDDL($UserAccounts)
$SDDL1

Write-Host ""
Write-Host "Get-AccountSDDL: (system accounts)"
Write-Host "***********************************"

$SDDL2 = Get-AccountSDDL @("NT AUTHORITY\SYSTEM", "NT AUTHORITY\NETWORK SERVICE")
$SDDL2

Write-Host ""
Write-Host "Convert-SDDLToACL"
Write-Host "***********************************"

Convert-SDDLToACL $SDDL1, $SDDL2

Write-Host ""


#
# Unit test for Get-IPAddress
#

Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

Write-Host ""
Write-Host "Get-IPAddress 4"
Write-Host "***************************"

Get-IPAddress 4

Write-Host ""
Write-Host "Get-IPAddress 6"
Write-Host "***************************"

Get-IPAddress 6

Write-Host ""
Write-Host "Get-IPAddress 3"
Write-Host "***************************"

Get-IPAddress 3

Write-Host ""
Write-Host "Failure test"
Write-Host "***************************"

$AdapterConfig = Get-AdapterConfig
Write-Error -Category NotEnabled -TargetObject $AdapterConfig -Message "IPv6 not configured on adapter"

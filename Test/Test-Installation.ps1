
#
# Unit test for Test-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
$OfficeShared = "%ProgramFiles%\Common Files\microsoft shared"

Write-Host ""
Write-Host "Test-Installation 'Office' $OfficeRoot"
Test-Installation "Office" ([ref]$OfficeRoot)

Write-Host "Adjusted install root for 'Office' is $OfficeRoot"
Write-Host ""

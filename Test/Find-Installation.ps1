
#
# Unit test for Find-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule


Write-Host ""
Write-Host "Find-Installation 'Office'"
Write-Host (Find-Installation "Office")

Write-Host ""
Write-Host "Find-Installation 'FailureTest'"
Write-Host (Find-Installation "FailureTest")

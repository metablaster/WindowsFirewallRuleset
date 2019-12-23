
#
# Unit test for Find-Program
#

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule


Write-Host ""
Write-Host "Find-Program 'Office'"
Write-Host (Find-Program "Office")

Write-Host ""
Write-Host "Find-Program 'FailureTest'"
Write-Host (Find-Program "FailureTest")

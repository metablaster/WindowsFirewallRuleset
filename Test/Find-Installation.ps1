
#
# Unit test for Find-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule


Write-Host ""
Write-Host "Find-Installation 'Chrome'"
Write-Host (Find-Installation "Chrome")

Write-Host ""
Write-Host "Find-Installation 'TeamViewer'"
Write-Host (Find-Installation "TeamViewer")

Write-Host ""
Write-Host "Find-Installation 'FailureTest'"
Write-Host (Find-Installation "FailureTest")

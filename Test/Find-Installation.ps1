
#
# Unit test for Find-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo


Write-Host ""
Write-Host "Find-Installation 'Chrome'"
Find-Installation "Chrome"

Write-Host ""
Write-Host "Find-Installation 'TeamViewer'"
Write-Host (Find-Installation "TeamViewer")

Write-Host ""
Write-Host "Find-Installation 'FailureTest'"
Write-Host (Find-Installation "FailureTest")

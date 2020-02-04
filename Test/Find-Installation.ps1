
#
# Unit test for Find-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo


Write-Host ""
Write-Host "Find-Installation 'EdgeChromium'"
Find-Installation "EdgeChromium"

Write-Host ""
Write-Host "Table data"
Write-Host "***************************"
$global:InstallTable | Format-Table -AutoSize

Write-Host ""
Write-Host "Install Root"
Write-Host "***************************"
$global:InstallTable | Select-Object -ExpandProperty InstallRoot

Write-Host ""
Write-Host "Find-Installation 'TeamViewer'"
Write-Host (Find-Installation "TeamViewer")

Write-Host ""
Write-Host "Find-Installation 'FailureTest'"
Write-Host (Find-Installation "FailureTest")

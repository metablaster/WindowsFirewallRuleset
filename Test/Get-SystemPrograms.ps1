
#
# Unit test for Get-SystemPrograms
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

$ComputerName = Get-ComputerName
$SystemPrograms = Get-SystemPrograms $ComputerName

Write-Host ""
Write-Host "Get-SystemPrograms Name"
Write-Host "***************************"
$SystemPrograms | Sort-Object -Property Name | Select-Object -ExpandProperty Name

Write-Host ""
Write-Host "Get-SystemPrograms InstallLocation"
Write-Host "***************************"
$SystemPrograms | Sort-Object -Property InstallLocation | Select-Object -ExpandProperty InstallLocation

Write-Host ""
Write-Host "Get-SystemPrograms"
Write-Host "***************************"
$SystemPrograms | Sort-Object -Property Name

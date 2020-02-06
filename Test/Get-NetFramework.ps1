#
# Unit test for Get-NetFramework
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

Write-Host "Get-NetFramework"
Write-Host "***************************"

$ComputerName = Get-ComputerName

$NETFramework = Get-NetFramework $ComputerName
$NETFramework

# Write-Host "Get-NetFramework latest"
# Write-Host "***************************"
# $NETFramework | Sort-Object -Property Version | Where-Object {$_.InstallPath} | Select-Object -Last 1 -ExpandProperty InstallPath

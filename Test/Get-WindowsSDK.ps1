#
# Unit test for Get-WindowsSDK
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

$ComputerName = Get-ComputerName

Write-Host "Get-WindowsSDK"
Write-Host "***************************"

$WindowsSDK = Get-WindowsSDK $ComputerName

Write-Host "Get-WindowsSDK latest"
Write-Host "***************************"

$WindowsSDK | Sort-Object -Property Version | Where-Object { $_.InstallPath } | Select-Object -Last 1 -ExpandProperty InstallPath


#
# Unit test for Get-SystemPrograms
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

Write-Host "Get-AllUserPrograms"
Write-Host "***************************"

$ComputerName = Get-ComputerName
Get-AllUserPrograms $ComputerName | Sort-Object -Property Name

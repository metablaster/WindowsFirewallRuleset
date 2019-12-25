
#
# Unit test for Get-SystemPrograms
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

Write-Host "Get-SystemPrograms"
Write-Host "***************************"

$ComputerName = Get-ComputerName
Get-SystemPrograms $ComputerName

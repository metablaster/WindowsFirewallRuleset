
#
# Unit test for Get-WindowsKits
#

Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

$ComputerName = Get-ComputerName

Write-Host "Get-WindowsKits"
Write-Host "***************************"

$WindowsKits = Get-WindowsKits $ComputerName
$WindowsKits

# Write-Host "Get-WindowsKits DebuggersRoot latest"
# Write-Host "***************************"

# $WindowsKits | Where-Object {$_.Product -like "WindowsDebuggersRoot*"} | Sort-Object -Property Product | Select-Object -Last 1 -ExpandProperty InstallPath

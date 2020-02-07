
#
# Unit test for Test-Function
#

# Uncomment modules as needed
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\Modules\ComputerInfo

Write-Host ""
Write-Host "Get-WindowsDefender"
Write-Host "***************************"

Get-WindowsDefender (Get-ComputerName) #| Select-Object -ExpandProperty InstallPath

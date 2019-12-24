
#
# Unit test for Get-SystemPrograms
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

Write-Host "Get-SystemPrograms"
$ComputerName = Get-ComputerName
Get-SystemPrograms $ComputerName


#
# Unit test for Get-UserPrograms
#

Import-Module -Name $PSScriptRoot\..\FirewallModule

Write-Host "Get-UserPrograms"
$ComputerName = Get-ComputerName
Get-UserPrograms "$ComputerName\User"

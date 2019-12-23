

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles%\Microsoft Office\root\Office16"
$OfficeShared = "%ProgramFiles%\Common Files\microsoft shared"

Write-Host ""
Write-Host "Test-File '$OfficeShared\ClickToRun\OfficeClickToRun.exe'"
Test-File "$OfficeShared\ClickToRun\OfficeClickToRun.exe"

Write-Host ""
Write-Host "Test-File '%ProgramFiles%\ClickToRun\OfficeClickToRun.exe'"
Test-File "%ProgramFiles%\ClickToRun\OfficeClickToRun.exe"

Write-Host ""


#
# Unit test for Test-File
#

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo

$OfficeShared = "%ProgramFiles%\Common Files\microsoft shared"
$VSInstallService = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\app\ServiceHub\Hosts\Microsoft.ServiceHub.Host.CLR\vs_installerservice.x86.exe"

Write-Host "Installation status for VisualStudioInstaller"
$global:InstallationStatus = $true

Write-Host ""
Write-Host "Test-File '$VSInstallService'"
Test-File "$VSInstallService"

Write-Host ""
Write-Host "Test-File '$OfficeShared\ClickToRun\OfficeClickToRun.exe'"
Test-File "$OfficeShared\ClickToRun\OfficeClickToRun.exe"

Write-Host ""
Write-Host "Test-File '%ProgramFiles%\ClickToRun\OfficeClickToRun.exe'"
Test-File "%ProgramFiles%\ClickToRun\OfficeClickToRun.exe"

Write-Host ""

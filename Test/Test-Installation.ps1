
#
# Unit test for Test-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\FirewallModule

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles(x866666)%\Microsoft Office\root\Office16"
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"
$TestBadVariable = "%UserProfile%\crazyFolder"

Write-Host ""
Write-Host "Test-Installation 'MicrosoftOffice' $OfficeRoot"
Test-Installation "MicrosoftOffice" ([ref]$OfficeRoot) $false

Write-Host ""
Write-Host "Test-Installation 'TeamViewer' $TeamViewerRoot"
Test-Installation "TeamViewer" ([ref]$TeamViewerRoot) $false

Write-Host ""
Write-Host "Test-Installation 'VisualStudio' $TestBadVariable"
Test-Installation "VisualStudio" ([ref]$TestBadVariable) $false

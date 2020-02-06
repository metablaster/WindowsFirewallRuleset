
#
# Unit test for Test-Installation
#

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles(x866666)%\Microsoft Office\root\Office16"
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"
$TestBadVariable = "%UserProfile%\crazyFolder"
$TestBadVariable2 = "%UserProfile%\crazyFolder"

Write-Host ""
Write-Host "Test-Installation 'MicrosoftOffice' $OfficeRoot"
Test-Installation "MicrosoftOffice" ([ref]$OfficeRoot) $false

Write-Host ""
Write-Host "Test-Installation 'TeamViewer' $TeamViewerRoot"
Test-Installation "TeamViewer" ([ref]$TeamViewerRoot) $false

Write-Host ""
Write-Host "Test-Installation 'VisualStudio' $TestBadVariable"
Test-Installation "VisualStudio" ([ref]$TestBadVariable) $false

Write-Host ""
Write-Host "Test-Installation 'BadVariable' $TestBadVariable2"
Test-Installation "BadVariable" ([ref]$TestBadVariable2) $true

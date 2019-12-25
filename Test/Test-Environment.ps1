
#
# Unit test for Test-Environment
#

# Includes
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo

$path1 = "%ProgramFiles%\Common Files\microsoft shared"
$path2 = "%ProgramFiles(x86)%\Microsoft Visual Studio"

Write-Host ""
Write-Host "Test-Environment '$path1'"
Test-Environment "$path1"

Write-Host ""
Write-Host "Test-Environment '$path2'"
Test-Environment "$path2"

Write-Host ""

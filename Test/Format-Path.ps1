
#
# Unit test for Test-Function
#

# Uncomment modules as needed
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo


Write-Host ""
Write-Host "Format-Path"
Write-Host "***************************"
Write-Host ""

$Result = Format-Path "C:\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\\Windows\System32"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Program Files (x86)\Windows Defender\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Program Files\WindowsPowerShell"
$Result
Test-Environment $Result

$Result = Format-Path '"C:\ProgramData\Git"'
$Result
Test-Environment $Result

$Result = Format-Path "C:\PerfLogs"
$Result
Test-Environment $Result

$Result = Format-Path "C:\Windows\Microsoft.NET\Framework64\v3.5"
$Result
Test-Environment $Result

$Result = Format-Path "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
$Result
Test-Environment $Result

$Result = Format-Path "D:\\microsoft\\windows"
$Result
Test-Environment $Result

$Result = Format-Path "D:\"
$Result
Test-Environment $Result

$Result = Format-Path "C:\\"
$Result
Test-Environment $Result

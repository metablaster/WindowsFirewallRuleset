#
# Unit test for Update-Table
#

Import-Module -Name $PSScriptRoot\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo


Write-Host "Initialize-Table"
Write-Host "***************************"

Initialize-Table

if (!$global:InstallTable)
{
    Write-Warning "Table not initialized"
    exit
}

if ($global:InstallTable.Rows.Count -ne 0)
{
    Write-Warning "Table not clear"
    exit
}

Write-Host ""
Write-Host "Fill table with Microsoft Edge"
Write-Host "***************************"
Update-Table "Microsoft Edge"

Write-Host ""
Write-Host "Table data"
Write-Host "***************************"
$global:InstallTable | Format-Table -AutoSize

Write-Host ""
Write-Host "Install Path"
Write-Host "***************************"
$global:InstallTable | Select-Object -ExpandProperty InstallRoot
Write-Host ""

Write-Host ""
Write-Host "Failure Test"
Write-Host "***************************"
Update-Table "Greenshot" $true

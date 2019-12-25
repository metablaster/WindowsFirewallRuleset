
#
# Unit test for Get-UserPrograms
#

Import-Module -Name $PSScriptRoot\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\Modules\ProgramInfo

Write-Host "Get-UserPrograms"
Write-Host "***************************"

foreach ($Account in $UserAccounts)
{
    Write-Host "Programs installed by $Account"
    Get-UserPrograms $Account
}

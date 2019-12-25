
#
# Unit test for Initialize-Table
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
Write-Host "Fill table with data"
Write-Host "***************************"

foreach ($Account in $global:UserAccounts)
{
    Write-Host "User programs for: $Account"
    $UserPrograms = Get-UserPrograms $Account
    
    if ($UserPrograms.Name -contains "Google Chrome")
    {
        # Create a row
        $Row = $global:InstallTable.NewRow()

        # Enter data in the row
        $Row.User = $Account.Split("\")[1]
        $Row.InstallRoot = $UserPrograms | Where-Object { $_.Name -contains "Google Chrome" } | Select-Object -ExpandProperty InstallLocation

        # Add the row to the table
        $global:InstallTable.Rows.Add($Row)
    }
}

Write-Host ""
Write-Host "Table data"
Write-Host "***************************"
$global:InstallTable | Format-Table -AutoSize

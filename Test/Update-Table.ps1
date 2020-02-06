
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

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
Write-Host "Fill table with Greenshot"
Write-Host "***************************"
Update-Table "Greenshot" $true

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

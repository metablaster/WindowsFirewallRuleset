
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
# Unit test for UnloadModules.ps1
#
. $PSScriptRoot\..\UnloadModules.ps1

Write-Host "Import-Module System"
Import-Module -Name $PSScriptRoot\..\Modules\System -Force

Write-Host "Import-Module Test"
Import-Module -Name $RepoDir\Modules\Test -Force

Write-Host "Import-Module UserInfo"
Import-Module -Name $RepoDir\Modules\UserInfo -Force

Write-Host "Import-Module FirewallModule"
Import-Module -Name $RepoDir\Modules\FirewallModule -Force

Write-Host "Import-Module ProgramInfo"
Import-Module -Name $RepoDir\Modules\ProgramInfo -Force

Write-Host "Import-Module ComputerInfo"
Import-Module -Name $RepoDir\Modules\ComputerInfo -Force

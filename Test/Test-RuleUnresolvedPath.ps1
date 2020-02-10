
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
# Unit test for unresolved path
#
. $PSScriptRoot\..\UnloadModules.ps1

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\Modules\System
Test-SystemRequirements

# Includes
. $RepoDir\Test\ContextSetup.ps1
Import-Module -Name $RepoDir\Modules\Test
Import-Module -Name $RepoDir\Modules\UserInfo
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $TestContext $IPVersion $Direction
if (!(Approve-Execute)) { exit }

$DebugPreference = "Continue"

#
# Setup local variables:
#
$Group = "Test - Relative path"
$Profile = "Any"

#
# TargetProgram installation directories
#
$TargetProgramRoot = "C:\Program Files (x86)\Realtek\..\PokerStars.EU"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Rules for TargetProgram
#

New-Test "Relative path"
# Test if installation exists on system
if ((Test-Installation "TargetProgram" ([ref]$TargetProgramRoot)) -or $Force)
{
    $Program = "$TargetProgramRoot\PokerStars.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "TargetProgram" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443, 26002 `
    -LocalUser $UserAccountsSDDL `
    -Description "" | Format-Output
}

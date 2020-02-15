
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
# Not an acctual unit test but a playground for testing stuff out
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
Import-Module -Name $RepoDir\Modules\ComputerInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $TestContext $MyInvocation.MyCommand.Name.TrimEnd(".ps1")
if (!(Approve-Execute)) { exit }

$DebugPreference = "Continue"
$Group = "Test - Multiple package users"
$Profile = "Any"

Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

New-Test "Test all aps for Admins"
$OwnerSID1 = Get-UserSID "Admin"
$OwnerSID2 = Get-UserSID "User"

# looks like not possible to combine rules
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "All store apps" -Program Any -Service Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -Owner @($OwnerSID1, $OwnerSID2) -Package "*" `
-Description "" | Format-Output

Exit-Test

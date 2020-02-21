
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
# Unit test for Test-Installation
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $RepoDir\Test\ContextSetup.ps1
Import-Module -Name $RepoDir\Modules\Test
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\Meta.AllPlatform.Logging
Import-Module -Name $RepoDir\Modules\Meta.AllPlatform.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

#
# Office installation directories
#
$OfficeRoot = "%ProgramFiles(x866666)%\Microsoft Office\root\Office16"
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"
$TestBadVariable = "%UserProfile%\crazyFolder"
$TestBadVariable2 = "%UserProfile%\crazyFolder"

New-Test "Test-Installation 'MicrosoftOffice' $OfficeRoot"
Test-Installation "MicrosoftOffice" ([ref]$OfficeRoot)

New-Test "Test-Installation 'TeamViewer' $TeamViewerRoot"
Test-Installation "TeamViewer" ([ref]$TeamViewerRoot)

New-Test "Test-Installation 'VisualStudio' $TestBadVariable"
Test-Installation "VisualStudio" ([ref]$TestBadVariable)

New-Test "Test-Installation 'BadVariable' $TestBadVariable2"
Test-Installation "BadVariable" ([ref]$TestBadVariable2)

Exit-Test

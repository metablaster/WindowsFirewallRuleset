
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems,
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
# Unit test for Get-NetFramework
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $RepoDir\Test\ContextSetup.ps1
Import-Module -Name $RepoDir\Modules\Test
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\ComputerInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $TestContext $MyInvocation.MyCommand.Name.TrimEnd(".ps1")
if (!(Approve-Execute)) { exit }

$DebugPreference = "Continue"

New-Test "Get-NetFramework"

$ComputerName = Get-ComputerName

# $NETFramework = Get-NetFramework $ComputerName
# $NETFramework

# New-Test "Get-NetFramework latest"
# $NETFramework | Sort-Object -Property Version | Where-Object {$_.InstallPath} | Select-Object -Last 1 -ExpandProperty InstallPath

# New-Test "Get-NetFramework latest version"
# $Version = $NETFramework | Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version
# #$Version | get-member
# $Major, $Minor, $Build, $Revision = $Version.Split(".")
# $Major
# $Minor

# Get latest NET Framework installation directory
$NETFramework = Get-NetFramework $ComputerName
if ($null -ne $NETFramework)
{
	$NETFrameworkRoot = $NETFramework |
	Sort-Object -Property Version |
	Where-Object {$_.InstallPath} |
	Select-Object -Last 1 -ExpandProperty InstallPath

	Write-Debug $NETFrameworkRoot -Debug
	# Edit-Table $NETFrameworkRoot
}

Exit-Test

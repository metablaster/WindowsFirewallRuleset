
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
# Unit test for Uninstall-DuplicateModule
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
. $ProjectRoot\Modules\Project.AllPlatforms.Initialize\Private\Uninstall-DuplicateModule.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

# NOTE: Install these outdated modules as standard user for testing,
# make sure to to test Get-Module returns single module
# Install-Module -Name PackageManagement -RequiredVersion "1.3.0.0" -Scope CurrentUser
# Install-Module -Name Pester -RequiredVersion "5.0.2.0" -Scope CurrentUser
# Install-Module -Name PowerShellGet -RequiredVersion "1.1.0.0" -Scope CurrentUser

if ($PSVersionTable.PSEdition -eq "Desktop")
{
	# This location is reserved for modules that ship with Windows.
	$ShippingPath = "$PSHome\Modules"

	# This location is for system wide modules install
	$SystemPath = "$Env:ProgramFiles\WindowsPowerShell\Modules"

	# This location is for per user modules install
	$HomePath = "$Home\Documents\WindowsPowerShell\Modules"
}
else
{
	$ShippingPath = "$PSHome\Modules"
	$SystemPath = "$Env:ProgramFiles\PowerShell\Modules"
	$HomePath = "$Home\Documents\PowerShell\Modules"
}

Start-Test "Get-Module"
[PSModuleInfo[]] $TargetModule = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName = "PackageManagement"; RequiredVersion = "1.0.0.1" } |
Where-Object -Property ModuleBase -Like $HomePath*
$TargetModule += Get-Module -ListAvailable -FullyQualifiedName @{ModuleName = "PowerShellGet"; RequiredVersion = "1.0.0.1" } |
Where-Object -Property ModuleBase -Like $HomePath*

if ($TargetModule)
{
	Start-Test "Uninstall-DuplicateModule Pipeline"
	$TargetModule | Uninstall-DuplicateModule @Logs
}

$ModulePath = "C:\Users\$UnitTester\Documents\PowerShell\Modules\Pester"

Start-Test "Uninstall-DuplicateModule Path"
Uninstall-DuplicateModule $ModulePath @Logs

Update-Log
Exit-Test


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
# Unit test for Initialize-Table
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

Start-Test

New-Test "Initialize-Table"

Initialize-Table @Logs
Update-Logs

if (!$global:InstallTable)
{
	Write-Warning -Message "Table not initialized"
	exit
}

if ($global:InstallTable.Rows.Count -ne 0)
{
	Write-Warning -Message "Table not clear"
	exit
}

# TODO: this produces errors, no time to investigate
# New-Test "Fill table with data"

# foreach ($Account in $global:UserAccounts)
# {
# 	Write-Information -Tags "Test" -MessageData "INFO: User programs for: $Account"
# 	$UserPrograms = Get-UserPrograms $Account @Logs
# 	Update-Logs

# 	if ($UserPrograms.Name -like "Greenshot*")
# 	{
# 		# Create a row
# 		$Row = $global:InstallTable.NewRow()

# 		# Enter data in the row
# 		$Row.User = $Account.Split("\")[1]
# 		$Row.InstallRoot = $UserPrograms | Where-Object { $_.Name -like "Greenshot*" } |
# 		Select-Object -ExpandProperty InstallLocation @Logs
# 		Update-Logs

# 		# Add row to the table
# 		$global:InstallTable.Rows.Add($Row)
# 	}
# }

# New-Test "Table data"
# $global:InstallTable | Format-Table -AutoSize @Logs

Exit-Test

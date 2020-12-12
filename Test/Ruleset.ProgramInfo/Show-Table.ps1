
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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

<#
.SYNOPSIS
Unit test for Show-Table

.DESCRIPTION
Unit test for Show-Table

.EXAMPLE
PS> .\Show-Table.ps1

.INPUTS
None. You cannot pipe objects to Show-Table.ps1

.OUTPUTS
None. Show-Table.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}
elseif (!((Get-Command -Name Initialize-Table -EA Ignore) -and
		(Get-Command -Name Update-Table -EA Ignore) -and
		(Get-Command -Name Show-Table -EA Ignore) -and
		(Get-Variable -Scope Global -Name InstallTable -EA Ignore)))
{
	Write-Error -Category NotEnabled -TargetObject "Private Functions" `
		-Message "This unit test is missing required private functions, please visit Ruleset.ProgramInfo.psd1 to adjust exports"
	return
}

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

Start-Test "-UserProfile switch Fill table with Greenshot"
Initialize-Table
Update-Table "Greenshot" -UserProfile
Show-Table

Start-Test "Failure Test"
Initialize-Table
Update-Table "Failure" -UserProfile
Show-Table

Start-Test "Test multiple paths"
Initialize-Table
Update-Table "Visual Studio" -UserProfile
Show-Table

Start-Test "-Executables switch - Fill table with PowerShell"
Initialize-Table
Update-Table "PowerShell.exe" -Executable
$Result = Show-Table
$Result

Test-Output $Result -Command Show-Table

Update-Log
Exit-Test

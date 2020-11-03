
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
Unit test for Show-SDDL

.DESCRIPTION
Unit test for Show-SDDL

.EXAMPLE
PS> .\Show-SDDL.ps1

.INPUTS
None. You cannot pipe objects to for Show-SDDL.ps1

.OUTPUTS
None. Show-SDDL.ps1 does not generate any output

.NOTES
None.
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

# Experiment with different path values to see what the ACL objects do
# $TestPath = "C:\Users\" # Not inherited
# TODO: Funny how "C:\Users\Public\Public Desktop\" doesn't work
$TestPath = "C:\Users\Public\Desktop\" # Inherited
# $TestPath = "HKCU:\" # Not Inherited
# $TestPath = "HKCU:\Software" # Inherited
# $TestPath = "HKLM:\" # Not Inherited

Start-Test "Path: $TestPath"

Start-Test "ACL.AccessToString"
$ACL = Get-Acl $TestPath
$ACL.AccessToString

Start-Test "ACL.Access | Format-list *"
$ACL.Access | Format-List *

Start-Test "ACL.SDDL"
$ACL.SDDL

Start-Test "Show-SDDL (pipeline)"
$ACL | Show-SDDL @Logs

Start-Test "Show-SDDL (parameter)"
$Result = Show-SDDL $ACL.SDDL @Logs
$Result

Test-Output $Result -Command Show-SDDL @Logs

Update-Log
Exit-Test

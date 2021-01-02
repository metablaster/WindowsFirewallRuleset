
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for ConvertFrom-SDDL

.DESCRIPTION
Unit test for ConvertFrom-SDDL

.EXAMPLE
PS> .\ConvertFrom-SDDL.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-SDDL.ps1

.OUTPUTS
None. ConvertFrom-SDDL.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

#
# Test groups
#

[string[]] $Group = @("Users", "Administrators")

Start-Test "Get-SDDL: $Group"
$SDDL1 = Get-SDDL -Group $Group
$SDDL1

#
# Test users
#

[string[]] $User = "Administrator", $TestAdmin, $TestUser

Start-Test "Get-SDDL: $User"
$SDDL2 = Get-SDDL -User $User
$SDDL2

#
# Test NT AUTHORITY
#

[string] $NTDomain = "NT AUTHORITY"
[string[]] $NTUser = "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE"


Start-Test "Get-SDDL: $NTDomain"
$SDDL3 = Get-SDDL -Domain $NTDomain -User $NTUser
$SDDL3

#
# Test APPLICATION PACKAGE AUTHORITY
#

[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
[string[]] $AppUser = "Your Internet connection", "Your pictures library"

Start-Test "Get-SDDL -Domain $AppDomain -User $AppUser"
$SDDL4 = Get-SDDL -Domain $AppDomain -User $AppUser
$SDDL4

#
# Test paths
#

$FileSystem = "C:\Users\Public\Desktop\" # Inherited
$Registry = "HKLM:\SOFTWARE\Microsoft\Clipboard"

Start-Test "Get-SDDL -Path FileSystem"
$SDDL5 = Get-SDDL -Path $FileSystem
$SDDL5

Start-Test "Get-SDDL -Path Registry"
$SDDL6 = Get-SDDL -Path $Registry
$SDDL6

#
# Test convert
#

Start-Test "ConvertFrom-SDDL SDDL1, SDDL2, SDDL3"
$Result = ConvertFrom-SDDL $SDDL1, $SDDL2, $SDDL3
$Result

Test-Output $Result -Command ConvertFrom-SDDL

# Start-Test "ConvertFrom-SDDL pipeline"
# $Result = $SDDL1, $SDDL2, $SDDL3 | ConvertFrom-SDDL
# $Result

# Test-Output $Result -Command ConvertFrom-SDDL

Start-Test "ConvertFrom-SDDL Store apps"
$Result = ConvertFrom-SDDL $SDDL4
$Result

Test-Output $Result -Command ConvertFrom-SDDL

Start-Test "ConvertFrom-SDDL file path"
ConvertFrom-SDDL $SDDL5

Start-Test "ConvertFrom-SDDL file path"
$Result = ConvertFrom-SDDL $SDDL6
$Result

Test-Output $Result -Command ConvertFrom-SDDL

Update-Log
Exit-Test

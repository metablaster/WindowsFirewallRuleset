
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

# Initialization
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ((Get-Item $PSCommandPath).Basename)

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $PSScriptRoot\..\ModulePreferences.ps1

#
# Script imports
#

$PublicScripts = @(
	"ConvertFrom-SID"
	"ConvertFrom-UserAccount"
	"Get-AccountSID"
	"Get-GroupPrincipal"
	"Get-GroupSID"
	"Get-SDDL"
	"Get-UserGroup"
	"Merge-SDDL"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initialize module constant variable: SpecialDomains"
# Must be before constants
# TODO: We need to handle more cases, first 3 are known to work for now
# TODO: Only Get-AccountSID makes use of this, should be inside script?
New-Variable -Name KnownDomains -Scope Script -Option Constant -Value @(
	"NT AUTHORITY"
	"APPLICATION PACKAGE AUTHORITY"
	"BUILTIN"
	"NT SERVICE" # NEW: ex. TrustedInstaller
	# See: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser?view=powershell-5.1
	"MicrosoftAccount"
)

# TODO: global configuration variables (in a separate script)?
if (!(Get-Variable -Name CheckInitUserInfo -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: CheckInitUserInfo"
	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUserInfo -Scope Global -Option Constant -Value $null

	# TODO: should not be used
	# Generate SDDL string for most common groups
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: UsersGroupSDDL"
	New-Variable -Name UsersGroupSDDL -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-32-545)"
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: AdministratorsGroupSDDL"
	New-Variable -Name AdministratorsGroupSDDL -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-32-544)"

	# TODO: shorter names
	# Generate SDDL string for most common system users
	Write-Debug -Message "[$ThisModule] Initialize global constant variables: NT AUTHORITY\..."
	New-Variable -Name NT_AUTHORITY_System -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-18)"
	New-Variable -Name NT_AUTHORITY_LocalService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-19)"
	New-Variable -Name NT_AUTHORITY_NetworkService -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-20)"
	New-Variable -Name NT_AUTHORITY_UserModeDrivers -Scope Global -Option Constant -Value "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
}

#
# System users SDDL strings
#

<# naming convention for common variables, parameters and aliases
type variable, parameter, alias - type[] ArrayVariable, ArrayParameters, alias

UserName / UserNames
UserGroup / UserGroups / Group
UserAccount / UserAccounts / Account

GroupUser / GroupUsers

ComputerName / ComputerNames / Computer, Server, Machine, Host


AccountSID / AccountsSID
GroupSID / GroupsSID

AccountSDDL/ AccountsSDDL
GroupSDDL / GroupsSDDL


SHOULD NOT BE USED:

UserSID / UsersSID
UserSDDL / UsersSDDL

FOR GLOBAL/SCRIPT VARIABLES:
<group_name>GroupSDDL
<user_account>AccountSDDL

SHOULD NOT BE USED IN GLOBAL/SCRIPT scopes
<user_name>UserSID
#>

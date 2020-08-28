
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InsideModule $true
. $PSScriptRoot\..\ModulePreferences.ps1

# TODO: get a user account that is connected to a Microsoft account. see Get-LocalUser docs.

#
# Script imports
#

$PublicScripts = @(
	"ConvertFrom-UserAccount"
	"Get-AccountSID"
	"Get-GroupPrincipal"
	"Get-GroupSID"
	"Get-SDDL"
	"Merge-SDDL"
	"Get-UserGroup"
	"ConvertFrom-SID"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: $Script.ps1"
	. ("{0}\Public\{1}.ps1" -f $PSScriptRoot, $Script)
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initialize module constant variable: SpecialDomains"
# Must be before constants
# TODO: there must be a better more conventional name for this
# TODO: We need to handle more cases, these 3 are known to work for now
# TODO: only Get-AccountSID makes use of this, should be inside script?
New-Variable -Name SpecialDomains -Scope Script -Option Constant -Value @(
	"NT AUTHORITY"
	"APPLICATION PACKAGE AUTHORITY"
	"BUILTIN"
	"NT SERVICE" # NEW: ex. TrustedInstaller
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
	New-Variable -Name UsersGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Users" -Computer $PolicyStore)
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: AdministratorsGroupSDDL"
	New-Variable -Name AdministratorsGroupSDDL -Scope Global -Option Constant -Value (Get-SDDL -Group "Administrators" -Computer $PolicyStore)

	# TODO: replace with function calls
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

# [System.Security.Principal.WellKnownSidType]::NetworkSid
# "D:(A;;CC;;;S-1-5-0)" # Unknown
# $NT_AUTHORITY_DialUp = "D:(A;;CC;;;S-1-5-1)"
# $NT_AUTHORITY_Network = "D:(A;;CC;;;S-1-5-2)"
# $NT_AUTHORITY_Batch = "D:(A;;CC;;;S-1-5-3)"
# $NT_AUTHORITY_Interactive = "D:(A;;CC;;;S-1-5-4)"
# "D:(A;;CC;;;S-1-5-5)" # Unknown
# $NT_AUTHORITY_Service = "D:(A;;CC;;;S-1-5-6)"
# $NT_AUTHORITY_AnonymousLogon = "D:(A;;CC;;;S-1-5-7)"
# $NT_AUTHORITY_Proxy = "D:(A;;CC;;;S-1-5-8)"
# $NT_AUTHORITY_EnterpriseDomainControllers = "D:(A;;CC;;;S-1-5-9)"
# $NT_AUTHORITY_Self = "D:(A;;CC;;;S-1-5-10)"
# $NT_AUTHORITY_AuthenticatedUsers = "D:(A;;CC;;;S-1-5-11)"
# $NT_AUTHORITY_Restricted = "D:(A;;CC;;;S-1-5-12)"
# $NT_AUTHORITY_TerminalServerUser = "D:(A;;CC;;;S-1-5-13)"
# $NT_AUTHORITY_RemoteInteractiveLogon = "D:(A;;CC;;;S-1-5-14)"
# $NT_AUTHORITY_ThisOrganization = "D:(A;;CC;;;S-1-5-15)"
# "D:(A;;CC;;;S-1-5-16)" # Unknown
# $NT_AUTHORITY_Iusr = "D:(A;;CC;;;S-1-5-17)"
# $NT_AUTHORITY_System = "D:(A;;CC;;;S-1-5-18)"
# $NT_AUTHORITY_LocalService = "D:(A;;CC;;;S-1-5-19)"
# $NT_AUTHORITY_NetworkService = "D:(A;;CC;;;S-1-5-20)"
# "D:(A;;CC;;;S-1-5-21)" ENTERPRISE_READONLY_DOMAIN_CONTROLLERS (S-1-5-21-<root domain>-498)
# $NT_AUTHORITY_EnterpriseReadOnlyDomainControllersBeta = "D:(A;;CC;;;S-1-5-22)"
# "D:(A;;CC;;;S-1-5-23)" # Unknown

# Application packages
# $APPLICATION_PACKAGE_AUTHORITY_AllApplicationPackages = "D:(A;;CC;;;S-1-15-2-1)"
# $APPLICATION_PACKAGE_AUTHORITY_AllRestrictedApplicationPackages = "D:(A;;CC;;;S-1-15-2-2)"
# "D:(A;;CC;;;S-1-15-2-3)" # Unknown

# Other System Users
# $NT_AUTHORITY_UserModeDrivers = "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"


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

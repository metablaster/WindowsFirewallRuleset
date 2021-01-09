
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

#region Initialization
param (
	[Parameter()]
	[switch] $ListPreference
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule -ListPreference:$ListPreference

if ($ListPreference)
{
	# NOTE: Preferences defined in caller scope are not inherited, only those defined in
	# Config\ProjectSettings.ps1 are pulled into module scope
	Write-Debug -Message "[$ThisModule] InformationPreference in module: $InformationPreference" -Debug
	Show-Preference # -All
	Remove-Module -Name Dynamic.Preference
}
#endregion

#
# Script imports
#

$PublicScripts = @(
	"ConvertFrom-SDDL"
	"ConvertFrom-SID"
	"Get-GroupPrincipal"
	"Get-GroupSID"
	"Get-PrincipalSID"
	"Get-SDDL"
	"Get-UserGroup"
	"Merge-SDDL"
	"Split-Principal"
	"Test-Credential"
	"Test-UPN"
)

foreach ($Script in $PublicScripts)
{
	try
	{
		. "$PSScriptRoot\Public\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Public\$Script.ps1' $($_.Exception.Message)"
	}
}

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# Must be before constants
# TODO: We need to handle more cases, first 3 are known to work for now
# TODO: Only Get-PrincipalSID makes use of this, should be inside script?
New-Variable -Name KnownDomains -Scope Script -Option Constant -Value @(
	"NT AUTHORITY"
	"APPLICATION PACKAGE AUTHORITY"
	"BUILTIN"
	"NT SERVICE"
	# See: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser?view=powershell-5.1
	"MicrosoftAccount"
)

if (!(Get-Variable -Name CheckInitUserInfo -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initializing module constants"

	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUserInfo -Scope Global -Option Constant -Value $null

	# Generate SDDL string for the most common user groups
	New-Variable -Name UsersGroupSDDL -Scope Global -Option Constant -Value (
		Get-SDDL -Group "Users"
	)

	New-Variable -Name AdminGroupSDDL -Scope Global -Option Constant -Value (
		Get-SDDL -Group "Administrators"
	)

	# Generate SDDL string for the most common system users
	New-Variable -Name LocalSystem -Scope Global -Option Constant -Value (
		Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM"
	)

	New-Variable -Name LocalService -Scope Global -Option Constant -Value (
		Get-SDDL -Domain "NT AUTHORITY" -User "LOCAL SERVICE"
	)

	New-Variable -Name NetworkService -Scope Global -Option Constant -Value (
		Get-SDDL -Domain "NT AUTHORITY" -User "NETWORK SERVICE"
	)
}

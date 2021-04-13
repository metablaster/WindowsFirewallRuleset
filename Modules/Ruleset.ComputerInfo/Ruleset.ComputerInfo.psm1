
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

# TODO: Functions for remote administration should be part of new module "Ruleset.NetworkInfo"

#
# Script imports
#

$PublicScripts = @(
	"ConvertFrom-OSBuild"
	"Get-InterfaceAlias"
	"Get-InterfaceBroadcast"
	"Get-SystemSKU"
	"Resolve-Host"
	"Select-IPInterface"
	"Test-DnsName"
	"Test-NetBiosName"
	"Test-Computer"
	"Test-UNC"
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

# Reserved words for computers and domain names in Active Directory
# The list is for Windows Server 2003 and later
New-Variable -Name ReservedName -Scope Script -Option Constant -Value @(
	"ANONYMOUS"
	"AUTHENTICATED USER"
	"BATCH"
	"BUILTIN"
	"CREATOR GROUP"
	"CREATOR GROUP SERVER"
	"CREATOR OWNER"
	"CREATOR OWNER SERVER"
	"DIALUP"
	"DIGEST AUTH"
	"INTERACTIVE"
	"INTERNET"
	"LOCAL"
	"LOCAL SYSTEM"
	"NETWORK"
	"NETWORK SERVICE"
	"NT AUTHORITY"
	"NT DOMAIN"
	"NTLM AUTH"
	"NULL"
	"PROXY"
	"REMOTE INTERACTIVE"
	"RESTRICTED"
	"SCHANNEL AUTH"
	"SELF"
	"SERVER"
	"SERVICE"
	"SYSTEM"
	"TERMINAL SERVER"
	"THIS ORGANIZATION"
	"USERS"
	"WORLD"
)

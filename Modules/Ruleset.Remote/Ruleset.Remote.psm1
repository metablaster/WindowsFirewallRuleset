
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule

if ($ListPreference)
{
	# NOTE: Preferences defined in caller scope are not inherited, only those defined in
	# Config\ProjectSettings.ps1 are pulled into module scope
	Write-Debug -Message "[$ThisModule] InformationPreference in module: $InformationPreference" -Debug
	Show-Preference # -All
	Remove-Module -Name Dynamic.Preference
}
#endregion

# TODO: Function to restore WinRM service to default needed

#
# Script imports
#

$PrivateScripts = @(
	"Initialize-WinRM"
	"Restore-NetProfile"
	"Unblock-NetProfile"
)

foreach ($Script in $PrivateScripts)
{
	try
	{
		. "$PSScriptRoot\Private\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Private\$Script.ps1' $($_.Exception.Message)"
	}
}

$PublicScripts = @(
	"Connect-Computer"
	"Deploy-SshKey"
	"Disable-WinRMServer"
	"Disconnect-Computer"
	"Enable-RemoteRegistry"
	"Enable-WinRMServer"
	"Register-SslCertificate"
	"Set-WinRMClient"
	"Show-WinRMConfig"
	"Test-WinRM"
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

# Timeout to start and stop WinRM service
New-Variable -Name ServiceTimeout -Scope Script -Value "00:00:20"

# Firewall rules needed to be present to configure some of the WinRM options
New-Variable -Name WinRMRules -Scope Script -Value "@FirewallAPI.dll,-30267"
New-Variable -Name WinRMCompatibilityRules -Scope Script -Value "@FirewallAPI.dll,-30252"

# Work Station (1)
# Domain Controller (2)
# Server (3)
New-Variable -Name Workstation -Scope Script -Option Constant -Value (
	(Get-CimInstance -ClassName Win32_OperatingSystem -EA Stop |
		Select-Object -ExpandProperty ProductType) -eq 1)

New-Variable -Name WinRM -Scope Script -Value (Get-Service -Name WinRM)


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
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSAvoidGlobalAliases", "", Justification = "Global alias is wanted in this case")]
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

$PrivateScripts = @(
	"Set-Privilege"
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
	"Approve-Execute"
	"Build-ServiceList"
	"Compare-Path"
	"Confirm-FileEncoding"
	"ConvertFrom-Wildcard"
	"Get-FileEncoding"
	"Get-TypeName"
	"Invoke-Process"
	"Out-DataTable"
	"Resolve-FileSystemPath"
	"Select-EnvironmentVariable"
	"Set-NetworkProfile"
	"Set-Permission"
	"Set-ScreenBuffer"
	"Set-Shortcut"
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
# Module aliases
#

New-Alias -Name gt -Value Get-TypeName -Scope Global

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# Default execution context, used in Approve-Execute
New-Variable -Name PreviousContext -Scope Script -Value "Context not set"

if (!(Get-Variable -Name CheckInitUtility -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initializing module constants"

	# check if constants already initialized, used for module reloading
	New-Variable -Name CheckInitUtility -Scope Global -Option Constant -Value $null

	# Most used program
	# TODO: Should be part of ProgramInfo, which means importing module
	New-Variable -Name ServiceHost -Scope Global -Option Constant -Value "%SystemRoot%\System32\svchost.exe"
}

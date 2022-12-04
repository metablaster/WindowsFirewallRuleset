
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the Apache license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Apache License

Copyright (C) 2015 Dave Wyatt

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

# NOTE: Following modifications by metablaster done to original PolicyFileEditor module November 2022:
# - Removed DSC related code because it's not needed
# - Separated every function into it's own script
# - Added module boilerplate code
# - Generated help content and markdown help files
# - Performed code formatting and formatting of help files and comment based help
# - Added source code for PolFileEditor.dll
# - Modified *.psd file
# - Renamed module to Ruleset.PolicyFileEditor

#region Initialization
param (
	[Parameter()]
	[switch] $ListPreference
)

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$dllPath = Join-Path $scriptRoot PolFileEditor.dll
Add-Type -Path $dllPath -ErrorAction Stop

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
	"Assert-InvalidDataTypeCombinationErrorRecord"
	"Assert-ValidDataAndType"
	"Build-KeyValueName"
	"Confirm-AdminTemplateCseGuidsArePresent"
	"Convert-PolicyEntryToPsObject"
	"Convert-PolicyEntryTypeToRegistryValueKind"
	"Convert-UInt16PairToUInt32"
	"Convert-UInt32ToUInt16Pair"
	"Get-EntryData"
	"Get-NewVersionNumber"
	"Get-PolicyFilePath"
	"Get-SidForAccount"
	"New-GptIni"
	"Open-PolicyFile"
	"Save-PolicyFile"
	"Test-DataIsEqual"
	"Update-GptIniVersion"
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
	"Get-PolicyFileEntry"
	"Remove-PolicyFileEntry"
	"Set-PolicyFileEntry"
	"Update-GptIniVersion"
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

New-Variable -Name MachineExtensionGuids -Scope Script -Value "[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F72-3407-48AE-BA88-E8213C6761F1}]"
New-Variable -Name UserExtensionGuids -Scope Script -Value "[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{D02B1F73-3407-48AE-BA88-E8213C6761F1}]"


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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

# TODO: If this is based on 3rd party module, include *.psm1 file changes here

#region Initialization
# TODO: Remove using statement
# NOTE: Do not use namespace here ex. "using namespace Microsoft.PowerShell.Commands" must be
# specified in a single place which is module file but it won't work.
# In other cases using namespace per file is more descriptive
using namespace System

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

# TODO: Remove unneeded template code

#
# Script imports
#

Write-Debug -Message "[$ThisModule] Dotsourcing scripts"

# Additional scripts from Scripts directory
$ScriptsToProcess = @(
)

foreach ($Script in $ScriptsToProcess)
{
	try
	{
		. "$PSScriptRoot\Scripts\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Scripts\$Script.ps1' $($_.Exception.Message)"
	}
}

# Private function scripts which should not be exported
$PrivateScripts = @(
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

# Public function scripts which should be exported
$PublicScripts = @(
	"New-Function"
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

# NOTE: Without explicit Export-ModuleMember in addition to FunctionsToExport = @() in manifest file
# verbose messages show private function exports even though they are not accessible and also
# verbose messages will read "Exporting function" in addition to "Importing function" resulting nn
# redundant verbose output
Export-ModuleMember -Function $PublicScripts

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# Template variable
New-Variable -Name TemplateModuleVariable -Scope Script -Value $null
Export-ModuleMember -Variable TemplateModuleVariable

#
# Module aliases
#

Write-Debug -Message "[$ThisModule] Creating aliases"
New-Alias -Name tv -Value TemplateModuleVariable
Export-ModuleMember -Alias tv

#
# Module cleanup
#

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	Write-Debug -Message "[$ThisModule] Performing module cleanup"

	# Do module cleanup here is necessary...
}

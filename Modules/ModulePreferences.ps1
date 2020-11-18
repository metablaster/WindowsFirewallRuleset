
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Script module preferences

.DESCRIPTION
At the moment used only for testing purposes

.EXAMPLE
PS> .\ModulePreferences.ps1

.INPUTS
None. You cannot pipe objects to ModulePreferences.ps1

.OUTPUTS
None. ModulePreferences.ps1 does not generate any output

.NOTES
TODO: Preferences not set/used because valid only for script modules which should not be present
in this project
TODO: If a script module is present in project make use of Scripts\Get-CallerPreference
#>

Set-StrictMode -Version Latest

# if ($Develop)
# {
# 	$ErrorActionPreference = $ModuleErrorPreference
# 	$WarningPreference = $ModuleWarningPreference
# 	$DebugPreference = $ModuleDebugPreference
# 	$VerbosePreference = $ModuleVerbosePreference
# 	$InformationPreference = $ModuleInformationPreference
# }
# else
# {
# 	# Everything is default except InformationPreference should be enabled
# 	$InformationPreference = "Continue"
# }

if ($ShowPreference)
{
	Write-Debug -Message "[$ThisModule] DebugPreference after import: $DebugPreference" -Debug
	Show-Preference -Target $ThisModule # -All
}

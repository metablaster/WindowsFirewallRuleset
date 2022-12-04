
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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

# NOTE: This file is intentionally associated to "test_file" in vscode settings to avoid generating
# PSScriptAnalyzer warnings.
# To use it uncomment "test_file" line in .vscode\settings.json and invoke analyzer on module
# this way Config/PSScriptAnalyzerSettings.psd1 as well as PS extension squiggles are tested for
# code analysis.

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 -InModule -ListPreference:$ListPreference

. "$PSScriptRoot\PssaTest.ps1"

# "PSUseToExportFieldsInManifest"
# NOTE: This is detected if analysing *.psd1 manifest file
FunctionsToExport = $null

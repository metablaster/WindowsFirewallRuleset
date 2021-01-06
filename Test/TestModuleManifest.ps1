
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Unit test to test out module manifests

.DESCRIPTION
Verifies that a module manifest files accurately describe the contents of project modules
For binary files also verify digital signature is valid

.EXAMPLE
PS> .\TestModuleManifest.ps1

.INPUTS
None. You cannot pipe objects to TestModuleManifest.ps1

.OUTPUTS
None. TestModuleManifest.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

if ($PSVersionTable.PSEdition -eq "Desktop")
{
	# NOTE: Ruleset.Compatibility requires PowerShell Core
	$Manifests = Get-ChildItem -Name -Depth 1 -Recurse -Path "$ProjectRoot\Modules" -Filter "*.psd1" -Exclude "*Ruleset.Compatibility*"
}
else
{
	$Manifests = Get-ChildItem -Name -Depth 1 -Recurse -Path "$ProjectRoot\Modules" -Filter "*.psd1"
}

[string[]] $GUID = @()

foreach ($Manifest in $Manifests)
{
	# Check minefest file is OK
	Test-ModuleManifest -Path $ProjectRoot\Modules\$Manifest

	[PSModuleInfo] $Module = Get-Module -ListAvailable -Name $ProjectRoot\Modules\$Manifest
	[string] $ThisGUID = $Module | Select-Object -ExpandProperty GUID
	[string] $HelpInfo = "$($Module.ModuleBase)\$($Module.Name)_$($ThisGUID)_HelpInfo.xml"

	# Check HelpInfo file exists and is properly named
	if (!(Test-Path -Path $HelpInfo))
	{
		Write-Error -Category InvalidResult -TargetObject $HelpInfo `
			-Message "HelpInfo file doesn't exist for module $($Module.Name) with GUID: $ThisGUID"
	}

	# Check no module with duplicate GUID exists among modules
	if ([array]::Find($GUID, [System.Predicate[string]] { $ThisGUID -eq $args[0] }))
	{
		Write-Error -Category InvalidData -TargetObject $ThisGUID -Message "Duplicate GUID: $ThisGUID"
	}

	$GUID += $ThisGUID
}

# Check digital signature of binary files
$VSSetupDLL = @(
	"$ProjectRoot\Modules\VSSetup\Microsoft.VisualStudio.Setup.Configuration.Interop.dll"
	"$ProjectRoot\Modules\VSSetup\Microsoft.VisualStudio.Setup.PowerShell.dll"
)

Get-AuthenticodeSignature -FilePath $VSSetupDLL | Select-Object -Property StatusMessage, Path

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Unit test to test module exports

.DESCRIPTION
Unit test to test module export of all modules in repository

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-ModuleVariables.ps1

.INPUTS
None. You cannot pipe objects to Test-ModuleVariables.ps1

.OUTPUTS
None. Test-ModuleVariables.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

# User prompt
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

$TotalFunctions = 0
$TotalVariables = 0
$TotalAliases = 0

<#
.SYNOPSIS
Get exported symbols from module

.DESCRIPTION
Helper function to get exported symbols from module

.PARAMETER Module
Module object which to process

.PARAMETER Property
Type of exported command

.PARAMETER Count
Expected count of exported command types

.EXAMPLE
PS> $Module = Get-Module Ruleset.Compatibility
PS> Get-Export $Module "Variables"

.NOTES
General notes
#>
function private:Get-Export
{
	[CmdletBinding(PositionalBinding = $false)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PSModuleInfo[]] $Module,

		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("Functions", "Variables", "Aliases")]
		[string] $Property,

		[Parameter(Mandatory = $true)]
		[uint32] $Count
	)

	begin
	{
		if ($Property -eq "Functions")
		{
			$ExportedProperty = "ExportedCommands"
		}

		$ExportedProperty = $Property.Insert(0, "Exported")
	}

	process
	{

		foreach ($ModuleItem in $Module)
		{
			Start-Test "$($ModuleItem.Name) - $Property"

			[array] $Exports = $ModuleItem | Select-Object -ExpandProperty $ExportedProperty |
			Select-Object -ExpandProperty Values | Select-Object -ExpandProperty Name

			if (!$Exports)
			{
				Write-Information -Tags "Test" -MessageData "INFO: No $($Property.ToLower()) are exported from $ModuleItem"
				continue
			}
			else
			{
				# Exclude aliases from ExportedCommands
				if ($Property -eq "Functions")
				{
					$AliasItem = @()
					foreach ($ExportedItem in $Exports)
					{
						$CurrentAliasItem = Get-Alias -Name $ExportedItem -ErrorAction Ignore
						if ($CurrentAliasItem)
						{
							$AliasItem += $CurrentAliasItem
						}
					}

					$AliasCount = ($AliasItem | Measure-Object).Count
					if ($AliasCount -gt 0)
					{
						$Exports = $Exports | Where-Object {
							$_ -notin $AliasItem.Name
						}
					}
				}

				if ($Exports.Count -ne $Count)
				{
					Write-Error -Category InvalidResult -TargetObject $ModuleItem -ErrorAction Stop `
						-Message "Unexpected count of exported $($Property.ToLower()), ($($Exports.Count) $($Property.ToLower()) instead of $Count)"
				}
				else
				{
					if ($Property -eq "Functions")
					{
						$script:TotalFunctions += $Exports.Count
						Write-Output $Exports
					}
					else
					{
						foreach ($ExportedItem in $Exports)
						{
							if ($Property -eq "Variables")
							{
								++$script:TotalVariables
								Write-Information -Tags "Test" -MessageData "INFO: Value of '$ExportedItem' is:"
								(Get-Variable -Name $ExportedItem).Value
							}
							else
							{
								++$script:TotalAliases
								(Get-Alias -Name $ExportedItem).DisplayName
							}

							Write-Output ""
						}
					}
				}
			}
		}
	}
}

#
# Cleanup
#

Start-Test "Remove all modules"
Get-Module -Name Ruleset.* | ForEach-Object {
	Write-Information -Tags "Test" -MessageData "INFO: Removing module $_"
	Remove-Module -Name $_ -Force -ErrorAction Stop
}

#
# Ruleset.Compatibility
#

if ($PSVersionTable.PSEdition -eq "Core")
{
	$Module = Import-Module -Name Ruleset.Compatibility -PassThru

	$Module | Get-Export Functions -Count 8
	$Module | Get-Export Variables -Count 0
	$Module | Get-Export Aliases -Count 1

	Remove-Module -Name Ruleset.Compatibility -Force
}

#
# Ruleset.ComputerInfo
#

$Module = Import-Module -Name Ruleset.ComputerInfo -PassThru

$Module | Get-Export Functions -Count 10
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.ComputerInfo -Force

#
# Ruleset.Firewall
#

$Module = Import-Module -Name Ruleset.Firewall -PassThru

$Module | Get-Export Functions -Count 10
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.Firewall -Force

#
# Ruleset.Initialize
#

$Module = Import-Module -Name Ruleset.Initialize -PassThru

$Module | Get-Export Functions -Count 8
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.Initialize -Force

#
# Ruleset.IP
#

$Module = Import-Module -Name Ruleset.IP -PassThru

$Module | Get-Export Functions -Count 15
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.IP -Force

#
# Ruleset.Logging
#

$Module = Import-Module -Name Ruleset.Logging -PassThru

$Module | Get-Export Functions -Count 2
$Module | Get-Export Variables -Count 1
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.Logging -Force

#
# Ruleset.PolicyFileEditor
#

$Module = Import-Module -Name Ruleset.PolicyFileEditor -PassThru

$Module | Get-Export Functions -Count 4
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.PolicyFileEditor -Force

#
# Ruleset.ProgramInfo
#

$Module = Import-Module -Name Ruleset.ProgramInfo -PassThru

if ($Develop)
{
	$Module | Get-Export Functions -Count 26
	$Module | Get-Export Variables -Count 1
}
else
{
	$Module | Get-Export Functions -Count 22
	$Module | Get-Export Variables -Count 0
}

$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.ProgramInfo -Force

#
# Ruleset.Remote
#

$Module = Import-Module -Name Ruleset.Remote -PassThru

$Module | Get-Export Functions -Count 16
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.Remote -Force

#
# Ruleset.Test
#

$Module = Import-Module -Name Ruleset.Test -PassThru

$Module | Get-Export Functions -Count 8
$Module | Get-Export Variables -Count 0
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.Test -Force

#
# Ruleset.UserInfo
#

$Module = Import-Module -Name Ruleset.UserInfo -PassThru

$Module | Get-Export Functions -Count 13
$Module | Get-Export Variables -Count 5
$Module | Get-Export Aliases -Count 0

Remove-Module -Name Ruleset.UserInfo -Force

#
# Ruleset.Utility
#

$Module = Import-Module -Name Ruleset.Utility -PassThru

$Module | Get-Export Functions -Count 17
$Module | Get-Export Variables -Count 1
$Module | Get-Export Aliases -Count 1

Remove-Module -Name Ruleset.Utility -Force

#
# Ruleset.VSSetup
#

$Module = Import-Module -Name VSSetup -PassThru

$Module | Get-Export Functions -Count 2
$Module | Get-Export Variables -Count 1
$Module | Get-Export Aliases -Count 0

Remove-Module -Name VSSetup -Force

#
# Cleanup
#

Start-Test "Remove all modules"
Get-Module -Name Ruleset.* | ForEach-Object {
	Write-Information -Tags "Test" -MessageData "INFO: Removing module $_"
	Remove-Module -Name $_ -Force -ErrorAction Stop
}

Write-Information -Tags "Test" `
	-MessageData "INFO: In total there are $TotalFunctions functions, $TotalVariables variables and $TotalAliases aliases exported from all modules"

Update-Log
Exit-Test

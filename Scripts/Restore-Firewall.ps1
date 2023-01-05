
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.15.0

.GUID 705cd3b9-ff1f-452d-bd44-09ed8e26a70d

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility, Ruleset.Firewall
#>

<#
.SYNOPSIS
Restore previously saved firewall rules and configuration

.DESCRIPTION
Restore-Firewall script imports all firewall rules and configuration which was previously exported
with Backup-Firewall.ps1
It is recommended to reset firewall prior to restore which will make import process much faster.

.PARAMETER Domain
Computer name on which to restore firewall from file

.PARAMETER Path
Path to directory where the exported settings file is located.
By default this is Exports directory in repository.
Wildcard characters are supported.

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions.
Force should be also specified to replace existing firewall rules that are
duplicate of the ones to be imported.

.EXAMPLE
PS> Restore-Firewall -Force

.EXAMPLE
PS> Restore-Firewall -Domain Server01 -Path "C:\MyExports"

.INPUTS
None. You cannot pipe objects to Restore-Firewall.ps1

.OUTPUTS
None. Restore-Firewall.ps1 does not generate any output

.NOTES
TODO: It needs to be tested exporting with PS Core and importing with Windows PS or vice versa,
there could be problem due to file encoding.
TODO: Import is as slow as Deploy-Firewall, we can make it ultra fast by importing or replacing
rules directly in registry, but care needs to be taken of rule and group GUID names.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
[OutputType([void])]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[SupportsWildcards()]
	[System.IO.DirectoryInfo] $Path,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project

# User prompt
$Accept = "Accpet importing firewall rules and settings from file"
$Deny = "Abort operation, no firewall rules and settings will be imported"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if (!$Path)
{
	# We can't use it as default parameter prior to Config\ProjectSettings
	$Path = "$ProjectRoot\Exports"
}
else
{
	$Path = Resolve-FileSystemPath $Path
	if (!$Path)
	{
		# Errors if any, reported by Resolve-FileSystemPath
		return
	}
}

# TODO: file existence checks such as this one, there should be utility function for this
$FilePath = "$Path\FirewallRules.csv"
if (!(Test-Path -Path $FilePath -PathType Leaf))
{
	Write-Error -Category ObjectNotFound -TargetObject $FilePath `
		-Message "Cannot find path '$FilePath' because it does not exist"
	return
}

$FilePath = "$Path\FirewallSettings.json"
if (!(Test-Path -Path $FilePath -PathType Leaf))
{
	Write-Error -Category ObjectNotFound -TargetObject $FilePath `
		-Message "Cannot find path '$FilePath' because it does not exist"
	return
}

$StopWatch = [System.Diagnostics.Stopwatch]::new()
$StopWatch.Start()

# Import all firewall rules to GPO
Import-FirewallRule -Path $Path -FileName "FirewallRules.csv" -Domain $Domain -Force:$Force
Import-FirewallSetting -Path $Path -FileName "FirewallSettings.json" -Domain $Domain

$StopWatch.Stop()

$TotalHours = $StopWatch.Elapsed | Select-Object -ExpandProperty Hours
$TotalMinutes = $StopWatch.Elapsed | Select-Object -ExpandProperty Minutes
$TotalSeconds = $StopWatch.Elapsed | Select-Object -ExpandProperty Seconds
Write-Information -Tags $ThisScript -MessageData "INFO: Time needed to import firewall was: $TotalHours hours, $TotalMinutes minutes and $TotalSeconds seconds"

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
	Disconnect-Computer -Domain $PolicyStore
}

Update-Log

<# STATS for Import-FirewallRule
NOTE: import speed is 26 rules per minute, slowed down by "Test-Computer" for store app rules
450 rules in 17 minutes on 3,6 Ghz quad core CPU with 16GB single channel RAM @2400 Mhz
NOTE: to speed up a little add the following to defender exclusions:
C:\Windows\System32\wbem\WmiPrvSE.exe
#>

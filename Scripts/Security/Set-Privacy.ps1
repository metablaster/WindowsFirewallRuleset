
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

<#PSScriptInfo

.VERSION 0.14.0

.GUID 3fad2dc6-8724-4cdb-ab3b-15b399e5d45c

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Configure Windows privacy

.DESCRIPTION
Configures Windows privacy in a restrictive way

.PARAMETER Domain
Computer name on which to configure privacy options

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Set-Privacy

.EXAMPLE
PS> Set-Privacy -Domain Server01

.INPUTS
None. You cannot pipe objects to Set-Privacy.ps1

.OUTPUTS
None. Set-Privacy.ps1 does not generate any output

.NOTES
TODO: More Windows privacy options can be set in GPO

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://gpsearch.azurewebsites.net
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project -Strict

$Domain = Format-ComputerName $Domain

# User prompt
$Accept = "Configure Windows privacy options on '$Domain' computer"
$Deny = "Abort operation, no Windows privacy options will be modified on '$Domain' computer"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

if ($PSCmdlet.ShouldProcess("Operating system", "Configure Windows privacy"))
{
	# GPO\Computer configuration
	$PolicyPath = "$env:WinDir\System32\GroupPolicy\Machine\Registry.pol"

	#
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Camera
	#

	Write-Information -MessageData "[$ThisScript] Allow Use of Camera"
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Camera"
	$ValueName = "AllowCamera"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Credential User Interface
	#

	Write-Information -MessageData "[$ThisScript] Enumerate administrator accounts on elevation"
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Microsoft\Windows\CurrentVersion\Policies\CredUI"
	$ValueName = "EnumerateAdministrators"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Data Collection and Preview Builds
	#

	Write-Information -MessageData "[$ThisScript] Allow device name to be sent in Windows diagnostic data"
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows\DataCollection"
	$ValueName = "AllowDeviceNameInTelemetry"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	#
	# GPO: Computer Configuration\Administrative Templates\Control Panel\Personalization
	#

	if ($false)
	{
		# NOTE: This doesn't work as expected, lock screen is shown regardless of what's set
		Write-Information -MessageData "[$ThisScript] Do not display the lock screen"
		# Enabled Value: decimal: 1
		# Disabled Value: decimal: 0
		$RegistryPath = "Software\Policies\Microsoft\Windows\Personalization"
		$ValueName = "NoLockScreen"
		$Value = 1
		$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
		Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind
	}

	#
	# GPO: Computer Configuration\Administrative Templates\Windows Components\Search
	#

	Write-Information -MessageData "[$ThisScript] Allow Cortana"
	# Enabled Value: decimal: 1
	# Disabled Value: decimal: 0
	$RegistryPath = "Software\Policies\Microsoft\Windows\Windows Search"
	$ValueName = "allowcortana"
	$Value = 0
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::DWord
	Set-PolicyFileEntry -Path $PolicyPath -Key $RegistryPath -ValueName $ValueName -Data $Value -Type $ValueKind

	# Update changes done to registry
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Disconnect-Computer -Domain $PolicyStore
Update-Log

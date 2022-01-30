
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

<#
.SYNOPSIS
Export firewall settings and profile setup to file

.DESCRIPTION
Export-FirewallSetting exports all firewall settings to file excluding firewall rules

.PARAMETER Domain
Computer name from which to export settings, default is local GPO.

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, json format

.EXAMPLE
PS> Export-FirewallSetting

.INPUTS
None. You cannot pipe objects to Export-FirewallSetting

.OUTPUTS
None. Export-FirewallSetting does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallSetting.md
#>
function Export-FirewallSetting
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallSetting.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[string] $FileName = "FirewallSettings.json"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall profile..."

	$Setting = Get-NetFirewallProfile -PolicyStore $PolicyStore -Name Private
	[hashtable] $PrivateProfile = @{
		Name = $Setting.Name
		Enabled = $Setting.Enabled
		DefaultInboundAction = $Setting.DefaultInboundAction
		DefaultOutboundAction = $Setting.DefaultOutboundAction
		AllowInboundRules = $Setting.AllowInboundRules
		AllowLocalFirewallRules = $Setting.AllowLocalFirewallRules
		AllowLocalIPsecRules = $Setting.AllowLocalIPsecRules
		AllowUserApps = $Setting.AllowUserApps
		AllowUserPorts = $Setting.AllowUserPorts
		AllowUnicastResponseToMulticast = $Setting.AllowUnicastResponseToMulticast
		NotifyOnListen = $Setting.NotifyOnListen
		EnableStealthModeForIPsec = $Setting.EnableStealthModeForIPsec
		LogFileName = $Setting.LogFileName
		LogMaxSizeKilobytes = $Setting.LogMaxSizeKilobytes
		LogAllowed = $Setting.LogAllowed
		LogBlocked = $Setting.LogBlocked
		LogIgnored = $Setting.LogIgnored
		DisabledInterfaceAliases = $Setting.DisabledInterfaceAliases
	}

	$Setting = Get-NetFirewallProfile -PolicyStore $PolicyStore -Name Public
	[hashtable] $PublicProfile = @{
		Name = $Setting.Name
		Enabled = $Setting.Enabled
		DefaultInboundAction = $Setting.DefaultInboundAction
		DefaultOutboundAction = $Setting.DefaultOutboundAction
		AllowInboundRules = $Setting.AllowInboundRules
		AllowLocalFirewallRules = $Setting.AllowLocalFirewallRules
		AllowLocalIPsecRules = $Setting.AllowLocalIPsecRules
		AllowUserApps = $Setting.AllowUserApps
		AllowUserPorts = $Setting.AllowUserPorts
		AllowUnicastResponseToMulticast = $Setting.AllowUnicastResponseToMulticast
		NotifyOnListen = $Setting.NotifyOnListen
		EnableStealthModeForIPsec = $Setting.EnableStealthModeForIPsec
		LogFileName = $Setting.LogFileName
		LogMaxSizeKilobytes = $Setting.LogMaxSizeKilobytes
		LogAllowed = $Setting.LogAllowed
		LogBlocked = $Setting.LogBlocked
		LogIgnored = $Setting.LogIgnored
		DisabledInterfaceAliases = $Setting.DisabledInterfaceAliases
	}

	$Setting = Get-NetFirewallProfile -PolicyStore $PolicyStore -Name Domain
	[hashtable] $DomainProfile = @{
		Name = $Setting.Name
		Enabled = $Setting.Enabled
		DefaultInboundAction = $Setting.DefaultInboundAction
		DefaultOutboundAction = $Setting.DefaultOutboundAction
		AllowInboundRules = $Setting.AllowInboundRules
		AllowLocalFirewallRules = $Setting.AllowLocalFirewallRules
		AllowLocalIPsecRules = $Setting.AllowLocalIPsecRules
		AllowUserApps = $Setting.AllowUserApps
		AllowUserPorts = $Setting.AllowUserPorts
		AllowUnicastResponseToMulticast = $Setting.AllowUnicastResponseToMulticast
		NotifyOnListen = $Setting.NotifyOnListen
		EnableStealthModeForIPsec = $Setting.EnableStealthModeForIPsec
		LogFileName = $Setting.LogFileName
		LogMaxSizeKilobytes = $Setting.LogMaxSizeKilobytes
		LogAllowed = $Setting.LogAllowed
		LogBlocked = $Setting.LogBlocked
		LogIgnored = $Setting.LogIgnored
		DisabledInterfaceAliases = $Setting.DisabledInterfaceAliases
	}

	[hashtable] $FirewallProfile = @{}
	$FirewallProfile.Add("Private", $PrivateProfile)
	$FirewallProfile.Add("Public", $PublicProfile)
	$FirewallProfile.Add("Domain", $DomainProfile)

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall global settings..."
	$Setting = Get-NetFirewallSetting -PolicyStore $PolicyStore
	[hashtable] $FirewallSetting = @{
		Name = $Setting.Name
		Exemptions = $Setting.Exemptions
		EnableStatefulFtp = $Setting.EnableStatefulFtp
		EnableStatefulPptp = $Setting.EnableStatefulPptp
		ActiveProfile = $Setting.ActiveProfile
		RemoteMachineTransportAuthorizationList = $Setting.RemoteMachineTransportAuthorizationList
		RemoteMachineTunnelAuthorizationList = $Setting.RemoteMachineTunnelAuthorizationList
		RemoteUserTransportAuthorizationList = $Setting.RemoteUserTransportAuthorizationList
		RemoteUserTunnelAuthorizationList = $Setting.RemoteUserTunnelAuthorizationList
		RequireFullAuthSupport = $Setting.RequireFullAuthSupport
		CertValidationLevel = $Setting.CertValidationLevel
		AllowIPsecThroughNAT = $Setting.AllowIPsecThroughNAT
		MaxSAIdleTimeSeconds = $Setting.MaxSAIdleTimeSeconds
		KeyEncoding = $Setting.KeyEncoding
		EnablePacketQueuing = $Setting.EnablePacketQueuing
	}

	$JsonData = @{}
	$JsonData.Add("FirewallProfile", $FirewallProfile)
	$JsonData.Add("FirewallSetting", $FirewallSetting)

	$Path = Resolve-FileSystemPath $Path -Create
	if (!$Path)
	{
		# Errors if any, reported by Resolve-FileSystemPath
		return
	}

	# NOTE: Split-Path -Extension is not available in Windows PowerShell
	$FileExtension = [System.IO.Path]::GetExtension($FileName)

	# Output rules in JSON format
	if (!$FileExtension -or ($FileExtension -ne ".json"))
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
		$FileName += ".json"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing JSON file"
	$JsonData | ConvertTo-Json -Depth 3 | Set-Content -Path "$Path\$FileName" -Encoding $DefaultEncoding
}

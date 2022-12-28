
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
Computer name from which firewall settings are to be exported

.PARAMETER Path
Path into which to save file.
Wildcard characters are supported.

.PARAMETER FileName
Output file name, json format

.PARAMETER Force
If specified does not prompt to replace existing file.

.EXAMPLE
PS> Export-FirewallSetting

.EXAMPLE
PS> Export-FirewallSetting -Path "C:\DirectoryName\filename.json" -Force

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
		[string] $FileName = "FirewallSettings.json",

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

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
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension .json to input file"
		$FileName += ".json"
	}

	$DestinationFile = "$Path\$FileName"
	$FileExists = Test-Path -Path $DestinationFile -PathType Leaf

	if ($FileExists)
	{
		if (!($Force -or $PSCmdlet.ShouldContinue($DestinationFile, "Replace existing export file?")))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Exporting firewall settings to '$FileName' was aborted"
			return
		}
	}

	#region ExportSettings
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall profile from '$Domain' computer..."

	$Setting = Get-NetFirewallProfile -PolicyStore $Domain -Name Private
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

	$Setting = Get-NetFirewallProfile -PolicyStore $Domain -Name Public
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

	$Setting = Get-NetFirewallProfile -PolicyStore $Domain -Name Domain
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

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting global firewall settings from '$Domain' computer..."
	$Setting = Get-NetFirewallSetting -PolicyStore $Domain
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
	#endregion

	$JsonData = @{}
	$JsonData.Add("FirewallProfile", $FirewallProfile)
	$JsonData.Add("FirewallSetting", $FirewallSetting)

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Writing settings to '$FileName'"
	$JsonData | ConvertTo-Json -Depth 3 | Set-Content -Path $DestinationFile -Encoding $DefaultEncoding

	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Exporting firewall settings to '$FileName' done"
}

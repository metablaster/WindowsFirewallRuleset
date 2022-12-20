
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
Import firewall settings and profile setup to file

.DESCRIPTION
Import-FirewallSetting imports all firewall settings from file previously exported by
Export-FirewallSetting

.PARAMETER Path
Path to directory where the exported settings file is located.
Wildcard characters are supported.

.PARAMETER FileName
Input file

.EXAMPLE
PS> Import-FirewallSetting

.INPUTS
None. You cannot pipe objects to Import-FirewallSetting

.OUTPUTS
None. Import-FirewallSetting does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallSetting.md
#>
function Import-FirewallSetting
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallSetting.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter()]
		[string] $FileName = "FirewallSettings"
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$Path = Resolve-FileSystemPath $Path
	if (!$Path -or !$Path.Exists)
	{
		Write-Error -Category ResourceUnavailable -Message "The path was not found: $Path"
		return
	}

	# NOTE: Split-Path -Extension is not available in Windows PowerShell
	$FileExtension = [System.IO.Path]::GetExtension($FileName)

	# read JSON file
	if (!$FileExtension)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Adding extension to input file"
		$FileName += ".json"
	}
	elseif ($FileExtension -ne ".json")
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Unexpected file extension '$FileExtension'"
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Reading JSON file"
	Confirm-FileEncoding "$Path\$FileName"
	$Settings = Get-Content "$Path\$FileName" -Encoding $DefaultEncoding | ConvertFrom-Json

	$LogSize = 4096
	foreach ($Profile in $Settings.FirewallProfile)
	{
		$Profile | Get-ObjectMember | ForEach-Object {
			$Data = $_.Value
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Importing $($Data.Name) firewall profile..."

			if ($Data.LogMaxSizeKilobytes -eq "NotConfigured")
			{
				# MSDN: NotConfigured: Valid only when configuring a Group Policy Object (GPO)
				# This parameter values is case sensitive and NotConfigured can only be specified using dot-notation.
				# The default setting when managing a computer is 4096
				# When managing a GPO, the default setting is NotConfigured.
				$Data.LogMaxSizeKilobytes = $LogSize
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to restore LogMaxSizeKilobytes to NotConfigured, setting to $LogSize"
			}

			Set-NetFirewallProfile -Profile $Data.Name -PolicyStore $PolicyStore `
				-Enabled $Data.Enabled -DefaultInboundAction $Data.DefaultInboundAction `
				-DefaultOutboundAction $Data.DefaultOutboundAction -AllowInboundRules $Data.AllowInboundRules `
				-AllowLocalFirewallRules $Data.AllowLocalFirewallRules -AllowLocalIPsecRules $Data.AllowLocalIPsecRules `
				-NotifyOnListen $Data.NotifyOnListen -EnableStealthModeForIPsec $Data.EnableStealthModeForIPsec `
				-AllowUnicastResponseToMulticast $Data.AllowUnicastResponseToMulticast `
				-LogAllowed $Data.LogAllowed -LogBlocked $Data.LogBlocked `
				-LogIgnored $Data.LogIgnored -LogMaxSizeKilobytes $Data.LogMaxSizeKilobytes `
				-AllowUserApps $Data.AllowUserApps -AllowUserPorts $Data.AllowUserPorts `
				-LogFileName $Data.LogFileName -DisabledInterfaceAliases $Data.DisabledInterfaceAliases
		}
	}

	$Data = $Settings.FirewallSetting
	Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Importing global firewall settings..."

	if ($Data.MaxSAIdleTimeSeconds -eq "NotConfigured")
	{
		# MSDN: NotConfigured: Valid only when configuring a Group Policy Object (GPO)
		# This parameter values is case sensitive and NotConfigured can only be specified using dot-notation.
		# The default value when managing a local computer is 300 seconds (5 minutes).
		# When managing a GPO, the default value is NotConfigured.
		$Data.MaxSAIdleTimeSeconds = 300
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to restore MaxSAIdleTimeSeconds to NotConfigured, setting to 300"
	}

	Set-NetFirewallSetting -PolicyStore $PolicyStore `
		-EnableStatefulFtp $Data.EnableStatefulFtp -EnableStatefulPptp $Data.EnableStatefulPptp `
		-EnablePacketQueuing $Data.EnablePacketQueuing `
		-Exemptions $Data.Exemptions -CertValidationLevel $Data.CertValidationLevel `
		-KeyEncoding $Data.KeyEncoding -RequireFullAuthSupport $Data.RequireFullAuthSupport `
		-MaxSAIdleTimeSeconds $Data.MaxSAIdleTimeSeconds -AllowIPsecThroughNAT $Data.AllowIPsecThroughNAT `
		-RemoteUserTransportAuthorizationList $Data.RemoteUserTransportAuthorizationList `
		-RemoteUserTunnelAuthorizationList $Data.RemoteUserTunnelAuthorizationList `
		-RemoteMachineTransportAuthorizationList $Data.RemoteMachineTransportAuthorizationList `
		-RemoteMachineTunnelAuthorizationList $Data.RemoteMachineTunnelAuthorizationList
}

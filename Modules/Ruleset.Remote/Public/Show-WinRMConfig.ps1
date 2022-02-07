
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021, 2022 metablaster zebal@protonmail.ch

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
Show WinRM service configuration

.DESCRIPTION
Various commands such as "winrm get winrm/config" will show all the data but will also include
containers, WSMan provider is also not universal, and you need to run different commands to get
desired results or values from sub containers.

Some of the WinRM options are advanced and not easily discoverable or often used, as such these
can cause isssues hard to debug due to WinRM service misconfiguration.

Show-WinRMConfig does all this, by harvesting all important and relevant information and
excludes\includes containers by specifying few switches, all of which is then sorted so that it
can be compared with other working configurations to quickly discover problems.

.PARAMETER Server
Display WinRM server configuration.
This includes configuration that is essential to accept remote commands.

.PARAMETER Client
Display WinRM client configuration.
This includes configuration that is essential to send remote commands.

.PARAMETER Detailed
Display additional WinRM configuration not handled by -Server and -Client switches.

.EXAMPLE
PS> Show-WinRMConfig

Without any switches it will show only status of the WinRM service and status of firewall rules

.EXAMPLE
PS> Show-WinRMConfig -Server -Detailed

.EXAMPLE
PS> Show-WinRMConfig -Client

.INPUTS
None. You cannot pipe objects to Show-WinRMConfig

.OUTPUTS
[System.Xml.XmlElement]
[Selected.System.Xml.XmlElement]
[Microsoft.WSMan.Management.WSManConfigLeafElement]

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Show-WinRMConfig.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
winrm get winrm/config
#>
function Show-WinRMConfig
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Show-WinRMConfig.md")]
	[OutputType([System.Xml.XmlElement], [Microsoft.WSMan.Management.WSManConfigLeafElement])]
	param (
		[Parameter()]
		[switch] $Server,

		[Parameter()]
		[switch] $Client,

		[Parameter()]
		[switch] $Detailed
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: WinRM service status=$($WinRM.Status) startup=$($WinRM.StartType)"

	$Present = $false
	$Enabled = $false
	$Rules = Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore

	if ($Rules)
	{
		$Present = $true
		$Enabled = $null -eq ($Rules.Enabled | Where-Object { $_ -eq "False" })
	}

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: WinRM firewall rules present=$Present allenabled=$Enabled"

	$Present = $false
	$Enabled = $false
	$Rules = Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -EA Ignore

	if ($Rules)
	{
		$Present = $true
		$Enabled = $null -eq ($Rules.Enabled | Where-Object { $_ -eq "False" })
	}

	Write-Information -Tags $MyInvocation.InvocationName `
		-MessageData "INFO: WinRM compatibility firewall rules present=$Present allenabled=$Enabled"

	# To start it, it must not be disabled
	if ($WinRM.StartType -eq [ServiceStartMode]::Disabled)
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Setting WinRM service to manual startup"
		Set-Service -InputObject $WinRM -StartupType Manual
	}

	if ($WinRM.Status -ne [ServiceControllerStatus]::Running)
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Starting WinRM service"
		$WinRM.Start()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
	}

	# MSDN: Select-Object, beginning in PowerShell 6,
	# it is no longer required to include the Property parameter for ExcludeProperty to work.
	if ($Server)
	{
		# TODO: Custom object and numbered Permission.Split(",")
		# winrm get winrm/config
		Write-Information -Tags $MyInvocation.InvocationName `
			-MessageData "INFO: Showing all enabled session configurations (short version)"
		Get-PSSessionConfiguration | Where-Object -Property Enabled -EQ True |
		Select-Object -Property Name, lang, Enabled, PSVersion, SDKVersion, Architecture,
		Capability, SupportsOptions, AutoRestart, OutputBufferingMode, RunAsUser, RunAsPassword,
		RunAsVirtualAccount, RunAsVirtualAccountGroups, Permission

		# winrm enumerate winrm/config/listener
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing configured listeners"
		Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate |
		Select-Object -Property LocalName, lang, Address, Transport, Port, Hostname, Enabled,
		URLPrefix, CertificateThumbprint, ListeningOn, IsReadOnly, IsEmpty, HasChildNodes

		# winrm get winrm/config/service
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing server configuration"
		Get-WSManInstance -ResourceURI winrm/config/Service |
		Select-Object -Property LocalName, RootSDDL, MaxConcurrentOperations,
		MaxConcurrentOperationsPerUser, EnumerationTimeoutms, MaxConnections,
		MaxPacketRetrievalTimeSeconds, AllowUnencrypted, IPv4Filter, IPv6Filter,
		EnableCompatibilityHttpListener, EnableCompatibilityHttpsListener, CertificateThumbprint,
		AllowRemoteAccess, IsReadOnly, IsEmpty, HasChildNodes

		# winrm get winrm/config/service/auth
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing server authentication"
		Get-WSManInstance -ResourceURI winrm/config/Service/Auth |
		Select-Object -Property LocalName, lang, Basic, Kerberos, Negotiate, Certificate, CredSSP,
		CbtHardeningLevel, IsReadOnly, IsEmpty, HasChildNodes

		# winrm get winrm/config/service/defaultports
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing server default ports"
		Get-WSManInstance -ResourceURI winrm/config/Service/DefaultPorts |
		Select-Object -Property LocalName, lang, HTTP, HTTPS, IsReadOnly, IsEmpty, HasChildNodes

		$TokenKey = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
		$TokenValue = $TokenKey.GetValue("LocalAccountTokenFilterPolicy")

		if ($null -ne $TokenValue)
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: LocalAccountTokenFilterPolicy value is $TokenValue"
		}
		else
		{
			# For example on fresh installed system
			Write-Warning -Message "[$($MyInvocation.InvocationName)] LocalAccountTokenFilterPolicy value is not present in the registry"
		}
	}

	if ($Client)
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing client configuration"
		Get-WSManInstance -ResourceURI winrm/config/Client |
		Select-Object -Property LocalName, lang, NetworkDelayms, URLPrefix, AllowUnencrypted,
		TrustedHosts, IsReadOnly, IsEmpty, HasChildNodes

		# winrm get winrm/config/client/auth
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing client authentication"
		Get-WSManInstance -ResourceURI winrm/config/Client/Auth |
		Select-Object -Property LocalName, lang, Basic, Digest, Kerberos, Negotiate, Certificate,
		CredSSP, IsReadOnly, IsEmpty, HasChildNodes

		# winrm get winrm/config/client/defaultports
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing client default ports"
		Get-WSManInstance -ResourceURI winrm/config/Client/DefaultPorts |
		Select-Object -Property LocalName, lang, HTTP, HTTPS, IsReadOnly, IsEmpty, HasChildNodes

		$ClientCertificate = Get-Item WSMan:\localhost\ClientCertificate\*
		if ($ClientCertificate)
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Showing client certificate configuration"
			$ClientCertificate
		}
	}

	if ($Detailed)
	{
		# TODO: More configuration data can be harvested here
		Write-Verbose -Message "Showing shell (WinRS) configuration" -Verbose
		# winrm get winrm/config/winrs
		Get-Item WSMan:\localhost\Shell\* | Select-Object -Property Name, Value | Format-Table -AutoSize

		# winrm enumerate winrm/config/plugin
		Write-Verbose -Message "Showing plugin status" -Verbose
		Get-Item WSMan:\localhost\Plugin\* | ForEach-Object {
			$Enabled = Get-Item "WSMan:\localhost\Plugin\$($_.Name)\Enabled" |
			Select-Object -ExpandProperty Value

			[PSCustomObject] @{
				Name = $_.Name
				Enabled = $Enabled
				PSPath = $_.PSPath
			}
		} | Sort-Object -Property Enabled -Descending | Format-Table -AutoSize
	}
}

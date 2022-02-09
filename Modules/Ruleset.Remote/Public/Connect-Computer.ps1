
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
Connect to remote computer

.DESCRIPTION
Connect local machine to local (loopback) or remote computer onto which to deploy firewall.

Following global variables or objects are created:
RemoteCim (CimSession), CIM session object
CimServer (variable), to be used by CIM commandlets to specify cim session to use
RemoteRegistry (PSDrive), administrative share C$ to remote computer (needed for authentication)
RemoteSession (PSSession), PS session object which represent remote session

.PARAMETER Domain
Computer name with which to connect for remoting

.PARAMETER Credential
Specify credentials which to use to test connection to remote computer.
Credentials are required for HTTPS and remote connections.
If not specified, you'll be asked for credentials

.PARAMETER Protocol
Specify protocol to use for connection, HTTP, HTTPS or any.
The default value is "Any" which means HTTPS is used for connection to remote computer
and HTTP for local machine.

.PARAMETER Port
Optionally specify port number if the WinRM server specified by
-Domain parameter listens on non default port

.PARAMETER CertThumbprint
Optionally specify certificate thumbprint which is to be used for HTTPS.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER Authentication
Optionally specify Authentication kind:
None, no authentication is performed, request is anonymous.
Basic, a scheme in which the user name and password are sent in clear text to the server or proxy.
Default, use the authentication method implemented by the WS-Management protocol.
Digest, a challenge-response scheme that uses a server-specified data string for the challenge.
Negotiate, negotiates with the server or proxy to determine the scheme, NTLM or Kerberos.
Kerberos, the client computer and the server mutually authenticate by using Kerberos certificates.
CredSSP, use Credential Security Support Provider (CredSSP) authentication.
The default value is "Default"

.PARAMETER SessionOption
Specify custom PSSessionOption object to use for remoting.
The default value is controlled with PSSessionOption variable from caller scope

.PARAMETER ConfigurationName
Specify session configuration to use for remoting, this session configuration must
be registered and enabled on remote computer.
The default value is controlled with PSSessionConfigurationName preference variable

.PARAMETER ApplicationName
Specify application name use for remote connection,
Currently only "wsman" is supported.
The default value is controlled with PSSessionApplicationName preference variable

.PARAMETER CimOptions
Optionally specify custom CIM session options to fine tune CIM session.
By default new CIM options object is made and set to use SSL if protocol is HTTPS

.EXAMPLE
PS> Connect-Computer COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Connect-Computer

.OUTPUTS
None. Connect-Computer does not generate any output

.NOTES
None.
#>
function Connect-Computer
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Protocol",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Connect-Computer.md")]
	[OutputType([void])]
	param (
		[Parameter(Position = 0)]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[PSCredential] $Credential,

		[Parameter(ParameterSetName = "Protocol")]
		[ValidateSet("HTTP", "HTTPS", "Any")]
		[string] $Protocol = "Any",

		[Parameter()]
		[ValidateRange(1, 65535)]
		[int32] $Port,

		[Parameter(ParameterSetName = "ThumbPrint")]
		[string] $CertThumbprint,

		[ValidateSet("None", "Basic", "CredSSP", "Default", "Digest", "Kerberos", "Negotiate", "Certificate")]
		[string] $Authentication = "Default",

		[Parameter()]
		[System.Management.Automation.Remoting.PSSessionOption]
		$SessionOption = $PSSessionOption,

		[Parameter()]
		[string] $ConfigurationName = $PSSessionConfigurationName,

		[Parameter()]
		[string] $ApplicationName = $PSSessionApplicationName,

		[Parameter()]
		[Microsoft.Management.Infrastructure.Options.CimSessionOptions]
		$CimOptions
	)

	# $DebugPreference = "Continue"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Replace localhost and dot with NETBIOS computer name
	if (($Domain -eq "localhost") -or ($Domain -eq "."))
	{
		$Domain = [System.Environment]::MachineName
	}

	if (Get-Variable -Name SessionEstablished -Scope Global -ErrorAction Ignore)
	{
		if ($Domain -eq $PolicyStore)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Connection already established to '$Domain', run Disconnect-Computer to disconnect"
			return
		}

		Disconnect-Computer $PolicyStore
	}

	if (($Protocol -eq "HTTPS") -and ($Domain -eq [System.Environment]::MachineName))
	{
		Write-Error -Category NotImplemented -TargetObject $Protocol `
			-Message "HTTPS for localhost not implemented"
	}

	$PSSessionParams = @{
		# PS session name
		Name = "RemoteSession"
		ErrorAction = "Stop"
		Port = $Port
		Authentication = $Authentication
		ApplicationName = $ApplicationName
		SessionOption = $SessionOption
		# MSDN: If you specify only the configuration name, the following schema URI is prepended: http://schemas.microsoft.com/PowerShell
		ConfigurationName = $ConfigurationName
	}

	$CimParams = @{
		# CIM session name
		Name = "RemoteCim"
		ErrorAction = "Stop"
		Port = $Port
		SessionOption = $CimOptions
		Authentication = $Authentication
		OperationTimeoutSec = $SessionOption.OperationTimeout.TotalSeconds
	}

	if (![string]::IsNullOrEmpty($CertThumbprint))
	{
		$Protocol = "HTTPS"
		$CimParams["CertificateThumbprint"] = $CertThumbprint
		$PSSessionParams["CertificateThumbprint"] = $CertThumbprint
	}

	if ($Protocol -eq "Any")
	{
		$PSSessionParams["UseSSL"] = $Domain -ne ([System.Environment]::MachineName)
	}
	else
	{
		$PSSessionParams["UseSSL"] = $Protocol -eq "HTTPS"
	}

	if ($Domain -ne [System.Environment]::MachineName)
	{
		if (!$Credential)
		{
			$Credential = Get-Credential -Message "Credentials are required to access '$Domain'"

			if (!$Credential)
			{
				# Will happen if credential request was dismissed using ESC key.
				Write-Error -Category InvalidOperation -TargetObject $Domain -Message "Credentials are required for remote session on '$Domain'"
			}
			elseif ($Credential.Password.Length -eq 0)
			{
				# Will happen when no password is specified
				Write-Error -Category InvalidData -TargetObject $Domain -Message "User '$($Credential.UserName)' must have a password"
				$Credential = $null
			}
		}

		$CimParams["Credential"] = $Credential
		$CimParams["ComputerName"] = $Domain

		$PSSessionParams["Credential"] = $Credential
		$PSSessionParams["ComputerName"] = $Domain
	}

	# Remote computer or localhost over HTTPS
	if ($PSSessionParams["UseSSL"])
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Configuring HTTPS connection"
		if (!$Port)
		{
			$CimParams["Port"] = 5986
			$PSSessionParams["Port"] = 5986
		}

		if (!$CimOptions)
		{
			# TODO: There is global variable for encoding
			$CimParams["SessionOption"] = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture $DefaultUICulture -Culture $DefaultCulture
		}
	}
	else
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Configuring HTTP connection"
		if (!$Port)
		{
			$CimParams["Port"] = 5985
			$PSSessionParams["Port"] = 5985
		}

		if (!$CimOptions)
		{
			$CimParams["SessionOption"] = New-CimSessionOption -Protocol Wsman -UICulture $DefaultUICulture -Culture $DefaultCulture
		}
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] CIM options: $($CimParams["SessionOption"] | Out-String)"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] PS session options: $($SessionOption | Out-String)"

	try
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Creating new CIM session to $Domain"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] CimParams: $($CimParams | Out-String)"

		# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
		# verification is accomplished using a standard WS-Identity operation.
		# MSDN: A CIM session is a client-side object representing a connection to a local computer or a remote computer.
		# NOTE: Specifying computer name may fail if WinRM listens on loopback only
		Set-Variable -Name CimServer -Scope Global -Option ReadOnly -Force -Value (New-CimSession @CimParams)
	}
	catch
	{
		Write-Error -Category ConnectionError -TargetObject $Domain `
			-Message "Creating CIM session to '$Domain' failed with: $($_.Exception.Message)"
		return
	}

	if ($Domain -ne ([System.Environment]::MachineName))
	{
		try
		{
			Write-Information -Tags $MyInvocation.InvocationName `
				-MessageData "INFO: Authenticating '$($Credential.UserName)' to computer '$Domain'"

			# Authentication is required to access remote registry
			# NOTE: Registry provider does not support credentials
			# TODO: More limited drive would be better
			[string] $SystemDrive = Get-CimInstance -Class Win32_OperatingSystem -CimSession $CimServer |
			Select-Object -ExpandProperty SystemDrive
			$SystemDrive = $SystemDrive.TrimEnd(":")

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Remote system drive is $SystemDrive"
			New-PSDrive -Credential $Credential -PSProvider FileSystem -Scope Global -Name RemoteRegistry `
				-Root "\\$Domain\$SystemDrive$" -Description "Remote registry authentication" | Out-Null
		}
		catch
		{
			Remove-CimSession -Name RemoteCim
			Remove-Variable -Name CimServer -Scope Global -Force

			Write-Error -Category AuthenticationError -TargetObject $Credential `
				-Message "Authenticating $($Credential.UserName) to '$Domain' failed with: $($_.Exception.Message)"
			return
		}
	}

	try
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Creating PS session to computer '$Domain'"
		Write-Debug -Message "[$($MyInvocation.InvocationName)] PSSessionParams: $($PSSessionParams | Out-String)"

		New-PSSession @PSSessionParams | Out-Null

		# TODO: For VM without external switch use -VMName
		# TODO: Temporarily not using because not in need to enter session
		# Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Entering remote session to computer '$Domain'"
		# Enter-PSSession -Name RemoteSession
	}
	catch
	{
		Remove-CimSession -Name RemoteCim
		Remove-Variable -Name CimServer -Scope Global -Force

		if (Get-PSDrive -Name RemoteRegistry -Scope Global -ErrorAction Ignore)
		{
			Remove-PSDrive -Name RemoteRegistry -Scope Global
		}

		Write-Error -Category ConnectionError -TargetObject $Domain `
			-Message "Creating PS session to computer '$Domain' failed with: $($_.Exception.Message)"
		return
	}

	Set-Variable -Name SessionEstablished -Scope Global -Option ReadOnly -Value $true
}

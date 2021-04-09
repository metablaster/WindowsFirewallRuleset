
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
WinRM service options

.DESCRIPTION
WinRM service options include, protocol, service, client and winrs settings

.PARAMETER IncludeClient
Include setting that apply to client configuration

.PARAMETER IncludeServer
Include setting that apply to service configuration

.EXAMPLE
PS> .\WinRMSettings.ps1

.INPUTS
None. You cannot pipe objects to WinRMSettings.ps1

.OUTPUTS
None. WinRMSettings.ps1 does not generate any output

.NOTES
TODO: Default options, "Reset" switch
TODO: Not all optional settings are configured
TODO: Client settings are missing for server and vice versa
TODO: WinRS options description

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management
#>

#Requires -Version 5.1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Settings used by other scripts")]
param (
	[Parameter()]
	[switch] $IncludeClient,

	[Parameter()]
	[switch] $IncludeServer
)

# Utility or settings scripts don't do anything on their own
if ($MyInvocation.InvocationName -ne '.')
{
	Write-Error -Category NotEnabled -TargetObject $MyInvocation.InvocationName `
		-Message "This is settings script and must be dot sourced where needed" -EA Stop
}

# Timeout to start and stop WinRM service
$ServiceTimeout = "00:00:30"

# Firewall rules needed to be present to configure some of the WinRM options
$WinRMRules = "@FirewallAPI.dll,-30267"
$WinRMCompatibilityRules = "@FirewallAPI.dll,-30252"

[hashtable] $ProtocolOptions = @{
	# Specifies the maximum Simple Object Access Protocol (SOAP) data in kilobytes.
	# The default is 150 kilobytes.
	MaxEnvelopeSizekb = 150

	# Specifies the maximum time-out, in milliseconds, that can be used for any request other than Pull requests.
	# The default value is 60000.
	MaxTimeoutms = $PSSessionOption.OperationTimeout.TotalMilliseconds

	# Specifies the maximum number of elements that can be used in a Pull response.
	# The default is 32000.
	MaxBatchItems = 32000

	# Specifies the maximum number of concurrent requests that are allowed by the service.
	# The default is 25.
	# NOTE: WinRM 2.0: This setting is deprecated, and is set to read-only.
	# MaxProviderRequests = 25
}

# NOTE: HTTP traffic by default only allows messages encrypted with the Negotiate or Kerberos SSP
[hashtable] $AuthenticationOptions = @{
	# The user name and password are sent in clear text.
	# Basic authentication cannot be used with domain accounts
	# The default value is true.
	Basic = $false
	# Authentication by using Kerberos certificates.
	# By default WinRM uses Kerberos for authentication, which does not support IP addresses.
	# The default value is true.
	Kerberos = $false
	# An alternative to Basic Authentication over HTTPS is Negotiate.
	# The server determines whether to use the Kerberos protocol or NTLM.
	# This results in NTLM authentication between the client and server and payload is encrypted over HTTP.
	# NTLM authentication is used by default whenever you specify an IP address.
	# Use the Credential parameter in all remote commands.
	# The Kerberos protocol is selected to authenticate a domain account, and NTLM is selected for local computer accounts.
	# The default value is true.
	Negotiate = $true
	# Certificate-based authentication is a scheme in which the server authenticates a client
	# identified by an X509 certificate.
	# Certificate requirements:
	# The date of the computer falls between the Valid from: to the To: date on the General tab.
	# Host name matches the Issued to: on the General tab, or it matches one of the
	# Subject Alternative Name exactly as displayed on the Details tab.
	# That the Enhanced Key Usage on the Details tab contains Server authentication.
	# On the Certification Path tab that the Current Status is This certificate is OK.
	# The default value is true.
	Certificate = $false
	# Allows the client to use Credential Security Support Provider (CredSSP) authentication.
	# The default value is false.
	CredSSP = $false
}

if ($IncludeClient)
{
	# Challenge-response scheme that uses a server-specified data string for the challenge.
	# Supported by both HTTP and HTTPS
	# The WinRM service does not accept Digest authentication.
	# The default value is true.
	$AuthenticationOptions["Digest"] = $false
}

if ($IncludeServer)
{
	# Sets the policy for channel-binding token requirements in authentication requests.
	# The default is Relaxed.
	$AuthenticationOptions["CbtHardeningLevel"] = "Relaxed"
}

if ($IncludeClient)
{
	[hashtable] $ClientOptions = @{
		# Specifies the extra time in milliseconds that the client computer waits to accommodate for network delay time.
		# The default value is 5000 milliseconds.
		NetworkDelayms = 1000

		# Specifies a URL prefix on which to accept HTTP or HTTPS requests.
		# The default URL prefix is "wsman".
		URLPrefix = "wsman"

		# MSDN: Allows the client computer to request unencrypted traffic.
		# The default value is false
		AllowUnencrypted = $Protocol -ne "HTTPS"

		# Specifies the ports that the client will use for either HTTP or HTTPS.
		# WinRM 2.0: The default HTTP port is 5985, and the default HTTPS port is 5986.
		# DefaultPorts

		# The TrustedHosts item can contain a comma-separated list of computer names,
		# IP addresses, and fully-qualified domain names. Wildcards are permitted.
		# Affects all users of the computer.
		TrustedHosts = ""
	}
}

if ($IncludeServer)
{
	[hashtable] $ServerOptions = @{
		# NOTE:	AllowRemoteAccess is read only

		# Specifies the security descriptor that controls remote access to the listener.
		# The default is "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)".
		# RootSDDL = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"

		# The maximum number of concurrent operations.
		# The default is 100.
		# WinRM 2.0: The MaxConcurrentOperations setting is deprecated
		# NOTE: MaxConcurrentOperations = 100

		# Specifies the maximum number of concurrent operations that any user can remotely open on the same system.
		# The default is 1500.
		MaxConcurrentOperationsPerUser = 1500

		# Specifies the idle time-out in milliseconds between Pull messages.
		# The default is 60000.
		EnumerationTimeoutms = 6000

		# Specifies the maximum number of active requests that the service can process simultaneously.
		# The default is 300.
		MaxConnections = 300

		# Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
		# The default is 120 seconds.
		MaxPacketRetrievalTimeSeconds = 10

		# Allows the client computer to request unencrypted traffic.
		# The default value is false
		AllowUnencrypted = $true

		# Specifies the IPv4 or IPv6 addresses that listeners can use.
		# IPv4: An IPv4 literal string consists of four dotted decimal numbers, each in the range 0 through 255.
		# Example: 192.168.0.0.
		# The default is: IPv4Filter = *
		IPv4Filter = "*"

		# IPv6: An IPv6 literal string is enclosed in brackets and contains hexadecimal numbers that
		# are separated by colons.
		# Example: [::1] or [3ffe:ffff::6ECB:0101].
		# The default is: IPv6Filter = *
		IPv6Filter = "*"

		# If this setting is True, then the listener will listen on port 80 in addition to port 5985.
		# The default is False.
		EnableCompatibilityHttpListener = $false

		# Specifies whether the compatibility HTTPS listener is enabled.
		# If this setting is True, then the listener will listen on port 443 in addition to port 5986.
		# The default is False.
		EnableCompatibilityHttpsListener = $false
	}
}

[hashtable] $PortOptions = @{
	# Specifies the ports the client and WinRM service will use for either HTTP or HTTPS.
	# WinRM 2.0: The default HTTP port is 5985, and the default HTTPS port is 5986.
	HTTP = 5985
	HTTPS = 5986
}

[hashtable] $WinRSOptions = @{
	AllowRemoteShellAccess = $false
	IdleTimeout = 180000
	MaxConcurrentUsers = 5
	MaxShellRunTime = 28800000
	MaxProcessesPerShell = 15
	MaxMemoryPerShellMB = 150
	MaxShellsPerUser = 5
}

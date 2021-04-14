
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
WinRM service options include protocol, service, client and winrs settings.
Some of which have sub options stored inside "containers".
This script lists all of these by documenting their purpose and defaults.
Main purpose is quick centralized configuration to mimimize the chance of
misconfiguration.
This script is automatically picked up by other WinRM remoting scripts within
this module.

.PARAMETER IncludeClient
Include setting that apply to client configuration

.PARAMETER IncludeServer
Include setting that apply to service configuration

.EXAMPLE
PS> .\WinRMSettings.ps1

Picks up only global options.
Note that it must be dot sourced to pick up modifications.

.EXAMPLE
PS> .\WinRMSettings.ps1 -IncludeClient

Picks up global options and client specific options.

.INPUTS
None. You cannot pipe objects to WinRMSettings.ps1

.OUTPUTS
None. WinRMSettings.ps1 does not generate any output

.NOTES
TODO: Make use of all default values, ex. Restore-WinRM or ResetWinRM
TODO: Client settings are missing for server and vice versa

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
	"PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Settings used by other scripts")]
param (
	[Parameter()]
	[switch] $IncludeClient,

	[Parameter()]
	[switch] $IncludeServer,

	[Parameter()]
	[switch] $Default
)

if (!$Default)
{
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
		# The default value is true according to docs, false according to fresh system.
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

			# The TrustedHosts item can contain a comma-separated list of computer names,
			# IP addresses, and fully-qualified domain names. Wildcards are permitted.
			# Affects all users of the computer.
			TrustedHosts = ""
		}
	}

	if ($IncludeServer)
	{
		# Sets the policy for channel-binding token requirements in authentication requests.
		# The default is Relaxed.
		$AuthenticationOptions["CbtHardeningLevel"] = "Relaxed"

		[hashtable] $ServerOptions = @{
			# NOTE:	AllowRemoteAccess is read only

			# Specifies the security descriptor that controls remote access to the listener.
			# The default according to docs is "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)".
			# Default on fresh server system: "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;IU)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
			# RootSDDL = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"

			# The maximum number of concurrent operations.
			# The default is 100.
			# NOTE: WinRM 2.0: The MaxConcurrentOperations setting is deprecated
			# MaxConcurrentOperations = 100

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
		# Enables access to remote shells.
		# The default is True.
		AllowRemoteShellAccess = $false

		# Specifies the maximum time, in milliseconds, that the remote shell will remain open when
		# there is no user activity in the remote shell
		# WinRM 2.0: The default is 180000. The minimum value is 60000.
		IdleTimeout = 180000

		# Specifies the maximum number of users who can concurrently perform remote operations on
		# the same computer through a remote shell.
		# The default is 5.
		MaxConcurrentUsers = 5

		# Specifies the maximum time, in milliseconds, that the remote command or script is allowed to execute.
		# The default is 28800000.
		# NOTE: WinRM 2.0: The MaxShellRunTime setting is set to read-only.
		MaxShellRunTime = 28800000

		# Specifies the maximum number of processes that any shell operation is allowed to start.
		# A value of 0 allows for an unlimited number of processes.
		# The default is 15.
		MaxProcessesPerShell = 15

		# Specifies the maximum amount of memory allocated per shell, including the shell's child processes.
		# The default is 150 MB.
		MaxMemoryPerShellMB = 150

		# Specifies the maximum number of concurrent shells that any user can remotely open on the same computer.
		# The default is 5 remote shells per user.
		MaxShellsPerUser = 5
	}
}
else
{
	# Default WinRM option values, do not modify except to update wrong defaults
	$ProtocolOptions["MaxEnvelopeSizekb"] = 150
	$ProtocolOptions["MaxTimeoutms"] = 60000
	$ProtocolOptions["MaxBatchItems"] = 32000

	$AuthenticationOptions["Basic"] = $true
	$AuthenticationOptions["Kerberos"] = $true
	$AuthenticationOptions["Negotiate"] = $true
	$AuthenticationOptions["Certificate"] = $true
	$AuthenticationOptions["CredSSP"] = $false

	if ($IncludeClient)
	{
		$AuthenticationOptions["Digest"] = $true

		$ClientOptions["NetworkDelayms"] = 5000
		$ClientOptions["URLPrefix"] = "wsman"
		$ClientOptions["AllowUnencrypted"] = $false
		$ClientOptions["TrustedHosts"] = ""
	}

	if ($IncludeServer)
	{
		$AuthenticationOptions["CbtHardeningLevel"] = "Relaxed"

		$ServerOptions["RootSDDL"] = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)"
		$ServerOptions["MaxConcurrentOperationsPerUser"] = 1500
		$ServerOptions["EnumerationTimeoutms"] = 60000
		$ServerOptions["MaxConnections"] = 300
		$ServerOptions["MaxPacketRetrievalTimeSeconds"] = 120
		$ServerOptions["AllowUnencrypted"] = $false
		$ServerOptions["IPv4Filter"] = " * "
		$ServerOptions["IPv6Filter"] = "*"
		$ServerOptions["EnableCompatibilityHttpListener"] = $false
		$ServerOptions["EnableCompatibilityHttpsListener"] = $false
	}

	$PortOptions["HTTP"] = 5985
	$PortOptions["HTTPS"] = 5986

	$WinRSOptions["AllowRemoteShellAccess"] = $true
	$WinRSOptions["IdleTimeout"] = 180000
	$WinRSOptions["MaxConcurrentUsers"] = 5
	$WinRSOptions["MaxProcessesPerShell"] = 15
	$WinRSOptions["MaxMemoryPerShellMB"] = 150
	$WinRSOptions["MaxShellsPerUser"] = 5
}

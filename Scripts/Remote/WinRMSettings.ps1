
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

.PARAMETER Client
Include setting that apply to client configuration

.PARAMETER Server
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
TODO: Client settings are missing for server

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
	[switch] $Client,

	[Parameter()]
	[switch] $Server
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
	# Specifies the maximum time-out, in milliseconds, that can be used for any request other than Pull requests.
	# The default value is 60000.
	MaxTimeoutms = $PSSessionOption.OperationTimeout.TotalMilliseconds
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

if ($Client)
{
	# Challenge-response scheme that uses a server-specified data string for the challenge.
	# Supported by both HTTP and HTTPS
	# The WinRM service does not accept Digest authentication.
	# The default value is true.
	$AuthenticationOptions["Digest"] = $false
}

if ($Client)
{
	[hashtable] $ClientOptions = @{
		# Specifies the extra time in milliseconds that the client computer waits to accommodate for network delay time.
		# The default value is 5000 milliseconds.
		NetworkDelayms = 1000

		# MSDN: Allows the client computer to request unencrypted traffic.
		# The default value is false
		AllowUnencrypted = $Protocol -ne "HTTPS"

		# The TrustedHosts item can contain a comma-separated list of computer names,
		# IP addresses, and fully-qualified domain names. Wildcards are permitted.
		# Affects all users of the computer.
		TrustedHosts = ""
	}
}

if ($Server)
{
	[hashtable] $ServerOptions = @{
		# NOTE:	AllowRemoteAccess is read only

		# Specifies the maximum length of time, in seconds, the WinRM service takes to retrieve a packet.
		# The default is 120 seconds.
		MaxPacketRetrievalTimeSeconds = 10

		# Specifies the idle time-out in milliseconds between Pull messages.
		# The default is 60000.
		EnumerationTimeoutms = 6000

		# Allows the client computer to request unencrypted traffic.
		# The default value is false
		AllowUnencrypted = $true
	}
}

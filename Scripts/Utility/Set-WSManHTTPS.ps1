
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

<#PSScriptInfo

.VERSION 0.10.1

.GUID 5f0b8c02-a28a-4e8b-b355-7478bc0bd665

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Configure computer for HTTPS remoting

.DESCRIPTION
Configures either remote or management machine for WS-Management via HTTPS.
This script should be run first on remote machine and then on management machine.

.PARAMETER Domain
Computer name which is to be managed remotely.
Certificate store is searched for certificate with CN entry set to this name,
If not found, certificate specified by CertFile is imported.

.PARAMETER LiteralPath
Specifies directory location where to optionally export certificate.
The exported certificate name is equal to remote computer name.

.PARAMETER CertFile
Optionally specify certificate file location of a remote computer.
In both cases, local store is searched for certificate that matches computer specified by
Domain parameter.

.PARAMETER Remote
Should be specified when configuring remote computer

.PARAMETER Force
If specified, overwrites exported certificates and does not prompt to create a listener

.EXAMPLE
PS> .\Set-WSManHTTPS.ps1 -Domain Server01 -LiteralPath "C:\Cert\Server01.cer"

Configures management machine by installing certificate of remote computer

.EXAMPLE
PS> .\Set-WSManHTTPS.ps1 -LiteralPath "C:\Cert\Server01.cer" -Remote

Configures WinRM on remote computer for HTTPS

.INPUTS
None. You cannot pipe objects to Set-WSManHTTPS.ps1

.OUTPUTS
None. Set-WSManHTTPS.ps1 does not generate any output

.NOTES
TODO: Credential should be tested with Test-Credential
TODO: This script must be part of Ruleset.Initialize module

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Local")]
param (
	[Parameter(Mandatory = $true, ParameterSetName = "Local")]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter(ParameterSetName = "Remote")]
	[Alias("LP")]
	[string] $LiteralPath,

	[Parameter(ParameterSetName = "Local")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $Remote,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $Force
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

if ($Remote)
{
	# Remote machine
	$Domain = [System.Environment]::MachineName
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	$CertCount = ($Cert | Measure-Object).Count

	if ($CertCount -gt 1)
	{
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates match"
		return
	}
	elseif ($CertCount -eq 0)
	{
		$Date = Get-Date
		Write-Information -Tags "Project" -MessageData "INFO: Creating new certificate"

		# TODO: -Signer -KeySpec -HashAlgorithm -Subject "localhost"
		$Cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation "Cert:\LocalMachine\My" `
			-FriendlyName "RemoteFirewall" -KeyAlgorithm RSA -KeyDescription "PSRemotingKey" `
			-KeyFriendlyName "RemoteFirewall" -KeyLength 2048 -Type SSLServerAuthentication `
			-KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy ExportableEncrypted `
			-NotBefore $Date -NotAfter $Date.AddMonths(6)
	}
	else
	{
		Write-Information -Tags "Project" -MessageData "INFO: Using existing certificate"
	}

	if (![string]::IsNullOrEmpty($LiteralPath))
	{
		if (!(Test-Path $LiteralPath -PathType Container -ErrorAction Ignore))
		{
			Write-Information -Tags "Project" -MessageData "INFO: Creating new directory $LiteralPath"
			New-Item -Path $LiteralPath -ItemType Directory | Out-Null
		}

		# To be imported by management machine
		Write-Information -Tags "Project" -MessageData "INFO: Exporting certificate '$Domain.cer'"

		$ExportParams = @{
			Cert = $Cert
			FilePath = "$LiteralPath\$Domain.cer"
			Type = "CERT"
		}

		if (!$Force)
		{
			$ExportParams.Add("NoClobber", $true)
		}

		Export-Certificate @ExportParams | Out-Null
	}

	Write-Information -Tags "Project" -MessageData "INFO: Using certificate with thumbprint $($Cert.Thumbprint)"

	# Write-Information -Tags "Project" -MessageData "INFO: Enabling PowerShell remoting"
	# NOTE: Configuring without Enable-PSRemoting
	# Enable-PSRemoting

	# NOTE: Will not work because certificate is self signed
	# Set-WSManQuickConfig -UseSSL

	# Configure HTTPS listener
	# NOTE: WinRM service must be running at this point
	Write-Information -Tags "Project" -MessageData "INFO: Starting WS-Management service"
	Start-Service -Name WinRM
	Get-Service -Name WinRM | Set-Service -StartupType Automatic

	$HTTPS = Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address = "*"; Transport = "HTTPS" }
	$CountHTTPS = ($HTTPS | Measure-Object).Count

	if ($CountHTTPS -gt 1)
	{
		Write-Error -Category NotImplemented -TargetObject $HTTPS -Message "Multiple HTTPS listeners exist"
	}
	elseif ($CountHTTPS -eq 1)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Setting existing HTTPS listener"
		Set-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{ Address = "*"; Transport = "HTTPS" } `
			-ValueSet @{ Enabled = "true"; CertificateThumbprint = $Cert.Thumbprint } | Out-Null
	}
	else
	{
		Write-Information -Tags "Project" -MessageData "INFO: Adding new HTTPS listener"
		New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force:$Force | Out-Null
	}

	# TODO: Other service configuration can be confirmed here
	Set-Item WSMan:\localhost\Service\AllowRemoteAccess -Value "true"
	Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value "false"

	# Remove all HTTP listeners
	Write-Information -Tags "Project" -MessageData "INFO: Removing all HTTP listeners"
	Get-ChildItem WSMan:\localhost\Listener | Where-Object -Property Keys -EQ "Transport=HTTP" | Remove-Item -Recurse

	# Show configured listeners
	Get-WSManInstance winrm/config/listener -Enumerate
	# winrm get winrm/config
}
else
{
	# Management machine
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	if (($Cert | Measure-Object).Count -gt 1)
	{
		# TODO: Search by thumbprint from CertFile if specified or implement parameter for Cert object
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates match"
		return
	}

	if ($Cert)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Certificate for computer '$Domain' already exists"
	}
	elseif ([string]::IsNullOrEmpty($CertFile))
	{
		Write-Error -Category InvalidOperation -Message "Certificate does not exist for computer '$Domain'"
		return
	}
	elseif (Test-Path $CertFile -PathType Leaf -ErrorAction Ignore)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Importing certificate '$CertFile'"
		$Cert = Import-Certificate -FilePath $CertFile -CertStoreLocation "Cert:\LocalMachine\Root"
	}
	else
	{
		Write-Error -Category ObjectNotFound -TargetObject $CertFile -Message "Specified certificate file was not found '$CertFile'"
		return
	}

	Write-Information -Tags "Project" -MessageData "INFO: Contacting computer '$Domain'"

	if (Test-NetConnection -ComputerName $Domain -Port 5986 -InformationLevel Quiet -EA Ignore)
	{
		# Test remote configuration
		Write-Information -Tags "Project" -MessageData "INFO: Using certificate with thumbprint $($Cert.Thumbprint)"
		Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service on computer '$Domain'"
		$RemoteCredential = Get-Credential -Message "Please provide credentials for computer $Domain"
		Test-WSMan -ComputerName $Domain -Credential $RemoteCredential -UseSSL -Authentication Negotiate

		# Eneter remote session
		# $SessionOptions = New-PSSessionOption -SkipCACheck
		Enter-PSSession -ComputerName $Domain -UseSSL -Credential $RemoteCredential # -SessionOption $SessionOptions
		# Exit-PSSession
	}
	elseif (Test-Connection -ComputerName $Domain -Count 2 -Quiet -EA Ignore)
	{
		Write-Error -Category ConnectionError -TargetObject $Domain -Message "WinRM listener on computer $Domain does not respond"
	}
	else
	{
		Write-Error -Category ConnectionError -TargetObject $Domain -Message "Computer $Domain does not respond"
	}
}

Write-Information -Tags "Project" -MessageData "INFO: All operation completed successfully"

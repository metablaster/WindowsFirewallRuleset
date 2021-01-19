
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

.VERSION 0.10.0

.GUID 5f0b8c02-a28a-4e8b-b355-7478bc0bd665

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Configure computer for HTTPS remoting

.DESCRIPTION
Configures either remote or management machine for WS-Management via HTTPS.

.PARAMETER Domain
Target computer name which is to be managed remotely.
Certificate store is searched for certificate with DnsName entry set to this name,
if not found new certificate is created.

.PARAMETER LiteralPath
When run on remote machine, specifies location where to export certificate,
When run on management machine, specifies certificate location to be imported.

.PARAMETER Remote
Should be specified when configuring remote computer

.EXAMPLE
PS> .\Enable-WSMan.ps1 -Domain Server01 -LiteralPath "C:\Cert\Server01.cer"

.EXAMPLE
PS> .\Enable-WSMan.ps1 -LiteralPath "C:\Cert\Server01.cer" -Remote

.INPUTS
None. You cannot pipe objects to Enable-WSMan.ps1

.OUTPUTS
None. Enable-WSMan.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = "Local")]
param (
	# The name of the computer that you want to manage remotely
	[Parameter(Mandatory = $true, ParameterSetName = "Local")]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter(Mandatory = $true)]
	[Alias("LP")]
	[string] $LiteralPath,

	[Parameter(ParameterSetName = "Remote")]
	[switch] $Remote
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

if (!$Remote)
{
	# Management machine
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	if ($Cert)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Certificate for remote computer '$Domain' already exists"
	}
	elseif (Test-Path $LiteralPath -PathType Leaf -ErrorAction Ignore)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Importing certificate '$LiteralPath'"
		Import-Certificate -FilePath $LiteralPath -CertStoreLocation "Cert:\LocalMachine\Root"
	}
	else
	{
		Write-Error -Category ObjectNotFound -TargetObject $LiteralPath -Message "Certificate file not found '$LiteralPath'"
		return
	}

	# Enter remote session
	Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service on computer '$Domain'"
	$RemoteCredential = Get-Credential -Message "Please provide credentials for computer $Domain"
	Test-WSMan -ComputerName $Domain -Credential $RemoteCredential -UseSSL -Authentication Negotiate
	# $SessionOption = New-PSSessionOption -SkipCACheck
	# Enter-PSSession -ComputerName $Domain -UseSSL -Credential (Get-Credential) -SessionOption $SessionOption

	return
}

# Remote machine
$Domain = [System.Environment]::MachineName
$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
	$_.Subject -eq "CN=$Domain"
}

$Count = ($Cert | Measure-Object).Count

if ($Count -gt 1)
{
	Write-Error -Category InvalidResult -TargetObject $Cert -Message "Multiple certificates match"
	return
}
elseif ($Count -eq 0)
{
	Write-Information -Tags "Project" -MessageData "INFO: Creating new certificate"
	$Date = Get-Date

	try
	{
		# TODO: -Signer -KeySpec -HashAlgorithm -Subject "localhost"
		$Cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation "Cert:\LocalMachine\My" `
			-FriendlyName "RemoteFirewall" -KeyAlgorithm RSA -KeyDescription "PSRemotingKey" `
			-KeyFriendlyName "RemoteFirewall" -KeyLength 2048 -Type SSLServerAuthentication `
			-KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy ExportableEncrypted `
			-NotBefore $Date -NotAfter $Date.AddMonths(6)
	}
	catch
	{
		Write-Error -ErrorRecord $_
		return
	}
}

if (!(Test-Path $LiteralPath -PathType Container -ErrorAction Ignore))
{
	Write-Information -Tags "Project" -MessageData "INFO: Creating new directory $LiteralPath"
	New-Item -Path $LiteralPath -ItemType Directory | Out-Null
}

# To be imported by management machine
Write-Information -Tags "Project" -MessageData "INFO: Exporting certificate '$Domain.cer' thumbprint $($Cert.Thumbprint)"
Export-Certificate -Cert $Cert -FilePath $LiteralPath\$Domain.cer -Type CERT -NoClobber | Out-Null

try
{
	Write-Information -Tags "Project" -MessageData "INFO: Enabling PowerShell remoting"
	Enable-PSRemoting
}
catch
{
	Write-Error -ErrorRecord $_
	return
}

# try
# {
#	Write-Information -Tags "Project" -MessageData "INFO: Enabling PowerShell remoting"
# 	# Enable-PSRemoting
# 	Set-WSManQuickConfig -UseSSL
# }
# catch
# {
# 	Write-Error -ErrorRecord $_
# 	return
# }

# Add new HTTPS listener
if (Get-ChildItem WSMan:\localhost\Listener | Where-Object -Property Keys -EQ "Transport=HTTPS")
{
	Write-Warning -Message "HTTPS listener already exists"
}
else
{
	Write-Information -Tags "Project" -MessageData "INFO: Adding new HTTPS listener"
	New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint
}

# Remove all HTTP listeners
Write-Information -Tags "Project" -MessageData "INFO: Removing all HTTP listeners"
Get-ChildItem WSMan:\localhost\Listener | Where-Object -Property Keys -EQ "Transport=HTTP" | Remove-Item -Recurse

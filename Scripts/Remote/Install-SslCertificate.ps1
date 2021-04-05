
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

.GUID 40002e43-f0b1-4afa-b0fb-904896d28af5

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Install SSL certificate for CIM and PowerShell remoting

.DESCRIPTION
Install SSL certificate to be used for encrypted PowerShell remoting.
By default certificate store is searched for existing certificate,
if not found default repository location (\Exports) is searched for certificate file which must have
same name as -Domain parameter value.
Otherwise you can specify your own custom certificate file location.
The script will always attempt to export public key (DER encoded CER file) on server computer
to default repository location, which you should then copy to client machine to be searched for
and used for client authentication.

.PARAMETER Domain
Specify host name which is to be managed remotely from this machine.
This parameter is required only when setting up client computer.
For server -Target this defaults to server NetBios host name.

.PARAMETER Target
Specify current system role which controls script behavior .
This is either Client or Server.

.PARAMETER CertFile
Optionally specify custom certificate file.
By default new self signed certifcate is made and trusted if no suitable certificate exists.
For server -Target this must be PFX file, for client -Target it must be DER encoded CER file

.PARAMETER CertThumbPrint
Optionally specify certificate thumbprint which is to be used for SSL.
Use this parameter when there are multiple certificates with same DNS entries.

.PARAMETER Force
If specified, overwrites an existing exported certificate file,
unless it has the Read-only attribute set.

.EXAMPLE
PS> .\Install-SslCertificate.ps1 -Target Server

Installs existing or new SSL certificate on server computer,
public key is exported to be used on client computer.

.EXAMPLE
PS> .\Install-SslCertificate.ps1 -Target Client -CertFile C:\Cert\Server.cer

Installs specified SSL certificate on client computer.

.EXAMPLE
PS> .\Install-SslCertificate.ps1 -Target Server -CertThumbPrint "96158c29ab14a96892c1a5202058c6fe25f06fd7"

Installs existing SSL certificate with specified thumbprint on the server computer,
public key is exported to be used on client computer.

.INPUTS
None. You cannot pipe objects to Install-SslCertificate.ps1

.OUTPUTS
[System.Security.Cryptography.X509Certificates.X509Certificate2]

.NOTES
TODO: Needs testing with PS Core
TODO: Risk mitigation
HACK: What happens when exporting a certificate that is already installed? (no error is shown)

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts

.LINK
https://docs.microsoft.com/en-us/powershell/module/pkiclient
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
[OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain,

	[Parameter(Mandatory = $true)]
	[ValidateSet("Client", "Server")]
	[string] $Target,

	[Parameter(ParameterSetName = "File")]
	[string] $CertFile,

	[Parameter(ParameterSetName = "ThumbPrint")]
	[string] $CertThumbPrint,

	[Parameter()]
	[switch] $Force
)

. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
Initialize-Project -Strict

$ErrorActionPreference = "Stop"
$ExportPath = "$ProjectRoot\Exports"

if ($Target -eq "Server")
{
	if ($Domain -and ($Domain -ne ([System.Environment]::MachineName)))
	{
		Write-Warning -Message "Domain parameter ignored when target is server"
	}

	$Domain = [System.Environment]::MachineName
}
elseif ([string]::IsNullOrEmpty($Domain))
{
	# TODO: Should be required parameter
	Write-Error -Category InvalidArgument -Message "Please specify remote host name which is to be managed by using -Domain parameter"
}

if ([string]::IsNullOrEmpty($CertFile))
{
	# Search default file name location
	if ($Target -eq "Server")
	{
		$CertFile = "$ExportPath\$Domain.pfx"
		$ExportFile = "$ExportPath\$Domain.cer"
	}
	else
	{
		$CertFile = "$ExportPath\$Domain.cer"
		$ExportFile = $CertFile
	}

	# Search personal store for certificate first
	$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
		$_.Subject -eq "CN=$Domain"
	}

	if (!$Cert)
	{
		$Cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
			$_.Subject -eq "CN=$Domain"
		}
	}

	if ($CertThumbPrint)
	{
		if ($Cert)
		{
			$Cert = $Cert | Where-Object -Property Thumbprint -EQ $CertThumbPrint
		}

		if (!$Cert)
		{
			Write-Error -Category InvalidResult -TargetObject $Cert -Message "Certificate with specified thumbprint not found '$CertThumbPrint'"
		}
	}

	if (($Cert | Measure-Object).Count -eq 1)
	{
		if (Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain -AllowUntrustedRoot)
		{
			if (($Target -eq "Server") -and (!$Cert.HasPrivateKey))
			{
				Write-Error -Category OperationStopped -TargetObject $Cert `
					-Message "Private key is missing for existing certificate '$Domain.cer', please specify thumbprint to select another certificate"
			}
			else
			{
				Write-Information -Tags "Project" -MessageData "INFO: Using existing certificate with thumbprint '$($Cert.thumbprint)'"
			}
		}
		else
		{
			Write-Error -Category SecurityError -TargetObject $Cert -Message "Verification failed for certificate '$($Cert.thumbprint)'"
		}
	}
	elseif ($Cert)
	{
		Write-Error -Category NotImplemented -TargetObject $Cert -Message "Multiple certificates exist for host '$Domain', please specify thumbprint"
	}
	elseif (Test-Path $CertFile -PathType Leaf -ErrorAction Ignore)
	{
		# Import certificate file from default repository location
		if ($Target -eq "Server")
		{
			$CertPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (
				"$Domain.pfx", (Read-Host -AsSecureString -Prompt "Enter password for certificate $Domain.pfx"))

			$Cert = Import-PfxCertificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My `
				-Password $CertPassword.Password -Exportable
		}
		else
		{
			$Cert = Import-Certificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My
		}

		if (($Cert.Subject -ne "CN=$Domain") -or
			($CertThumbPrint -and ($Cert.thumbprint -ne $CertThumbPrint)) -or
			!(Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain -AllowUntrustedRoot))
		{
			# Undo import operation
			Get-ChildItem Cert:\LocalMachine\My |
			Where-Object { $_.Thumbprint -eq $Cert.thumbprint } | Remove-Item
			Write-Error -Category SecurityError -TargetObject $Cert -Message "Certificate verification from default repository location failed"
		}

		Write-Information -Tags "Project" -MessageData "INFO: Using certificate from default repository location '$($Cert.thumbprint)'"
	}
	elseif ($Target -eq "Server")
	{
		# Create new self signed server certificate
		$Date = Get-Date
		Write-Information -Tags "Project" -MessageData "INFO: Creating new certificate"

		# TODO: -Signer -KeySpec -HashAlgorithm -Subject "localhost"
		$Cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation Cert:\LocalMachine\My `
			-FriendlyName "RemoteFirewall" -KeyAlgorithm RSA -KeyDescription "PSRemotingKey" `
			-KeyFriendlyName "RemoteFirewall" -KeyLength 2048 -Type SSLServerAuthentication `
			-KeyUsage DigitalSignature, KeyEncipherment -KeyExportPolicy ExportableEncrypted `
			-NotBefore $Date -NotAfter $Date.AddMonths(6)

		Write-Information -Tags "Project" -MessageData "INFO: Using new certificate with thumbprint '$($Cert.thumbprint)'"
	}
	else
	{
		Write-Error -Category ObjectNotFound -TargetObject $CertFile -Message "No certificate was not found in default repository location"
	}
}
elseif (Test-Path -Path $CertFile -PathType Leaf -ErrorAction Ignore)
{
	# Import certificate file from custom location
	if ($Target -eq "Server")
	{
		$ExportFile = "$ExportPath\$((Split-Path -Path $CertFile -Leaf) -replace '\.pfx$').cer"

		if ($CertFile.EndsWith(".pfx"))
		{
			$CertPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (
				"$Domain.pfx", (Read-Host -AsSecureString -Prompt "Enter certificate password"))

			$Cert = Import-PfxCertificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My `
				-Password $CertPassword.Password -Exportable
		}
		else
		{
			Write-Error -Category InvalidArgument -TargetObject $CertFile -Message "Invalid certificate file format, *.pfx expected"
		}
	}
	elseif ($CertFile.EndsWith(".cer"))
	{
		$Cert = Import-Certificate -FilePath $CertFile -CertStoreLocation Cert:\LocalMachine\My
	}
	else
	{
		Write-Error -Category InvalidArgument -TargetObject $CertFile -Message "Invalid certificate file format, *.cer expected"
	}

	if (Test-Certificate -Cert $Cert -Policy SSL -DNSName $Domain -AllowUntrustedRoot)
	{
		Write-Information -Tags "Project" -MessageData "INFO: Using certificate from custom location '$($Cert.thumbprint)'"
	}
	else
	{
		# Undo import operation
		Get-ChildItem Cert:\LocalMachine\My |
		Where-Object { $_.Thumbprint -eq $Cert.thumbprint } | Remove-Item
		Write-Error -Category SecurityError -TargetObject $Cert -Message "Certificate verification from custom location failed"
	}
}
else
{
	Write-Error -Category ObjectNotFound -TargetObject $CertFile -Message "Specified certificate file was not found '$CertFile'"
}

if ($Target -eq "Server")
{
	# Export self signed, existing certificate from store or imported PFX
	if (Test-Path $ExportFile -PathType Leaf -ErrorAction Ignore)
	{
		if ($Force)
		{
			# NOTE: Will not overwrite readonly file, which isn't reported here
			Write-Warning -Message "Overwriting existing certificate file '$ExportFile'"
			Export-Certificate -Cert $Cert -FilePath $ExportFile -Type CERT -Force | Out-Null
		}
		else
		{
			Write-Warning -Message "Certificate '$Domain.cer' not exported, target file already exists"
		}
	}
	else
	{
		Write-Information -Tags "Project" -MessageData "INFO: Exporting certificate '$Domain.cer'"
		Export-Certificate -Cert $Cert -FilePath $ExportFile -Type CERT | Out-Null
	}
}

# TODO: Should be verified or singed by custom key instead of having many trusted self signed certs
if (!(Test-Certificate -Cert $Cert -Policy SSL -ErrorAction Ignore))
{
	# Add public key to trusted root to trust this certificate locally
	if ($PSCmdlet.ShouldContinue("Add certificate to trusted root store?", "Certificate not trusted"))
	{
		Write-Information -Tags "Project" -MessageData "Trusting certificate '$Domain.cer' with thumbprint '$($Cert.thumbprint)'"
		Import-Certificate -FilePath $ExportFile -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
	}
	else
	{
		Write-Warning -Message "Certificate '$Domain.cer' is not trusted because it is not in the Trusted Root Certification Authorities store"
	}
}

Write-Output $Cert

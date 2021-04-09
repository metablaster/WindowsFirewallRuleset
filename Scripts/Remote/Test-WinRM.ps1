
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

.GUID 40deca2f-e524-4883-b4df-97763c7e0bcd

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Test WinRM service configuration

.DESCRIPTION
Test WinRM service configuration and connectivity

.PARAMETER Protocol
Specify protocol to use for test, HTTP, HTTPS or both.
By default only HTTPS is tested.

.PARAMETER Domain
Target host which is to be tested.
If not specified, local machine is the default

.EXAMPLE
PS> .\Test-WinRM.ps1

.INPUTS
None. You cannot pipe objects to Test-WinRM.ps1

.OUTPUTS
None. Test-WinRM.ps1 does not generate any output

.NOTES
TODO: Test all options are applied, reset by Enable-PSSessionConfiguration or (Set-WSManInstance or wait service restart?)
TODO: To test, configure or query remote computer, use Connect-WSMan and New-WSManSessionOption
TODO: Remote registry test

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Default")]
[OutputType([void], [System.Xml.XmlElement])]
param (
	[Parameter(Position = 0)]
	[ValidateSet("HTTP", "HTTPS", "Any")]
	[string] $Protocol = "HTTPS",

	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$PSDefaultParameterValues["Write-Verbose:Verbose"] = $true
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

$WSManParams = @{
	Authentication = "Default"
}

# NOTE: If using SSL on localhost, it would go trough network stack and for this we need authentication
# Otherwise the error is: "The server certificate on the destination computer (localhost) has the
# following errors: Encountered an internal error in the SSL library.
if (($Domain -ne ([System.Environment]::MachineName)) -or ($Protocol -ne "HTTP"))
{
	$RemoteCredential = Get-Credential -Message "Credentials are required to access host '$Domain'"
	$WSManParams["ComputerName"] = $Domain
	$WSManParams["Credential"] = $RemoteCredential
}

if ($Protocol -ne "HTTP")
{
	Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTPS on '$Domain'"
	# TODO: -CertificateThumbprint $Cert.Thumbprint -ApplicationName -Port
	Test-WSMan -UseSSL @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
}

if ($Protocol -ne "HTTPS")
{
	Write-Information -Tags "Project" -MessageData "INFO: Testing WinRM service over HTTP on '$Domain'"
	Test-WSMan @WSManParams | Select-Object ProductVendor, ProductVersion | Format-List
}

Write-Verbose -Message "[$ThisScript] Creating new CIM session to $Domain"
$CimOptions = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture en-US -Culture en-US

if ($Protocol -eq "HTTP")
{
	$CimOptions.UseSsl = $false
}

$CimParams = @{
	SessionOption = $CimOptions
	OperationTimeoutSec = $PSSessionOption.OperationTimeout.TotalSeconds
	Name = "RemoteCim"
}

if ($Domain -eq ([System.Environment]::MachineName)) # -or ($Domain -eq "localhost"))
{
	# NOTE: If localhost does not accept HTTP (ex. HTTPS configured WinRM server), then change this to true
	$CimOptions.UseSsl = $false
	$CimParams["SessionOption"] = $CimOptions
}
else
{
	$CimParams["Credential"] = $RemoteCredential
	$CimParams["ComputerName"] = $Domain
}

if (Get-CimSession -Name RemoteCim -ErrorAction Ignore)
{
	Remove-CimSession -Name RemoteCim
}

# MSDN: -SkipTestConnection, by default it verifies port is open and credentials are valid,
# verification is accomplished using a standard WS-Identity operation.
# NOTE: Specifying computer name may fail if WinRM listens on loopback only
$CimServer = New-CimSession @CimParams

Write-Information -Tags "Project" -MessageData "INFO: Testing CIM server on localhost"
Get-CimInstance -Class Win32_OperatingSystem |
Select-Object CSName, Caption | Format-Table

Write-Information -Tags "Project" -MessageData "INFO: Testing CIM server on '$Domain'"
Get-CimInstance -CimSession $CimServer -Class Win32_OperatingSystem |
Select-Object CSName, Caption | Format-Table

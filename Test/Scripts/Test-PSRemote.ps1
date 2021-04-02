
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
Unit test for Set-WSManHTTPS.ps1

.DESCRIPTION
Test correctness of Scripts\Utility\Set-WSManHTTPS.ps1 script.
The script Utility\Set-WSManHTTPS.ps1 is not run, only results is tested.

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> .\Test-PSRemote.ps1

.INPUTS
None. You cannot pipe objects to Test-PSRemote.ps1

.OUTPUTS
None. Test-PSRemote.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Test-Function"

[bool] $YesToAll = $false
[bool] $NoToAll = $false

if ($Force -or $PSCmdlet.ShouldContinue("Query", "Accept remote session unit test", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	Start-Test "Enter-PSSession localhost"
	# NOTE: localhost won't work with HTTPS due to CN entry in certificate
	$Cred = Get-Credential -Message "Credentials are required to access localhost'"
	Enter-PSSession -UseSSL -ComputerName ([Environment]::MachineName) -Credential $Cred
	Exit-PSSession

	Start-Test "Enter-PSSession $TestDomain"
	$Cred = Get-Credential -Message "Credentials are required to access '$TestDomain'"
	Enter-PSSession -UseSSL -ComputerName $TestDomain -Credential $Cred -ConfigurationName FirewallSession
	Exit-PSSession
}

Update-Log
Exit-Test

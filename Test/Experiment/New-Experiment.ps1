
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Script experiment

.DESCRIPTION
Use New-Experiment.ps1 to write temporary tests

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\New-Experiment.ps1

.INPUTS
None. You cannot pipe objects to New-Experiment.ps1

.OUTPUTS
None. New-Experiment.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force,

	[Parameter(Mandatory = $true)]
	[Alias("UserName")]
	[string[]] $User,

	[Parameter()]
	[Alias("ComputerName", "CN", "PolicyStore")]
	[string] $Domain = [System.Environment]::MachineName
)

begin
{
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
	Import-Module -Name $PSScriptRoot\Experiment.Module -Scope Global -Force:$Force

	$DebugPreference = "Continue"
	Write-Debug -Message "[$ThisScript] Run module function"
	Debug-Experiment # -Debug
}

process
{
	Write-Debug -Message "INFO: Run script function"

	Get-CimInstance -Class Win32_OperatingSystem -Namespace "root\cimv2" |
	Select-Object CSName, Caption | Format-Table

	Get-CimInstance -CimSession $RemoteCIM -Namespace "root\cimv2" -Class Win32_OperatingSystem |
	Select-Object CSName, Caption | Format-Table

	if ($Domain -eq ([System.Environment]::MachineName))
	{
		Get-PrincipalSID -User $User -Domain $Domain
	}

	Get-PrincipalSID -User $User -Domain $Domain -CIM
}

end
{
	Exit-PSSession
	Get-CimSession -Name RemoteFirewall -EA Ignore | Remove-CimSession
	Get-CimSession -Name LocalFirewall -EA Ignore | Remove-CimSession

	Update-Log
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
Outbound firewall rules for SQLServer

.DESCRIPTION
Outbound firewall rules for SQL Server instance

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\SQLServer.ps1

.INPUTS
None. You cannot pipe objects to SQLServer.ps1

.OUTPUTS
None. SQLServer.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Server - SQL"
# TODO: this is most likely wrong
$SQLUsers = Get-SDDL -Group "Users", "Administrators" -Merge
$Accept = "Outbound rules for Microsoft SQL Server software will be loaded, recommended if Microsoft SQL Server software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Microsoft SQL Server software will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# SQLServer installation directories
#
$SqlManagementStudioRoot = "%ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18"
$SqlPathRoot = "%ProgramW6432%\Microsoft SQL Server\150\DTS"
$SqlServerRoot = "%ProgramW6432%\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Binn"

#
# Rules for SQLServer
#

# Test if installation exists on system
if ((Confirm-Installation "SqlManagementStudio" ([ref] $SqlManagementStudioRoot)) -or $ForceLoad)
{
	# TODO: old directory, our Get-SqlManagementStudio may not work as expected for older versions
	# $Program = "$SQLServerRoot\Tools\Binn\ManagementStudio\Ssms.exe"
	$Program = "$SqlManagementStudioRoot\Common7\IDE\Ssms.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "SQL Server Management Studio" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SQLUsers `
			-InterfaceType $DefaultInterface `
			-Description "Used to check for updates" |
		Format-RuleOutput
	}
}

# Test if installation exists on system
if ((Confirm-Installation "SqlPath" ([ref] $SqlPathRoot)) -or $ForceLoad)
{
	$Program = "$SqlPathRoot\Binn\DTSWizard.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "SQL Server Import and Export Wizard" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SQLUsers `
			-InterfaceType $DefaultInterface `
			-Description "" |
		Format-RuleOutput
	}
}

if ((Confirm-Installation "SqlServer" ([ref] $SqlServerRoot)) -or $ForceLoad)
{
	$Program = "$SqlServerRoot\sqlceip.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# SQLTELEMETRY service must exist in order for "NT SERVICE\SQLTELEMETRY" to exist on system
		$TelemetryService = Get-Service -Name SQLTELEMETRY -ErrorAction Ignore

		if (!$TelemetryService -and $ForceLoad)
		{
			$SqlTelemetryUser = "Any"
		}
		else
		{
			$SqlTelemetryUser = Get-SDDL -Domain "NT SERVICE" -User "SQLTELEMETRY"
		}

		if ($SqlTelemetryUser)
		{
			# TODO: only connections to LocalSubnet and/or over virtual adapters were seen
			# Service short name = SQLTELEMETRY
			New-NetFirewallRule -DisplayName "SQL Server telemetry" `
				-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
				-Service Any -Program $Program -Group $Group `
				-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
				-LocalAddress Any -RemoteAddress Any `
				-LocalPort Any -RemotePort 1433 `
				-LocalUser $SqlTelemetryUser `
				-InterfaceType $DefaultInterface `
				-Description "SQL customer experience improvement program" |
			Format-RuleOutput
		}
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log

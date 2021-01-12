
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Server - SQL"
# TODO: this is most likely wrong
$SQLUsers = Get-SDDL -Group "Users", "Administrators" -Merge
$Accept = "Outbound rules for Microsoft SQL Server software will be loaded, recommended if Microsoft SQL Server software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Microsoft SQL Server software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# SQLServer installation directories
#
# TODO: Unknown default installation directory
$SqlManagementStudioRoot = ""
$SQLDTSRoot = ""

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
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "SQL Server Management Studio" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
			-LocalUser $SQLUsers `
			-Description "" | Format-RuleOutput
	}
}

# Test if installation exists on system
if ((Confirm-Installation "SQLDTS" ([ref] $SQLDTSRoot)) -or $ForceLoad)
{
	$Program = "$SQLDTSRoot\Binn\DTSWizard.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "SQL Server Import and Export Wizard" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
			-LocalUser $SQLUsers `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log

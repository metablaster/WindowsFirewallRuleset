
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Unit test for Get-InterfaceAlias

.DESCRIPTION
Unit test for Get-InterfaceAlias

.EXAMPLE
PS> .\Get-InterfaceAlias.ps1

.INPUTS
None. You cannot pipe objects to Get-InterfaceAlias.ps1

.OUTPUTS
None. Get-InterfaceAlias.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

Start-Test "Get-InterfaceAlias IPv4"
$Aliases = Get-InterfaceAlias IPv4
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv6 FAILURE TEST"
$Aliases = Get-InterfaceAlias -ErrorAction SilentlyContinue IPv6
if ($Aliases)
{
	$Aliases.ToWql()
}

Start-Test "Get-InterfaceAlias IPv4 -IncludeDisconnected -WildCardOption"
$Aliases = Get-InterfaceAlias IPv4 -IncludeDisconnected -WildCardOption IgnoreCase
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeVirtual"
$Aliases = Get-InterfaceAlias IPv4 -IncludeVirtual
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected"
$Aliases = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware"
$Aliases = Get-InterfaceAlias IPv4 -IncludeVirtual -IncludeDisconnected -ExcludeHardware
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeHidden"
$Aliases = Get-InterfaceAlias IPv4 -IncludeHidden
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeAll"
$Aliases = Get-InterfaceAlias IPv4 -IncludeAll
$Aliases.ToWql()

Start-Test "Get-InterfaceAlias IPv4 -IncludeAll -ExcludeHardware"
$Aliases = Get-InterfaceAlias IPv4 -IncludeAll -ExcludeHardware
$Aliases.ToWql()

Test-Output $Aliases -Command Get-InterfaceAlias

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Unit test for Initialize-Project

.DESCRIPTION
Test correctness of Initialize-Project function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Initialize-Project.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Project.ps1

.OUTPUTS
None. Initialize-Project.ps1 does not generate any output

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

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Initialize-Project"

if ($Force -or $PSCmdlet.ShouldContinue("Perform project initialization in develop mode", "Accept potentially dangerous unit test"))
{
	if (!($ProjectCheck -and $ModulesCheck -and $ServicesCheck))
	{
		Write-Error -Category NotEnabled -TargetObject $ThisScript `
			-Message "This unit test requires ProjectCheck, ModulesCheck and ServicesCheck variables to be set"
		return
	}

	# Save original values
	$PreviousModulesCheck = (Get-Variable -Name ModulesCheck -Scope Global).Value
	$PreviousServicesCheck = (Get-Variable -Name ServicesCheck -Scope Global).Value
	$PreviousProjectCheck = (Get-Variable -Name ProjectCheck -Scope Global).Value

	Start-Test "default"
	Initialize-Project

	Start-Test "-Strict"
	Initialize-Project

	Start-Test "ModulesCheck = $false ServicesCheck = $false"
	Set-Variable -Name ModulesCheck -Scope Global -Force -Value $false
	Set-Variable -Name ServicesCheck -Scope Global -Force -Value $false

	Initialize-Project

	Set-Variable -Name ModulesCheck -Scope Global -Force -Value $PreviousModulesCheck
	Set-Variable -Name ServicesCheck -Scope Global -Force -Value $PreviousServicesCheck

	Start-Test "ModulesCheck = $false ServicesCheck = $PreviousServicesCheck"
	Set-Variable -Name ModulesCheck -Scope Global -Force -Value $false
	Initialize-Project
	Set-Variable -Name ModulesCheck -Scope Global -Force -Value $PreviousModulesCheck

	Start-Test "ModulesCheck = $PreviousModulesCheck ServicesCheck = $false"
	Set-Variable -Name ServicesCheck -Scope Global -Force -Value $false
	$Result = Initialize-Project
	$Result
	Test-Output $Result -Command Initialize-Project
	Set-Variable -Name ServicesCheck -Scope Global -Force -Value $PreviousServicesCheck

	Start-Test "ProjectCheck = $false"
	Set-Variable -Name ProjectCheck -Scope Global -Force -Value $false
	$Result = Initialize-Project
	$Result
	Set-Variable -Name ProjectCheck -Scope Global -Force -Value $PreviousProjectCheck

	Test-Output $Result -Command Initialize-Project
}

Update-Log
Exit-Test


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Unit test for info logging

.DESCRIPTION
Unit test for info logging

.EXAMPLE
PS> .\Test-Info.ps1

.INPUTS
None. You cannot pipe objects to Test-Info.ps1

.OUTPUTS
None. Test-Info.ps1 does not generate any output

.NOTES
None.
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

<#
.SYNOPSIS
	Info logging with advanced function
#>
function Test-Info
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] info 1"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] info 2"
}

<#
.SYNOPSIS
	Info logging on pipeline
#>
function Test-Pipeline
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		"PSReviewUnusedParameter", "", Justification = "Needed for test case")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$Param
	)

	process
	{
		Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] End of pipe 1"
		Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] End of pipe 2"
	}
}

<#
.SYNOPSIS
	Info logging with nested function
#>
function Test-Nested
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] Nested 1"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] Nested 2"
}

<#
.SYNOPSIS
	Info logging with nested function
#>
function Test-Parent
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] Parent 1"
	Test-Nested
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] Parent 2"
}

<#
.SYNOPSIS
	Info logging with a combination of other streams
#>
function Test-Combo
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.MyCommand.Name)] combo" -Category PermissionDenied -ErrorId 11
	Write-Warning -Message "[$($MyInvocation.InvocationName)] combo"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.MyCommand.Name)] INFO: combo"
}

<#
.SYNOPSIS
	No info log
.NOTES
	Is this function called?
#>
function Test-Empty
{
	[CmdletBinding()]
	param ()
}

Enter-Test $ThisScript

# NOTE: we test generating logs not what is shown in the console
# disabling this for "RunAllTests"
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"

Start-Test "No info"
Get-ChildItem -Path "C:\" @Logs | Out-Null

Start-Test "Test-Info"
Test-Info @Logs

Start-Test "Test-Pipeline"
Test-Empty @Logs | Test-Pipeline @Logs

Start-Test "Test-Parent"
Test-Parent @Logs

Start-Test "Test-Combo"
Test-Combo @Logs

Update-Log
Exit-Test

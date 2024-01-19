
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
Unit test for Get-TypeName

.DESCRIPTION
Test correctness of Get-TypeName function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-TypeName.ps1

.INPUTS
None. You cannot pipe objects to for Get-TypeName.ps1

.OUTPUTS
None. Get-TypeName.ps1 does not generate any output

.NOTES
TODO: Need to write test cases for non .NET types such as WMI or custom types,
also more failure test cases.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

<#
.SYNOPSIS
Test case when there is no return
#>
function global:Test-NoReturn
{
	[OutputType([int32])]
	[CmdletBinding()]
	param ()

	return $null
}

<#
.SYNOPSIS
Test case when there are multiple OutputType types
#>
function global:Test-Multiple
{
	[OutputType([int32], [string])]
	[CmdletBinding()]
	param ()

	return $null
}

<#
.SYNOPSIS
Test case for custom object
#>
function global:Test-CustomObject
{
	[OutputType("UnitTest.TestType")]
	[CmdletBinding()]
	param ()

	[PSCustomObject] @{
		Domain = [System.Environment]::MachineName
		PSTypeName = "UnitTest.TestType"
	}
}

Enter-Test "Get-TypeName"

#
# Defaults test
#
New-Section "Test default"

Start-Test "-InputObject" -Expected "System.String"
Get-TypeName ([System.Environment]::MachineName)

Start-Test "-Accelerator" -Expected "string"
Get-TypeName ([System.Environment]::MachineName) -Accelerator

Start-Test "-InputObject" -Expected "System.Void"
Get-TypeName (Test-NoReturn)

Start-Test "-Accelerator" -Expected "void"
Get-TypeName (Test-NoReturn) -Accelerator

#
# Test command
#
New-Section "Test command parameter"

Start-Test "-Command" -Expected "System.Int32"
Get-TypeName -Command Test-NoReturn

Start-Test "-Command" -Expected "int32, string"
Get-TypeName -Command Test-Multiple -Accelerator

#
# Test with Get-Process
#
New-Section "Test with Get-Process"

Start-Test "-InputObject" -Expected "System.Diagnostics.Process"
$Result = Get-TypeName (Get-Process)
$Result

Start-Test "-Command" -Expected "Get-Process OutputType attributes"
Get-TypeName -Command Get-Process

#
# Test conversion
#
New-Section "Test -Accelerator parameter"

Start-Test "-Name" -Expected "System.Management.Automation.SwitchParameter"
Get-TypeName -Name [switch]

Start-Test "-Name -Accelerator" -Expected "switch"
Get-TypeName -Name [System.Management.Automation.SwitchParameter] -Accelerator

Start-Test "-Name" -Expected "System.String"
Get-TypeName -Name string

Start-Test "-Name -Accelerator" -Expected "string"
Get-TypeName -Name System.String -Accelerator

Start-Test "-Name -Accelerator" -Expected "string"
Get-TypeName -Name string -Accelerator

#
# Test default, pipeline
#
New-Section "Test pipeline"

Start-Test "-InputObject" -Expected "System.String"
([System.Environment]::MachineName) | Get-TypeName

Start-Test "-Accelerator" -Expected "string"
([System.Environment]::MachineName) | Get-TypeName -Accelerator

Start-Test "-InputObject" -Expected "System.Void"
Test-NoReturn | Get-TypeName

Start-Test "-Accelerator" -Expected "void"
Test-NoReturn | Get-TypeName -Accelerator

#
# Test pipeline with Get-Process
#
New-Section "Test pipeline with Get-Process"

Start-Test "-InputObject" -Expected "System.Diagnostics.Process"
Write-Warning -Message "[$ThisScript] Test did not run to reduce output"
# Get-Process | Get-TypeName -Verbose:$false -Debug:$false | Out-Null

#
# PSCustomObject
#
New-Section "Custom object"

Start-Test "-Command" -Expected "UnitTest.TestType"
Get-TypeName -Command Test-CustomObject -Force

Start-Test "InputObject" -Expected "UnitTest.TestType"
Test-CustomObject | Get-TypeName -Force

Start-Test "InputObject -Accelerator" -Expected "UnitTest.TestType"
Get-TypeName (Test-CustomObject) -Accelerator -Force

Start-Test "Name" -Expected "FAIL"
Get-TypeName -Name "UnitTest.TestType"

#
# Other common issues
#
New-Section "Random tests"

Start-Test "null" -Expected "void"
Get-TypeName -Accelerator

Start-Test "false" -Expected "System.Boolean"
$FalseType = $false
$FalseType | Get-TypeName

# TODO: These tests fail, Get-TypeName not implementing these
Start-Test "ServiceController" -Expected "FAIL"
$ServiceController = Get-Service -Name Dhcp
Get-TypeName $ServiceController

Start-Test "CimInstance Win32_OperatingSystem" -Expected "FAIL"
Get-CimInstance -Class Win32_OperatingSystem | Get-TypeName

Start-Test "[ModuleInfoGrouping] on PS Core"
Get-Module -ListAvailable -Name "PowerShellGet" | Get-TypeName

Test-Output $Result -Command Get-TypeName

Update-Log
Exit-Test

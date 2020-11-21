
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
Unit test for Get-TypeName

.DESCRIPTION
Unit test for Get-TypeName

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

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
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

Enter-Test

#
# Defaults test
#
New-Section "Test default"

Start-Test "Get-TypeName -> System.String"
Get-TypeName ([System.Environment]::MachineName)

Start-Test "Get-TypeName -Accelerator -> string"
Get-TypeName ([System.Environment]::MachineName) -Accelerator

Start-Test "Get-TypeName -> System.Void"
Get-TypeName (Test-NoReturn)

Start-Test "Get-TypeName -Accelerator -> void"
Get-TypeName (Test-NoReturn) -Accelerator

#
# Test command
#
New-Section "Test command parameter"

Start-Test "Get-TypeName -Command -> int32"
Get-TypeName -Command Test-NoReturn

Start-Test "Get-TypeName -Command -> int32, System.String"
Get-TypeName -Command Test-Multiple

#
# Test with Get-Process
#
New-Section "Test with Get-Process"

Start-Test "Get-TypeName -> System.Diagnostics.Process"
$Result = Get-TypeName (Get-Process)
$Result

Start-Test "Get-TypeName -Command -> Get-Process"
Get-TypeName -Command Get-Process

#
# Test conversion
#
New-Section "Test -Accelerator parameter"

Start-Test "Get-TypeName -Name -> System.Management.Automation.SwitchParameter"
Get-TypeName -Name [switch]

Start-Test "Get-TypeName -Name -Accelerator -> switch"
Get-TypeName -Name [System.Management.Automation.SwitchParameter] -Accelerator

Start-Test "Get-TypeName -Name -> FAIL"
Get-TypeName -Name [string]

Start-Test "Get-TypeName -Name -Accelerator -> FAIL"
Get-TypeName -Name [string] -Accelerator

#
# Test default, pipeline
#
New-Section "Test pipeline"

Start-Test "Get-TypeName -> System.String"
([System.Environment]::MachineName) | Get-TypeName

Start-Test "Get-TypeName -Accelerator -> string"
([System.Environment]::MachineName) | Get-TypeName -Accelerator

Start-Test "Get-TypeName -> System.Void"
Test-NoReturn | Get-TypeName

Start-Test "Get-TypeName -Accelerator -> void"
Test-NoReturn | Get-TypeName -Accelerator

#
# Test pipeline with Get-Process
#
New-Section "Test pipeline with Get-Process"

Start-Test "Get-TypeName -> System.Diagnostics.Process"
Write-Warning -Message "Test did not run to reduce output"
# Get-Process | Get-TypeName -Verbose:$false -Debug:$false | Out-Null

#
# Other common issues
#
Start-Test "Get-TypeName -> null"
Get-TypeName

Start-Test "Get-TypeName False"
$FalseType = $false
$FalseType | Get-TypeName

# TODO: These tests fail, Get-TypeName not implementing these
# Start-Test "Get-TypeName Get-Service"
# $ServiceController = Get-Service
# Get-TypeName $ServiceController

# Start-Test "Get-TypeName Get-Service"
# Get-CimInstance -Class Win32_OperatingSystem | Get-TypeName

Test-Output $Result -Command Get-TypeName

Update-Log
Exit-Test

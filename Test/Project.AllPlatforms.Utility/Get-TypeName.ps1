
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
Unit test for Get-TypeName

.DESCRIPTION
Unit test for Get-TypeName

.EXAMPLE
PS> .\ Get-TypeName.ps1

.INPUTS
None. You cannot pipe objects to for Get-TypeName.ps1

.OUTPUTS
None. Get-TypeName.ps1 does not generate any output

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
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

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
	[OutputType([int32], [System.String])]
	[CmdletBinding()]
	param ()

	return $null
}

Enter-Test $ThisScript

#
# Test default
#

Start-Test "Get-TypeName -> System.String"
Get-TypeName ([System.Environment]::MachineName) @Logs

Start-Test "Get-TypeName -Accelerator -> string"
Get-TypeName ([System.Environment]::MachineName) -Accelerator @Logs

Start-Test "Get-TypeName -> System.Void"
Get-TypeName (Test-NoReturn) @Logs

Start-Test "Get-TypeName -Accelerator -> void"
Get-TypeName (Test-NoReturn) -Accelerator @Logs

#
# Test command
#

Start-Test "Get-TypeName -Command -> int32"
Get-TypeName -Command Test-NoReturn @Logs

Start-Test "Get-TypeName -Command -> int32, System.String"
Get-TypeName -Command Test-Multiple @Logs

#
# Test with Get-Process
#

Start-Test "Get-TypeName -> System.Diagnostics.Process"
Get-TypeName (Get-Process) @Logs

Start-Test "Get-TypeName -Command -> Get-Process"
Get-TypeName -Command Get-Process @Logs

#
# Test conversion
#

Start-Test "Get-TypeName -Name -> System.Management.Automation.SwitchParameter"
Get-TypeName -Name "switch"

Start-Test "Get-TypeName -Name -Accelerator -> switch"
Get-TypeName -Name "System.Management.Automation.SwitchParameter" -Accelerator

Start-Test "Get-TypeName -Name -> FAIL"
Get-TypeName -Name "System.String"

Start-Test "Get-TypeName -Name -Accelerator -> FAIL"
Get-TypeName -Name "string" -Accelerator

#
# Test default, pipeline
#

Write-Information -Tags "Test" -MessageData "INFO: Test default, pipeline"

Start-Test "Get-TypeName -> System.String"
([System.Environment]::MachineName) | Get-TypeName @Logs

Start-Test "Get-TypeName -Accelerator -> string"
([System.Environment]::MachineName) | Get-TypeName -Accelerator @Logs

Start-Test "Get-TypeName -> System.Void"
Test-NoReturn | Get-TypeName @Logs

Start-Test "Get-TypeName -Accelerator -> void"
Test-NoReturn | Get-TypeName -Accelerator @Logs

#
# Test with Get-Process
#

Start-Test "Get-TypeName -> System.Diagnostics.Process"
Write-Warning -Message "Test aborted"
# Get-Process | Get-TypeName @Logs

Start-Test "Get-TypeName -> null"
Get-TypeName @Logs

Update-Log
Exit-Test

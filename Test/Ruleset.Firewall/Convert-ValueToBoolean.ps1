
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
Unit test for Convert-ValueToBoolean

.DESCRIPTION
Unit test for Convert-ValueToBoolean

.EXAMPLE
PS> .\Convert-ValueToBoolean.ps1

.INPUTS
None. You cannot pipe objects to Convert-ValueToBoolean.ps1

.OUTPUTS
None. Convert-ValueToBoolean.ps1 does not generate any output
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "This unit test is enabled only when 'Develop' is set to $true"
	return
}

Start-Test "Convert-ValueToBoolean 0"
Convert-ValueToBoolean "0" @Logs

Start-Test "Convert-ValueToBoolean False"
Convert-ValueToBoolean "False" @Logs

Start-Test "Convert-ValueToBoolean 3"
Convert-ValueToBoolean "3" -EA SilentlyContinue -EV CoversionError
if ($CoversionError)
{
	Write-Warning "Error ignored by unit test: $CoversionError"
}

Start-Test "Convert-ValueToBoolean UNKNOWN"
Convert-ValueToBoolean "UNKNOWN" -EA SilentlyContinue -EV CoversionError
if ($CoversionError)
{
	Write-Warning "Error ignored by unit test: $CoversionError"
}

Start-Test "Convert-ValueToBoolean True"
$Result = Convert-ValueToBoolean "True" @Logs
$Result

Test-Output $Result -Command Convert-ValueToBoolean @Logs

Update-Log
Exit-Test

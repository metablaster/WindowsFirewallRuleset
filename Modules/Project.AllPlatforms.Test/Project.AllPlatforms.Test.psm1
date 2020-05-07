
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

Set-StrictMode -Version Latest
Set-Variable -Name ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}
else
{
	# Everything is default except InformationPreference should be enabled
	$InformationPreference = "Continue"
}

<#
.SYNOPSIS
Used to initialize test units, ie. to disable logging.
.DESCRIPTION
TODO: add description
.EXAMPLE
Start-Test
.INPUTS
None. You cannot pipe objects to New-Test
.OUTPUTS
None.
.NOTES
None.
#>
function Start-Test
{
	[OutputType([System.Void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# disable logging errors for tests
	Set-Variable -Name ErrorLoggingCopy -Scope Script -Value $ErrorLogging
	Set-Variable -Name ErrorLogging -Scope Global -Value $true

	# disable logging warnings for tests
	Set-Variable -Name WarningLoggingCopy -Scope Script -Value $WarningLogging
	Set-Variable -Name WarningLogging -Scope Global -Value $true

	# disable logging information messages for tests
	Set-Variable -Name InformationLoggingCopy -Scope Script -Value $InformationLogging
	Set-Variable -Name InformationLogging -Scope Global -Value $true

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ErrorLogging changed to: $ErrorLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] WarningLogging changed to: $WarningLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] InformationLogging changed to: $InformationLogging"
}

<#
.SYNOPSIS
Write output to console to separate test cases
.PARAMETER InputMessage
Message to format and print before test
.EXAMPLE
New-Test "My-Function"

***********************
*Testing: My-Function *
***********************
.INPUTS
None. You cannot pipe objects to New-Test
.OUTPUTS
None. Formatted message block is shown in console.
#>
function New-Test
{
	[OutputType([System.Void])]
	param (
		[AllowEmptyString()]
		[Parameter(Mandatory = $true)]
		[string] $InputMessage
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$Message = "Testing: $InputMessage"
	$Asterisks = $("*" * ($Message.Length + 4))

	# NOTE: Write-Host would mess up test case outputs
	Write-Output ""
	Write-Output $Asterisks
	Write-Output "* $Message *"
	Write-Output $Asterisks
	Write-Output ""
}

<#
.SYNOPSIS
Used to tell script scope test is done, ie. to restore previous state
.EXAMPLE
Exit-Test
.INPUTS
None. You cannot pipe objects to Exit-Test
.OUTPUTS
None.
#>
function Exit-Test
{
	[OutputType([System.Void])]
	param()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# restore logging errors
	Set-Variable -Name ErrorLogging -Scope Global -Value $ErrorLoggingCopy

	# restore logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value $WarningLoggingCopy

	# restore logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value $InformationLoggingCopy

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ErrorLogging restored to: $ErrorLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] WarningLogging restored to: $WarningLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] InformationLogging restored to: $InformationLogging"

	Write-Output ""
}

#
# Function exports
#

Export-ModuleMember -Function Start-Test
Export-ModuleMember -Function New-Test
Export-ModuleMember -Function Exit-Test

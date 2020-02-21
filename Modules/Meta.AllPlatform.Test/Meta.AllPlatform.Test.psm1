
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

<#
.SYNOPSIS
Do stuff before any tests
.EXAMPLE
Start-Test
.INPUTS
None. You cannot pipe objects to New-Test
.OUTPUTS
formatted message block is shown in console
#>
function Start-Test
{
	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	# disable logging errors for tests
	Set-Variable -Name ErrorLoggingCopy -Scope Script -Value $ErrorLogging
	Set-Variable -Name ErrorLogging -Scope Global -Value $false

	# disable logging warnings for tests
	Set-Variable -Name WarningLoggingCopy -Scope Script -Value $WarningLogging
	Set-Variable -Name WarningLogging -Scope Global -Value $false

	# disable logging information messages for tests
	Set-Variable -Name InformationLoggingCopy -Scope Script -Value $InformationLogging
	Set-Variable -Name InformationLogging -Scope Global -Value $false

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ErrorLogging is $ErrorLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] WarningLogging is $WarningLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] InformationLogging is $InformationLogging"
}

<#
.SYNOPSIS
write output to separate test cases
.PARAMETER InputMessage
message to print before test
.EXAMPLE
New-Test "my test"
.INPUTS
None. You cannot pipe objects to New-Test
.OUTPUTS
formatted message block is shown in console
#>
function New-Test
{
	param (
		[Parameter(Mandatory = $true)]
		[string] $InputMessage
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	$Message = "Testing: $InputMessage"
	$Asterisks = $("*" * ($Message.Length + 4))

	Write-Host ""
	Write-Host $Asterisks
	Write-Host "* $Message *"
	Write-Host $Asterisks
	Write-Host ""
}

<#
.SYNOPSIS
write output to tell script scope test is done
.EXAMPLE
Exit-Test
.INPUTS
None. You cannot pipe objects to Exit-Test
.OUTPUTS
formatted message block is shown in console
#>
function Exit-Test
{
	Write-Debug -Message "[$($MyInvocation.InvocationName)] $($PSBoundParameters.Values)"

	# restore logging errors
	Set-Variable -Name ErrorLogging -Scope Global -Value $ErrorLoggingCopy

	# restore logging warnings
	Set-Variable -Name WarningLogging -Scope Global -Value $WarningLoggingCopy

	# restore logging information messages
	Set-Variable -Name InformationLogging -Scope Global -Value $InformationLoggingCopy

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ErrorLogging is $ErrorLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] WarningLogging is $WarningLogging"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] InformationLogging is $InformationLogging"

	# Write-Host ""
	# Save-Errors
	Write-Host ""
}

#
# Function exports
#

Export-ModuleMember -Function Start-Test
Export-ModuleMember -Function New-Test
Export-ModuleMember -Function Exit-Test

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

	$ThisModule = $MyInvocation.MyCommand.Name -replace ".{5}$"

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

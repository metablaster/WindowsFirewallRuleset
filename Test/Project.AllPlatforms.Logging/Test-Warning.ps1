
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

#
# Unit test for Test-Warning
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

function Test-Warning
{
	[CmdletBinding()]
	param ()

	Write-Warning -Message "[$($MyInvocation.InvocationName)] warning 1"
	Write-Warning -Message "[$($MyInvocation.InvocationName)] warning 2"
}

function Test-Pipeline
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$Param
	)

	Write-Warning -Message "[$($MyInvocation.InvocationName)] End of pipe 1"
	Write-Warning -Message "[$($MyInvocation.InvocationName)] End of pipe 2"
}

function Test-Nested
{
	[CmdletBinding()]
	param ()

	Write-Warning -Message "[$($MyInvocation.InvocationName)] Nested 1"
	Write-Warning -Message "[$($MyInvocation.InvocationName)] Nested 2"
}

function Test-Parent
{
	[CmdletBinding()]
	param ()

	Write-Warning -Message "[$($MyInvocation.InvocationName)] Parent 1"
	Test-Nested
	Write-Warning -Message "[$($MyInvocation.InvocationName)] Parent 2"
}

function Test-Combo
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.MyCommand.Name)] combo"  -Category PermissionDenied -ErrorId 10
	Write-Warning -Message "[$($MyInvocation.InvocationName)] combo"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.MyCommand.Name)] INFO: combo"
}

function Test-Empty
{
	[CmdletBinding()]
	param ()
}

Start-Test

New-Test "No warnings"
Get-ChildItem -Path "C:\" @Logs | Out-Null

New-Test "Test-Warning"
Test-Warning @Logs

New-Test "Test-Pipeline"
Test-Empty @Logs | Test-Pipeline @Logs

New-Test "Test-Parent"
Test-Parent @Logs

New-Test "Test-Combo"
Test-Combo @Logs

Update-Logs
Exit-Test

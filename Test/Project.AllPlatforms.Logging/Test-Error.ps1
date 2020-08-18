
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
# Unit test for Test-Error
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Test-SystemRequirements

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

<#
.SYNOPSIS
	Error logging with advanced function
#>
function Test-Error
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.InvocationName)] error 1" -Category PermissionDenied -ErrorId 1
	Write-Error -Message "[$($MyInvocation.InvocationName)] error 2" -Category PermissionDenied -ErrorId 2
}

<#
.SYNOPSIS
	Error logging on pipeline
#>
function Test-Pipeline
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Needed for test case')]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$Param
	)

	process
	{
		Write-Error -Message "[$($MyInvocation.InvocationName)] End of pipe 1" -Category PermissionDenied -ErrorId 3
		Write-Error -Message "[$($MyInvocation.InvocationName)] End of pipe 2" -Category PermissionDenied -ErrorId 4
	}
}

<#
.SYNOPSIS
	Error logging with nested function
#>
function Test-Nested
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.InvocationName)] Nested 1" -Category PermissionDenied -ErrorId 5
	Write-Error -Message "[$($MyInvocation.InvocationName)] Nested 2" -Category PermissionDenied -ErrorId 6
}

<#
.SYNOPSIS
	Error logging with nested function
#>
function Test-Parent
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.InvocationName)] Parent 1" -Category PermissionDenied -ErrorId 7
	Test-Nested
	Write-Error -Message "[$($MyInvocation.InvocationName)] Parent 2" -Category PermissionDenied -ErrorId 8
}

<#
.SYNOPSIS
	Error logging with a combination of other streams
#>
function Test-Combo
{
	[CmdletBinding()]
	param ()

	Write-Error -Message "[$($MyInvocation.InvocationName)] combo" -Category PermissionDenied -ErrorId 9
	Write-Warning -Message "[$($MyInvocation.MyCommand.Name)] combo"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.MyCommand.Name)] INFO: combo"
}

Start-Test

New-Test "Generate errors"
$Folder = "C:\CrazyFolder"
Get-ChildItem -Path $Folder @Logs

New-Test "No errors"
Get-ChildItem -Path "C:\" @Logs | Out-Null

New-Test "Test-Error"
Test-Error @Logs

New-Test "Test-Pipeline"
Get-ChildItem -Path $Folder @Logs | Test-Pipeline @Logs

New-Test "Test-Parent"
Test-Parent @Logs

New-Test "Test-Combo"
Test-Combo @Logs

Update-Log
Exit-Test

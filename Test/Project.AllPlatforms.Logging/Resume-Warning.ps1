
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
# Unit test for Resume-Warning
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $RepoDir\Test\ContextSetup.ps1
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Test
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Logging
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

# function Test-NonAdvancedFunction
# {
# 	Write-Warning -Message "[$($MyInvocation.InvocationName)] warning message" -WarningAction "Continue" 3>&1 |
# 	Resume-Warning -Log:$WarningLogging -Preference $WarningPreference
# }

# function Test-WarningNow
# {
# 	[CmdletBinding()]
# 	param ()

# 	Write-Debug -Message "[$($MyInvocation.InvocationName)] Warning preference is: $WarningPreference"

# 	Write-Warning -Message "Test-WarningNow 1" -WarningAction "Continue" 3>&1 | Resume-Warning -Preference "Continue"
# 	Write-Log

# 	Write-Warning -Message "Test-WarningNow 2"
# }

function Test-WarningRecursiveInternal
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Warning preference is: $WarningPreference"

	Write-Warning -Message "$($MyInvocation.MyCommand.Name)"
}

function Test-WarningRecursive
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Warning preference is: $WarningPreference"

	Test-WarningRecursiveInternal

	Write-Warning -Message "$($MyInvocation.MyCommand.Name)"
}

function Test-WarningCmdLet
{
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Warning preference is: $WarningPreference"

	Write-Warning -Message "Test-WarningCmdLet 1"
	Write-Warning -Message "Test-WarningCmdLet 2"
}

function Test-NoWarningCmdLet
{
	[CmdletBinding()]
	param ()
}

function Test-Pipeline
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$Param
	)

	Write-Warning -Message "End of pipe"
}

Start-Test

#$WarningPreference = "SilentlyContinue"

# New-Test "Test-NonAdvancedFunction"
# Test-NonAdvancedFunction

# New-Test "Test-WarningNow"
# Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Warning preference is: $WarningPreference"
# Test-WarningNow @Commons
# Write-Log

New-Test "Test-WarningCmdLet"
Test-WarningCmdLet @Commons
Write-Log

New-Test "Test-WarningRecursive"
Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Warning preference is: $WarningPreference"
Test-WarningRecursive @Commons
Write-Log

New-Test "Test-NoWarningCmdLet"
Test-NoWarningCmdLet @Commons
Write-Log

# $Folder = "C:\CrazyFolder"

# New-Test "Test pipeline"
# Get-ChildItem -Path $Folder @Commons | Test-Pipeline @Commons
# Write-Log

# New-Test "Test pipeline"
# Get-ChildItem -Path $Folder @Commons | Test-Pipeline @Commons
# Write-Log

Exit-Test

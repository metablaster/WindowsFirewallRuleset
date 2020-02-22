
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
# Unit test for Resume-Info
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

# function Test-NonAdvancedFunction
# {
# 	Write-Information -Tags "Test" -MessageData "INFO: sample info" `
# 	-Tags Result 6>&1 | Resume-Info -Log:$InformationLogging -Preference $InformationPreference
# }

function Test-InfoCmdLet
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "INFO: Test-InfoCmdLet 1"
	Write-Information -Tags "Test" -MessageData "INFO: Test-InfoCmdLet 2"
	#Write-Error -Message "Test-InfoCmdLet error" -Category PermissionDenied -ErrorId SampleID
}

function Test-NoInfoCmdLet
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

	Write-Information -Tags "Test" -MessageData "INFO: End of pipe"
}

Start-Test

# $InformationPreference = "SilentlyContinue"

# New-Test "Test-NonAdvancedFunction"
# Test-NonAdvancedFunction

New-Test "Test-InfoCmdLet"
Test-InfoCmdLet @Logs
Update-Logs

New-Test "Test-NoInfoCmdLet"
Test-NoInfoCmdLet @Logs
Update-Logs

$Folder = "C:\CrazyFolder"

New-Test "Test pipeline"
Get-ChildItem -Path $Folder @Logs | Test-Pipeline @Logs
Update-Logs

New-Test "Test pipeline"
Get-ChildItem -Path $Folder @Logs | Test-Pipeline @Logs
Update-Logs

New-Test "Write-Host"
Write-Host "Write-Host" @Logs
Update-Logs

New-Test "Write-Output"
Write-Output "Write-Output" @Logs
Update-Logs

Exit-Test

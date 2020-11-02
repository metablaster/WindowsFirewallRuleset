
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
Unit test for Set-Permission

.DESCRIPTION
Unit test for Set-Permission

.EXAMPLE
PS> .\ Set-Permission.ps1

.INPUTS
None. You cannot pipe objects to for Set-Permission.ps1

.OUTPUTS
None. Set-Permission.ps1 does not generate any output

.NOTES
None.
#>

# Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

# Set up test variables
$Computer = [System.Environment]::MachineName
$TestFolder = "$ProjectRoot\Test\Project.AllPlatforms.Utility\TestPermission"
$TestFolders = @(
	"DenyRights"
	"Inheritance"
	"Protected"
)
$TestFiles = @(
	"NT Service.txt"
	"LocalService.txt"
	"Remote Management Users.txt"
)

# Create test files
if (!(Test-Path -PathType Container -Path $TestFolder))
{
	Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $TestFolder"
	New-Item -ItemType Container -Path $TestFolder | Out-Null
}

$FileIndex = 0
foreach ($Folder in $TestFolders)
{
	if (!(Test-Path -PathType Container -Path $TestFolder\$Folder))
	{
		Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $Folder"
		New-Item -ItemType Container -Path $TestFolder\$Folder | Out-Null
		New-Item -ItemType File -Path $TestFolder\$Folder\$($TestFiles[$FileIndex]) | Out-Null
	}

	++$FileIndex
}

foreach ($File in $TestFiles)
{
	if (!(Test-Path -PathType Leaf -Path $TestFolder\$File))
	{
		Write-Information -Tags "Test" -MessageData "INFO: Creating new test file: $File"
		New-Item -ItemType File -Path $TestFolder\$File | Out-Null
	}
}

# Test ownership
Start-Test "Set-Permission ownership"
Set-Permission -Owner $UnitTester -Domain $Computer -Path $TestFolder @Logs

# Test defaults
Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on file"
Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestFolder\$($TestFiles[0])" @Logs

Start-Test "Set-Permission - Local Service permission on file"
Set-Permission -Principal "Local Service" -Path "$TestFolder\$($TestFiles[1])" @Logs

Start-Test "Set-Permission - Group permission on file"
Set-Permission -Principal "Remote Management Users" -Path "$TestFolder\$($TestFiles[2])" @Logs

# Test parameters
Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on folder"
Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestFolder\$($TestFolders[0])" `
	-Type "Deny" -Rights "TakeOwnership, Delete, Modify" @Logs

Start-Test "Set-Permission - Local Service permission on folder"
Set-Permission -Principal "Local Service" -Path "$TestFolder\$($TestFolders[1])" `
	-Type "Allow" -Inheritance "ObjectInherit" -Propagation "NoPropagateInherit" @Logs

Start-Test "Set-Permission - Group permission on folder"
$Result = Set-Permission -Principal "Remote Management Users" -Path "$TestFolder\$($TestFolders[2])" `
	-Protected @Logs

$Result

# Test output type
Start-Test "Get-TypeName"
$Result | Get-TypeName @Logs

Update-Log
Exit-Test

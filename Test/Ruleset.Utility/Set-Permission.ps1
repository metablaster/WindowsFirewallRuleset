
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

using namespace System.Security

<#
.SYNOPSIS
Unit test for Set-Permission

.DESCRIPTION
Unit test for Set-Permission

.PARAMETER FileSystem
Test setting file system permissions/ownership

.PARAMETER Registry
Test setting registry permissions/ownership

.EXAMPLE
PS> .\Set-Permission.ps1 -FileSystem

.EXAMPLE
PS> .\Set-Permission.ps1 -Registry -FileSystem

.INPUTS
None. You cannot pipe objects to for Set-Permission.ps1

.OUTPUTS
None. Set-Permission.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $FileSystem,

	[Parameter()]
	[switch] $Registry
)

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

if ($FileSystem)
{
	# Set up test variables
	$Computer = [System.Environment]::MachineName
	$TestFolder = "$ProjectRoot\Test\Ruleset.Utility\TestPermission"

	[AccessControl.FileSystemRights] $Access = "ReadAndExecute, ListDirectory, Traverse"

	# NOTE: temporary reset
	if ($false)
	{
		# Test ownership
		Start-Test "Set-Permission ownership"
		Set-Permission -Owner $TestUser -Domain $Computer -Path $TestFolder -Recurse @Logs

		# Reset existing tree for re-test
		Start-Test "Reset existing tree"
		Set-Permission -Principal $TestUser -Domain $Computer -Path $TestFolder -Reset -Grant $Access -Recurse @Logs
	}

	$TestFolders = @(
		"DenyRights"
		"Inheritance"
		"Protected"
		"Recurse"
	)
	$TestFiles = @(
		"NT Service.txt"
		"LocalService.txt"
		"Remote Management Users.txt"
		"Recurse.txt"
	)

	# Create root test folder
	if (!(Test-Path -PathType Container -Path $TestFolder))
	{
		Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $TestFolder"
		New-Item -ItemType Container -Path $TestFolder | Out-Null
	}

	# Create subfolder files and directories
	$FileIndex = 0
	foreach ($Folder in $TestFolders)
	{
		if (!(Test-Path -PathType Container -Path $TestFolder\$Folder))
		{
			Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $Folder"
			New-Item -ItemType Container -Path $TestFolder\$Folder | Out-Null
			New-Item -ItemType Container -Path $TestFolder\$Folder\$Folder | Out-Null
			New-Item -ItemType File -Path $TestFolder\$Folder\$($TestFiles[$FileIndex]) | Out-Null
		}

		++$FileIndex
	}

	# Create test files
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
	Set-Permission -Owner $TestUser -Domain $Computer -Path $TestFolder @Logs

	# Test defaults
	Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on file"
	Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestFolder\$($TestFiles[0])" -Grant $Access @Logs

	Start-Test "Set-Permission - Local Service permission on file"
	Set-Permission -Principal "Local Service" -Path "$TestFolder\$($TestFiles[1])" -Grant $Access @Logs

	Start-Test "Set-Permission - Group permission on file"
	Set-Permission -Principal "Remote Management Users" -Path "$TestFolder\$($TestFiles[2])" -Grant $Access @Logs

	# Test parameters
	Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on folder"
	Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestFolder\$($TestFolders[0])" `
		-Type "Deny" -Rights "TakeOwnership, Delete, Modify" @Logs

	Start-Test "Set-Permission - Local Service permission on folder"
	Set-Permission -Principal "Local Service" -Path "$TestFolder\$($TestFolders[1])" `
		-Type "Allow" -Inheritance "ObjectInherit" -Propagation "NoPropagateInherit" -Grant $Access @Logs

	Start-Test "Set-Permission - Group permission on folder"
	$Result = Set-Permission -Principal "Remote Management Users" -Path "$TestFolder\$($TestFolders[2])" -Grant $Access `
		-Protected @Logs

	$Result

	# Test output type
	Test-Output $Result -Command Set-Permission @Logs

	# Test reset/recurse
	Start-Test "Reset permissions inheritance to explicit"
	Set-Permission -Path "$TestFolder\Protected\Remote Management Users.txt" -Reset -Protected -PreserveInheritance

	Start-Test "Reset permissions recurse"
	Set-Permission -Principal "Administrators" -Grant "FullControl" -Path $TestFolder -Reset -Recurse @Logs

	Start-Test "Recursive ownership on folder"
	Set-Permission -Owner "Replicator" -Path $TestFolder -Recurse @Logs

	Start-Test "Recursively reset"
	Set-Permission -Path $TestFolder -Reset -Recurse @Logs

	Start-Test "Recursively clear all rules or folder"
	Set-Permission -Path $TestFolder -Reset -Recurse -Protected @Logs
}
elseif ($Registry -or $PSCmdlet.ShouldContinue("Modify registry ownership or permissions", "Accept dangerous unit test"))
{
	# NOTE: This test may fail until Set-Privilege script is considered into Set-Permission function
	# Ownership + Full control
	$TestKey = "TestKey"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening registry hive"
	$RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser
	$RegistryView = [Microsoft.Win32.RegistryView]::Registry64

	try
	{
		$RootKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView)
	}
	catch
	{
		Write-Error -TargetObject $_.TargetObject -Category $_.CategoryInfo.Category -Message $_.Exception.Message
		Update-Log
		Exit-Test
		return
	}

	if (!$RootKey)
	{
		Write-Warning -Message "Failed to open registry root key: HKCU"
	}
	else
	{
		[Microsoft.Win32.RegistryKey] $SubKey = $RootKey.OpenSubkey($TestKey)

		if ($SubKey)
		{
			# TODO: Return value is 'HKEY_CURRENT_USER\TestKey'
			$KeyLocation = $SubKey.Name # "HKCU:\TestKey" #

			# Take ownership and set full control
			# NOTE: setting other owner (except current user) will not work for HKCU
			Set-Permission -Principal "TrustedInstaller" -Domain "NT SERVICE" -Path $KeyLocation -Reset -RegistryRight "ReadKey"
			Set-Permission -Owner "TrustedInstaller" -Domain "NT SERVICE" -Path $KeyLocation

			Set-Permission -Principal $TestUser -Path $KeyLocation -Reset -RegistryRight "ReadKey"
			Set-Permission -Owner $TestUser -Path $KeyLocation
		}
		else
		{
			Write-Warning -Message "Failed to open registry sub key: HKCU:$TestKey"
		}
	}
}

Update-Log
Exit-Test

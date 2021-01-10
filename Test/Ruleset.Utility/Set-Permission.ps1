
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Test correctness of Set-Permission function

.PARAMETER FileSystem
Test setting file system permissions/ownership

.PARAMETER Registry
Test setting registry permissions/ownership

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Set-Permission.ps1 -FileSystem

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Set-Permission.ps1 -Registry -FileSystem

.INPUTS
None. You cannot pipe objects to for Set-Permission.ps1

.OUTPUTS
None. Set-Permission.ps1 does not generate any output

.NOTES
None.
#>

using namespace System.Security
#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $FileSystem,

	[Parameter()]
	[switch] $Registry,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test

if ($FileSystem)
{
	# Set up test variables
	$Computer = [System.Environment]::MachineName
	$TestDrive = "$DefaultTestDrive\$ThisScript"

	[AccessControl.FileSystemRights] $Access = "ReadAndExecute, ListDirectory, Traverse"

	# NOTE: temporary reset
	if ($false)
	{
		# Test ownership
		Start-Test "Set-Permission ownership"
		Set-Permission -Owner $TestUser -Domain $Computer -Path $TestDrive -Recurse

		# Reset existing tree for re-test
		Start-Test "Reset existing tree"
		Set-Permission -Principal $TestUser -Domain $Computer -Path $TestDrive -Reset -Grant $Access -Recurse
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
	if (!(Test-Path -PathType Container -Path $TestDrive))
	{
		Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $TestDrive"
		New-Item -ItemType Container -Path $TestDrive | Out-Null
	}

	# Create subfolder files and directories
	$FileIndex = 0
	foreach ($Folder in $TestFolders)
	{
		if (!(Test-Path -PathType Container -Path $TestDrive\$Folder))
		{
			Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory: $Folder"
			New-Item -ItemType Container -Path $TestDrive\$Folder | Out-Null
			New-Item -ItemType Container -Path $TestDrive\$Folder\$Folder | Out-Null
			New-Item -ItemType File -Path $TestDrive\$Folder\$($TestFiles[$FileIndex]) | Out-Null
		}

		++$FileIndex
	}

	# Create test files
	foreach ($File in $TestFiles)
	{
		if (!(Test-Path -PathType Leaf -Path $TestDrive\$File))
		{
			Write-Information -Tags "Test" -MessageData "INFO: Creating new test file: $File"
			New-Item -ItemType File -Path $TestDrive\$File | Out-Null
		}
	}

	# Test ownership
	Start-Test "Set-Permission ownership"
	Set-Permission -Owner $TestUser -Domain $Computer -Path $TestDrive

	# Test defaults
	Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on file"
	Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestDrive\$($TestFiles[0])" -Grant $Access

	Start-Test "Set-Permission - Local Service permission on file"
	Set-Permission -Principal "Local Service" -Path "$TestDrive\$($TestFiles[1])" -Grant $Access

	Start-Test "Set-Permission - Group permission on file"
	Set-Permission -Principal "Remote Management Users" -Path "$TestDrive\$($TestFiles[2])" -Grant $Access

	# Test parameters
	Start-Test "Set-Permission - NT SERVICE\LanmanServer permission on folder"
	Set-Permission -Principal "LanmanServer" -Domain "NT SERVICE" -Path "$TestDrive\$($TestFolders[0])" `
		-Type "Deny" -Rights "TakeOwnership, Delete, Modify"

	Start-Test "Set-Permission - Local Service permission on folder"
	Set-Permission -Principal "Local Service" -Path "$TestDrive\$($TestFolders[1])" `
		-Type "Allow" -Inheritance "ObjectInherit" -Propagation "NoPropagateInherit" -Grant $Access

	Start-Test "Set-Permission - Group permission on folder"
	$Result = Set-Permission -Principal "Remote Management Users" -Path "$TestDrive\$($TestFolders[2])" -Grant $Access `
		-Protected

	$Result

	# Test output type
	Test-Output $Result -Command Set-Permission

	# Test reset/recurse
	Start-Test "Reset permissions inheritance to explicit"
	Set-Permission -Path "$TestDrive\Protected\Remote Management Users.txt" -Reset -Protected -PreserveInheritance

	Start-Test "Reset permissions recurse"
	Set-Permission -Principal "Administrators" -Grant "FullControl" -Path $TestDrive -Reset -Recurse

	Start-Test "Recursive ownership on folder"
	Set-Permission -Owner "Replicator" -Path $TestDrive -Recurse

	Start-Test "Recursively reset"
	Set-Permission -Path $TestDrive -Reset -Recurse

	Start-Test "Recursively clear all rules or folder"
	Set-Permission -Path $TestDrive -Reset -Recurse -Protected
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
		Write-Error -ErrorRecord $_
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

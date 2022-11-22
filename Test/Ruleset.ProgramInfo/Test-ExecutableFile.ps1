
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Unit test for Test-ExecutableFile

.DESCRIPTION
Test correctness of Test-ExecutableFile function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-ExecutableFile.ps1

.INPUTS
None. You cannot pipe objects to Test-ExecutableFile.ps1

.OUTPUTS
None. Test-ExecutableFile.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test
$ValidFile = "%SystemRoot%\regedit.exe"
$Directory = "%SystemDrive%\Windows\System32"
$BlacklistedExtension = New-Item -ItemType File -Path $DefaultTestDrive\badfile.scr -Force
$UnknownExtension = New-Item -ItemType File -Path $DefaultTestDrive\badfile.asd -Force
$NoExtension = New-Item -ItemType File -Path $DefaultTestDrive\fileonly -Force
$UnsignedFile = New-Item -ItemType File -Path $DefaultTestDrive\unsigned.exe -Force
$UNCPath = "\\COMPUTERNAME\Directory\file.exe"
$RemoteEicar = "C:\dev\WindowsFirewallRuleset\Test\TestDrive\eicar.exe"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "Remote valid executable -Domain"
	Test-ExecutableFile $ValidFile -Domain $Domain -Credential $RemotingCredential

	Start-Test "Remote valid executable -Session"
	Test-ExecutableFile $ValidFile -Session $SessionInstance

	Start-Test "Remote directory -Session"
	Test-ExecutableFile $Directory -Session $SessionInstance

	Start-Test "Remote eicar test"
	Test-ExecutableFile $RemoteEicar -Session $SessionInstance
}
else
{
	$PSDefaultParameterValues["Test-ExecutableFile:Session"] = $SessionInstance

	Start-Test "Valid executable"
	$Result = Test-ExecutableFile $ValidFile
	$Result

	Start-Test "Directory"
	Test-ExecutableFile $Directory

	Start-Test "Blacklisted extension" -Expected "FAIL"
	Test-ExecutableFile $BlacklistedExtension.FullName

	Start-Test "Unknown extension" -Expected "FAIL"
	Test-ExecutableFile $UnknownExtension.FullName

	Start-Test "No extension" -Expected "FAIL"
	Test-ExecutableFile $NoExtension.FullName

	Start-Test "Unsigned file" -Expected "FAIL"
	Test-ExecutableFile $UnsignedFile.FullName

	Start-Test "Force unsigned file" -Expected "WARNING"
	Test-ExecutableFile $UnsignedFile.FullName -Force

	Start-Test "Non existent directory"
	Test-ExecutableFile "C:\Unknown\Directory\"

	Start-Test "Non existent file"
	Test-ExecutableFile "C:\Unknown\Directory\file.exe"

	Start-Test "Unresolved path"
	Test-ExecutableFile "C:\Unk[n]own\*tory"

	Start-Test "Relative path to directory"
	Test-ExecutableFile ".\.."

	Start-Test "Relative path to this directory: ."
	Test-ExecutableFile "."

	Start-Test "Relative path to root drive: \"
	Test-ExecutableFile "\"

	Start-Test "Relative path to valid file 1"
	Copy-Item -Path ([System.Environment]::ExpandEnvironmentVariables($ValidFile)) -Destination $DefaultTestDrive
	Test-ExecutableFile "..\TestDrive\regedit.exe"

	Start-Test "Relative path to valid file 2"
	Test-ExecutableFile "C:\Windows\System32\..\regedit.exe"

	Start-Test "Relative path to unsigned file"
	Test-ExecutableFile "..\TestDrive\$($UnsignedFile.Name)"

	Start-Test "Bad path syntax"
	Test-ExecutableFile "C:\Bad\<Path>\Loca'tion"

	Start-Test "Path to registry"
	Test-ExecutableFile "HKLM:\SOFTWARE\Microsoft\Clipboard"

	Start-Test "UNC path"
	Test-ExecutableFile $UNCPath

	Test-Output $Result -Command Test-ExecutableFile
}

Update-Log
Exit-Test

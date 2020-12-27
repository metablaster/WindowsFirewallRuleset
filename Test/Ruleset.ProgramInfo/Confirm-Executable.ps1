
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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
Unit test for Confirm-Executable

.DESCRIPTION
Test correctness of Confirm-Executable function

.EXAMPLE
PS> .\Confirm-Executable.ps1

.INPUTS
None. You cannot pipe objects to Confirm-Executable.ps1

.OUTPUTS
None. Confirm-Executable.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

$ValidFile = "%SystemRoot%\regedit.exe"
$Directory = "%SystemDrive%\Windows\System32"
$BlacklistedExtension = New-Item -ItemType File -Path $DefaultTestDrive\badfile.scr -Force
$UnknownExtension = New-Item -ItemType File -Path $DefaultTestDrive\badfile.asd -Force
$NoExtension = New-Item -ItemType File -Path $DefaultTestDrive\fileonly -Force
$UnsignedFile = New-Item -ItemType File -Path $DefaultTestDrive\unsigned.exe -Force
$UNCPath = "\\COMPUTERNAME\Directory\file.exe"

Start-Test "Valid executable"
$Result = Confirm-Executable $ValidFile
$Result

Start-Test "Directory"
Confirm-Executable $Directory

Start-Test "Blacklisted extension"
Confirm-Executable $BlacklistedExtension.FullName

Start-Test "Unknown extension"
Confirm-Executable $UnknownExtension.FullName

Start-Test "No extension"
Confirm-Executable $NoExtension.FullName

Start-Test "Unsigned file"
Confirm-Executable $UnsignedFile.FullName

Start-Test "Force unsigned file"
Confirm-Executable $UnsignedFile.FullName -Force

Start-Test "Non existent directory"
Confirm-Executable "C:\Unknown\Directory\"

Start-Test "Non existent file"
Confirm-Executable "C:\Unknown\Directory\file.exe"

Start-Test "Unresolved path"
Confirm-Executable "C:\Unk[n]own\*tory"

Start-Test "Relative path to directory"
Confirm-Executable ".\.."

Start-Test "Relative path to this directory: ."
Confirm-Executable "."

Start-Test "Relative path to root drive: \"
Confirm-Executable "\"

Start-Test "Relative path to valid file 1"
Copy-Item -Path ([System.Environment]::ExpandEnvironmentVariables($ValidFile)) -Destination $DefaultTestDrive
Confirm-Executable "..\TestDrive\regedit.exe"

Start-Test "Relative path to valid file 2"
Confirm-Executable "C:\Windows\System32\..\regedit.exe"

Start-Test "Relative path to unsigned file"
Confirm-Executable "..\TestDrive\$($UnsignedFile.Name)"

Start-Test "Bad path syntax"
Confirm-Executable "C:\Bad\<Path>\Loca'tion"

Start-Test "Path to registry"
Confirm-Executable "HKLM:\SOFTWARE\Microsoft\Clipboard"

Start-Test "UNC path"
Confirm-Executable $UNCPath

Test-Output $Result -Command Confirm-Executable

Update-Log
Exit-Test

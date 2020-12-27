
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
Unit test for Test-File

.DESCRIPTION
Test correctness of Test-File function

.EXAMPLE
PS> .\Test-File.ps1

.INPUTS
None. You cannot pipe objects to Test-File.ps1

.OUTPUTS
None. Test-File.ps1 does not generate any output

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
$Result = Test-File $ValidFile
$Result

Start-Test "Directory"
Test-File $Directory

Start-Test "Blacklisted extension"
Test-File $BlacklistedExtension.FullName

Start-Test "Unknown extension"
Test-File $UnknownExtension.FullName

Start-Test "No extension"
Test-File $NoExtension.FullName

Start-Test "Unsigned file"
Test-File $UnsignedFile.FullName

Start-Test "Force unsigned file"
Test-File $UnsignedFile.FullName -Force

Start-Test "Non existent directory"
Test-File "C:\Unknown\Directory\"

Start-Test "Non existent file"
Test-File "C:\Unknown\Directory\file.exe"

Start-Test "Unresolved path"
Test-File "C:\Unk[n]own\*tory"

Start-Test "Relative path to directory"
Test-File ".\.."

Start-Test "Relative path to this directory: ."
Test-File "."

Start-Test "Relative path to root drive: \"
Test-File "\"

Start-Test "Relative path to valid file 1"
Copy-Item -Path ([System.Environment]::ExpandEnvironmentVariables($ValidFile)) -Destination $DefaultTestDrive
Test-File "..\TestDrive\regedit.exe"

Start-Test "Relative path to valid file 2"
Test-File "C:\Windows\System32\..\regedit.exe"

Start-Test "Relative path to unsigned file"
Test-File "..\TestDrive\$($UnsignedFile.Name)"

Start-Test "Bad path syntax"
Test-File "C:\Bad\<Path>\Loca'tion"

Start-Test "Path to registry"
Test-File "HKLM:\SOFTWARE\Microsoft\Clipboard"

Start-Test "UNC path"
Test-File $UNCPath

Test-Output $Result -Command Test-File

Update-Log
Exit-Test

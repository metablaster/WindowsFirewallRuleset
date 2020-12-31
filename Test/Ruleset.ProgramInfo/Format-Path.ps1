
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
Unit test for Format-Path

.DESCRIPTION
Unit test for Format-Path

.EXAMPLE
PS> .\Format-Path.ps1

.INPUTS
None. You cannot pipe objects to Format-Path.ps1

.OUTPUTS
None. Format-Path.ps1 does not generate any output

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

#
# Root drive
#
New-Section "Root drive"

$TestPath = "C:\"
$Result = Start-Test $TestPath
$Result
Format-Path $TestPath

$TestPath = "C:\\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "D:///\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "Z:"
Start-Test $TestPath
Format-Path $TestPath

#
# Expanded path
#
New-Section "Expanded path"

$TestPath = "C:\\Windows\System32"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:Windows\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Program Files\WindowsPowerShell"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "D:\\microsoft///windows"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Windows\Microsoft.NET/Framework64\v3.5\\"
Start-Test $TestPath
Format-Path $TestPath

#
# Environment variables
#
New-Section "Environment variables"

$TestPath = "%SystemDrive%"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "%SystemDrive%\Windows\System32"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
Start-Test $TestPath
Format-Path $TestPath

#
# User profile
#
New-Section "User profile"

$TestPath = "C:\Users\Public\Public Downloads"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Users\$TestUser\AppData//Local\OneDrive"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Users\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:/Users"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:Users\"
Start-Test $TestPath
Format-Path $TestPath

#
# Relative paths
#
New-Section "Relative paths"

$TestPath = ".\.."
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "."
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "..\dir//.\.."
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Windows\System32\..\regedit.exe"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "~"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "~/\Direcotry//file.exe"
Start-Test $TestPath
Format-Path $TestPath

#
# UNC and rooted path
#
New-Section "UNC and rooted path"

$TestPath = "\\/COMPUTERNAME\Directory\file.exe/"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "/user//\/dir"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "\Windows"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "\\\COMPUTERNAME//"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "///"
Start-Test $TestPath
Format-Path $TestPath

#
# Bad format
#
New-Section "Bad format"

$TestPath = '"C:\ProgramData\Git"'
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "'C:\PerfLogs'"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "`'`"C:\ProgramData\Git`"`'"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "`"`'C:\ProgramData\Git`'`""
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "'C:\PerfLogs"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "$("'C:\PerfLogs;'")"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "%SystemDrive%\%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:PerfLogs\.../"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Unk[n]own\*tory"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "C:\Bad\<Path>\Loca'tion"
Start-Test $TestPath
Format-Path $TestPath

#
# Not file system
#
New-Section "Not file system"

$TestPath = "HKLM:\SOFTWARE\Microsoft\Clipboard"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "\\.\pipe\vscode-git-475e6cdf67-sock"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "\\?\"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = $env:path
Start-Test "env:PATH"
Format-Path $TestPath

$TestPath = "C:\Windows;;D:Dir1\..\dir2;F:/Data"
Start-Test "C:\Windows;;D:Dir1\..\dir2;"
Format-Path $TestPath

$TestPath = "Intel64 Family 6 Model 158 Stepping 11, GenuineIntel"
Start-Test $TestPath
Format-Path $TestPath

$TestPath = "1.52.1"
Start-Test $TestPath
Format-Path $TestPath

#
# null or empty
#
New-Section "null or empty"

$TestPath = ""
Start-Test '""'
Format-Path $TestPath

$TestPath = $null
Start-Test '$null'
Format-Path $TestPath

Test-Output $Result -Command Format-Path

New-Section "Test data to pipeline"
$TestData = Get-Content -Path $ThisScript\..\TestData\Format-Path.txt
# TODO: Need pipeline support for Start-Test
$TestData | Format-Path

New-Section "Test array input"
Format-Path $TestData

Update-Log
Exit-Test

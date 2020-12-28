
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
Unit test for Test-Environment

.DESCRIPTION
Test correctness of Test-Environment function

.EXAMPLE
PS> .\Test-Environment.ps1

.INPUTS
None. You cannot pipe objects to Test-Environment.ps1

.OUTPUTS
None. Test-Environment.ps1 does not generate any output

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
# Root drives
#

New-Section "Root drive"

$TestPath = "C:"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath -PathType Directory

$TestPath = "C:\\"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "D:\"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "Z:\"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

#
# Expanded paths
#

New-Section "Expanded paths"

$TestPath = "C:\\Windows\System32"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "C:/Windows/explorer.exe"
Start-Test "Test-Environment -PathType Leaf: $TestPath"
Test-Environment $TestPath -PathType File

$TestPath = "C:\\NoSuchFolder"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

#
# Environment variables
#

New-Section "Environment variables"

$TestPath = "%SystemDrive%"
Start-Test "Test-Environment: $TestPath"
$Status = Test-Environment $TestPath
$Status

$TestPath = "C:\Program Files (x86)\Windows Defender\"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "%Path%"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "%SystemDrive%\Windows\%ProgramFiles%"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

#
# Bad syntax
#

New-Section "Invalid syntax"

$TestPath = '"C:\ProgramData\ssh"'
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "C:\Unk[n]own\*tory"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "C:\Bad\<Path>\Loca'tion"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

#
# Users folder
#

New-Section "Users folder"

$TestPath = "C:\Users"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

# TODO: 3 or more of \
$TestPath = "C:\Users\\"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "C:\\UsersA\"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "C:\\Users\3"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "C:\Users\\"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "C:\\UsersA\"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "C:\\Users\3"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

#
# User profile
#

New-Section "UserProfile"

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-Environment -UserProfile: $TestPath"
Test-Environment -UserProfile $TestPath

#
# Firewall switch
#

New-Section "Test firewall"

$TestPath = "C:\\Windows\System32"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-Environment -Firewall: $TestPath"
Test-Environment -Firewall $TestPath

#
# Firewall and UserProfile switch
#

New-Section "-Firewall + -UserProfile"

$TestPath = "%HOME%\AppData\Local\MicrosoftEdge"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

$TestPath = "C:\Program Files (x86)\Windows Defender"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\\"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\Public"
Start-Test "Test-Environment -Firewall -UserProfile: $TestPath"
Test-Environment -Firewall -UserProfile $TestPath

#
# Null or empty string
#

New-Section "Null test"

$TestPath = ""
Start-Test "Test-Environment: '$TestPath'"
Test-Environment $TestPath

$TestPath = $null
Start-Test "Test-Environment: null"
$Status = Test-Environment $TestPath
$Status

Test-Output $Status -Command Test-Environment

#
# Relative paths
#

New-Section "Relative paths"

$TestPath = ".\.."
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "."
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "\"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "C:\Windows\System32\..\regedit.exe"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

#
# Not file system
#

$TestPath = "HKLM:\SOFTWARE\Microsoft\Clipboard"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

$TestPath = "\\COMPUTERNAME\Directory\file.exe"
Start-Test "Test-Environment: $TestPath"
Test-Environment $TestPath

Test-Output $Status -Command Test-Environment

Update-Log
Exit-Test

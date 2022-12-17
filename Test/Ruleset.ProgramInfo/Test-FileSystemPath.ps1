
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
Unit test for Test-FileSystemPath

.DESCRIPTION
Test correctness of Test-FileSystemPath function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-FileSystemPath.ps1

.INPUTS
None. You cannot pipe objects to Test-FileSystemPath.ps1

.OUTPUTS
None. Test-FileSystemPath.ps1 does not generate any output

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
if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "remote Session"
	$TestPath = "C:\Windows\regedit.exe"
	Test-FileSystemPath $TestPath -PathType Directory -Session $SessionInstance

	Start-Test "remote Session"
	$TestPath = "%SystemDrive%\Windows\System32"
	Test-FileSystemPath $TestPath -PathType Directory -Session $SessionInstance

	# Start-Test "remote Domain"
	# Test-FileSystemPath $TestPath -PathType Directory -Domain $Domain -Credential $RemotingCredential
}
else
{
	$PSDefaultParameterValues["Test-FileSystemPath:Session"] = $SessionInstance

	#
	# Root drives
	#

	New-Section "Root drive"

	$TestPath = "C:"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath -PathType Directory

	$TestPath = "C:\\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "D:\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "Z:\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	#
	# Expanded paths
	#

	New-Section "Expanded paths"

	$TestPath = "C:\\Windows\System32"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:/Windows/explorer.exe"
	Start-Test "-PathType Leaf: $TestPath"
	Test-FileSystemPath $TestPath -PathType File

	$TestPath = "C:\\NoSuchFolder"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "\Windows"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	#
	# Environment variables
	#

	New-Section "Environment variables"

	$TestPath = "%SystemDrive%"
	Start-Test "$TestPath"
	$Status = Test-FileSystemPath $TestPath
	$Status

	$TestPath = "C:\Program Files (x86)\Windows Defender\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%Path%"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%SystemDrive%\Windows\%ProgramFiles%"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%SystemDrive%\%NUMBER_OF_PROCESSORS%\directory"
	Start-Test "$TestPath"
	$Status = Test-FileSystemPath $TestPath
	$Status

	#
	# Bad syntax
	#

	New-Section "Invalid syntax"

	$TestPath = '"C:\ProgramData\ssh"'
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:\Unk[n]own\*tory"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:\Bad\<Path>\Loca'tion"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%SystemRoot%\%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:\%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	#
	# Users folder
	#

	New-Section "Users folder"
	# ((C:\\?)|\\)Users(?!\\+(Public$|Public\\+))\\

	$TestPath = "C:\Users"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:Users\\\PublicUser"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "\Users\user"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:\\UsersA\"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:\\Users\3"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:\Users"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:Users\\\PublicUser"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\Users\\"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\\UsersA\"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\\Users\3"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "\Users\user"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	#
	# User profile
	#

	New-Section "UserProfile"

	$TestPath = "%LOCALAPPDATA%\Temp"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%LOCALAPPDATA%\Temp"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "%HOMEPATH%\AppData\Local\Temp"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "%HOMEPATH%\AppData\Local\Temp"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "C:\Users\$TestUser\AppData"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:\Users\$TestUser\AppData"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	$TestPath = "F:\Users\$TestUser"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "F:\Users\$TestUser"
	Start-Test "-UserProfile: $TestPath"
	Test-FileSystemPath -UserProfile $TestPath

	#
	# Firewall switch
	#

	New-Section "Test firewall"

	$TestPath = "C:\\Windows\System32"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "%LOCALAPPDATA%\Temp"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "%HOMEPATH%\AppData\Local\Temp"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\Users\$TestUser\AppData"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "F:\Users\$TestUser"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "%UNKNOWNVARIABLE%\directory"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath -Firewall

	$TestPath = "C:"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "C:\"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath -Firewall $TestPath

	$TestPath = "\Windows"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	#
	# Firewall and UserProfile switch
	#

	New-Section "-Firewall + -UserProfile"

	$TestPath = "%HOME%\AppData\Local\MicrosoftEdge"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	$TestPath = "C:\Users\$TestUser\AppData"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	$TestPath = "C:\Program Files (x86)\Windows Defender"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	$TestPath = "%HOMEPATH%\AppData\Local\Temp"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	$TestPath = "C:\Users\\"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	$TestPath = "C:\Users\Public"
	Start-Test "-Firewall -UserProfile: $TestPath"
	Test-FileSystemPath -Firewall -UserProfile $TestPath

	#
	# Null or empty string
	#

	New-Section "Null test"

	$TestPath = ""
	Start-Test "'$TestPath'"
	Test-FileSystemPath $TestPath

	$TestPath = $null
	Start-Test "null"
	$Status = Test-FileSystemPath $TestPath
	$Status

	Test-Output $Status -Command Test-FileSystemPath

	#
	# Relative paths
	#

	New-Section "Relative paths"

	$TestPath = ".\.."
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "."
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:\Windows\System32\..\regedit.exe"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "C:Windows"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "~\Direcotry\file.exe"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = ".\.."
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	$TestPath = "."
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	$TestPath = "C:\Windows\System32\..\regedit.exe"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	$TestPath = "C:Windows"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	$TestPath = "~\Direcotry\file.exe"
	Start-Test "-Firewall: $TestPath"
	Test-FileSystemPath $TestPath -Firewall

	#
	# Not file system
	#

	New-Section "Not file system"

	$TestPath = "HKLM:\SOFTWARE\Microsoft\Clipboard"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "\\COMPUTERNAME\Directory\file.exe"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	$TestPath = "\\"
	Start-Test "$TestPath"
	Test-FileSystemPath $TestPath

	Test-Output $Status -Command Test-FileSystemPath
}

Update-Log
Exit-Test


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

# Initialization
New-Variable -Name ThisModule -Scope Script -Option ReadOnly -Value (Split-Path $PSScriptRoot -Leaf)

# Imports
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule
. $ProjectRoot\Modules\ModulePreferences.ps1

#
# Script imports
# TODO: Executables involved in rules which are installed into ProgramFiles\Common Files require
# separate search algorithm (function) instead of using Update-Table, these are present only
# if program in question is installed, likely into ProgramFiles
# Example programs: Adobe and Java
#

$ScriptsToProcess = @(
	"TargetProgram"
)

foreach ($Script in $ScriptsToProcess)
{
	Write-Debug -Message "[$ThisModule] Importing script: Scripts\$Script.ps1"
	. "$PSScriptRoot\Scripts\$Script.ps1"
}

$PrivateScripts = @(
	"Edit-Table"
	"Initialize-Table"
	"Show-Table"
	"Update-Table"
)

foreach ($Script in $PrivateScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Private\$Script.ps1"
	. "$PSScriptRoot\Private\$Script.ps1"
}

$PublicScripts = @(
	"External\Get-SqlServerInstance"
	"Find-Installation"
	"Format-Path"
	"Get-AllUserSoftware"
	"Get-AppCapability"
	"Get-AppSID"
	"Get-ExecutablePath"
	"Get-NetFramework"
	"Get-OneDrive"
	"Get-SqlManagementStudio"
	"Get-SystemApps"
	"Get-SystemSoftware"
	"Get-UserApps"
	"Get-UserSoftware"
	"Get-WindowsDefender"
	"Get-WindowsKit"
	"Get-WindowsSDK"
	"Test-Environment"
	"Confirm-Executable"
	"Test-Installation"
	"Test-Service"
)

foreach ($Script in $PublicScripts)
{
	Write-Debug -Message "[$ThisModule] Importing script: Public\$Script.ps1"
	. "$PSScriptRoot\Public\$Script.ps1"
}

#
# Module variables
#
Write-Debug -Message "[$ThisModule] Initializing module variables"

# Installation table holds user and program directory pair
if ($Develop)
{
	# TODO: script scope variable should be exportable?
	Remove-Variable -Name InstallTable -Scope Script -ErrorAction Ignore
	New-Variable -Name InstallTable -Scope Global -Value $null
}
else
{
	Remove-Variable -Name InstallTable -Scope Global -ErrorAction Ignore
	New-Variable -Name InstallTable -Scope Script -Value $null
}

# Programs installed system wide
New-Variable -Name SystemPrograms -Scope Script -Option ReadOnly -Value (
	Get-SystemSoftware -Computer $PolicyStore
)

# Executable paths
New-Variable -Name ExecutablePaths -Scope Script -Option ReadOnly -Value (
	Get-ExecutablePath -Computer $PolicyStore
)

# Program data
New-Variable -Name AllUserPrograms -Scope Script -Option ReadOnly -Value (
	Get-AllUserSoftware -Computer $PolicyStore
)

# Allowed executable extensions
New-Variable -Name WhiteListExecutable -Scope Script -Option Constant -Value @{
	EXE	= "Executable"
}

# Blacklisted executable extensions
New-Variable -Name BlackListExecutable -Scope Script -Option Constant -Value @{
	BAT = "Batch File"
	BIN = "Binary Executable"
	CMD = "Command Script"
	COM	= "Command File"
	CPL	= "Control Panel Extension"
	GADGET = "Windows Gadget"
	INF1 = "Setup Information File"
	INS = "Internet Communication Settings"
	INX	= "InstallShield Compiled Script"
	ISU	= "InstallShield Uninstaller Script"
	JOB	= "Windows Task Scheduler Job File"
	JSE	= "JScript Encoded File"
	LNK	= "File Shortcut"
	MSC	= "Microsoft Common Console Document"
	MSI	= "Windows Installer Package"
	MSP	= "Windows Installer Patch"
	MST	= "Windows Installer Setup Transform File"
	PAF	= "Portable Application Installer File"
	PIF	= "Program Information File"
	PS1	= "Windows PowerShell Cmdlet"
	REG	= "Registry Data File"
	RGS	= "Registry Script"
	SCR	= "Screensaver Executable"
	SCT	= "Windows Scriptlet"
	SHB	= "Windows Document Shortcut"
	SHS	= "Shell Scrap Object"
	U3P	= "U3 Smart Application"
	VB	= "VBScript File"
	VBE	= "VBScript Encoded Script"
	VBS	= "VBScript File"
	VBSCRIPT = "Visual Basic Script"
	WS	= "Windows Script"
	WSF	= "Windows Script"
	WSH	= "Windows Script Preference"
}

#
# Module cleanup
#

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	Write-Debug -Message "[$ThisModule] Cleanup module"

	if ($Develop)
	{
		Remove-Variable -Name InstallTable -Scope Global
	}
}

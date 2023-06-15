
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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

<#PSScriptInfo

.VERSION 0.15.1

.GUID c4321c55-c1ad-4867-bbaa-50d16c9f856e

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Add "Open in Windows Terminal as administrator" context menu

.DESCRIPTION
Adds an "Open in Windows Terminal as administrator" option in right click context menu

.EXAMPLE
PS> .\WindowsTerminal.ps1

.INPUTS
None. You cannot pipe objects to WindowsTerminal.ps1

.OUTPUTS
None. WindowsTerminal.ps1 does not generate any output

.NOTES
HACK: Context menu not shown
TODO: Figure out why -d parameter value for wt.exe results in "Could not access starting directory " %V\. ""

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
[OutputType([void])]
param ()

Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

if ($PSCmdlet.ShouldProcess("Windows registry", "Add 'Open in Windows Terminal as administrator' context menu"))
{
	$ValueKind = [Microsoft.Win32.RegistryValueKind]::String
	$RegistryHive = [Microsoft.Win32.RegistryHive]::ClassesRoot
	$RegistryView = [Microsoft.Win32.RegistryView]::Registry64
	$RegistryPermission = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree
	$RegistryRights = [System.Security.AccessControl.RegistryRights] "CreateSubKey, SetValue"

	try
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on local computer"
		$BaseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView)

		$HKCR = "Directory\shell"
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKCR\$HKCR"
		$RootKey = $BaseKey.OpenSubkey($HKCR, $RegistryPermission, $RegistryRights)

		if (!$RootKey)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] The following registry key does not exist: HKCR\$HKCR"
			$BaseKey.Dispose()
			return
		}
	}
	catch
	{
		if ($BaseKey)
		{
			$BaseKey.Dispose()
		}

		Write-Error -ErrorRecord $_
		return
	}

	# HKEY_CLASSES_ROOT\Directory\shell\OpenWTHereAsAdmin
	$WtKey = $RootKey.CreateSubKey("OpenWTHereAsAdmin", $RegistryPermission)

	$WtKey.SetValue("HasLUAShield", "", $ValueKind)
	$WtKey.SetValue("MUIVerb", "Open in Windows Terminal as administrator", $ValueKind)
	$WtKey.SetValue("Extended", "-", $ValueKind)
	$WtKey.SetValue("SubCommands", "", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Shell\OpenWTHereAsAdmin\shell\001flyout
	$ShellKey = $WtKey.CreateSubKey("shell", $RegistryPermission)
	$SubKey = $ShellKey.CreateSubKey("001flyout", $RegistryPermission)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)
	$SubKey.SetValue("MUIVerb", "Default Profile", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\001flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Shell\OpenWTHereAsAdmin\shell\002flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("002flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "Command Prompt", $ValueKind)
	$SubKey.SetValue("Icon", "imageres.dll,-5324", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\002flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""Command Prompt"""','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""Command Prompt"""'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Shell\OpenWTHereAsAdmin\shell\003flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("003flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "Windows PowerShell", $ValueKind)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)
	$SubKey.SetValue("Icon", "powershell.exe", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\003flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""Windows PowerShell"""','-d','"""%1\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""Windows PowerShell"""'',''-d'',''"""%1\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Shell\OpenWTHereAsAdmin\shell\004flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("004flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "PowerShell Core", $ValueKind)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)
	$SubKey.SetValue("Icon", "pwsh.exe", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\004flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""Windows PowerShell"""','-d','"""%2\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""PowerShell Core"""'',''-d'',''"""%2\."""'')"', $ValueKind)
	$CommandKey.Close()

	$SubKey.Close()
	$ShellKey.Close()
	$WtKey.Close()

	try
	{
		$HKCR = "Directory\Background\shell"
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKCR\$HKCR"

		$RootKey.Close()
		$RootKey = $BaseKey.OpenSubkey($HKCR, $RegistryPermission, $RegistryRights)

		if (!$RootKey)
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] The following registry key does not exist: HKCR\$HKCR"
			$BaseKey.Dispose()
			return
		}
	}
	catch
	{
		$BaseKey.Dispose()
		Write-Error -ErrorRecord $_
		return
	}


	# HKEY_CLASSES_ROOT\Directory\Background\shell\OpenWTHereAsAdmin
	$BackgroundKey = $RootKey.CreateSubKey("OpenWTHereAsAdmin", $RegistryPermission)

	$BackgroundKey.SetValue("HasLUAShield", "", $ValueKind)
	$BackgroundKey.SetValue("MUIVerb", "Open in Windows Terminal as administrator", $ValueKind)
	$BackgroundKey.SetValue("Extended", "-", $ValueKind)
	$BackgroundKey.SetValue("SubCommands", "", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\001flyout
	$ShellKey.Close()
	$ShellKey = $BackgroundKey.CreateSubKey("shell", $RegistryPermission)
	$SubKey = $ShellKey.CreateSubKey("001flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "Default Profile", $ValueKind)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\001flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\002flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("002flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "Command Prompt", $ValueKind)
	$SubKey.SetValue("Icon", "imageres.dll,-5324", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\002flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""Command Prompt"""','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""Command Prompt"""'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\003flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("003flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "Windows PowerShell", $ValueKind)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)
	$SubKey.SetValue("Icon", "powershell.exe", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\003flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""Windows PowerShell"""','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""Windows PowerShell"""'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\004flyout
	$SubKey.Close()
	$SubKey = $ShellKey.CreateSubKey("003flyout", $RegistryPermission)
	$SubKey.SetValue("MUIVerb", "PowerShell Core", $ValueKind)
	$SubKey.SetValue("HasLUAShield", "", $ValueKind)
	$SubKey.SetValue("Icon", "pwsh.exe", $ValueKind)

	# HKEY_CLASSES_ROOT\Directory\Background\Shell\OpenWTHereAsAdmin\shell\004flyout\command
	$CommandKey = $SubKey.CreateSubKey("command", $RegistryPermission)
	# powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @('/c','start wt.exe','-p','"""PowerShell Core"""','-d','"""%V\."""')"
	$CommandKey.SetValue("", 'powershell.exe -WindowStyle Hidden "Start-Process -Verb RunAs cmd.exe -ArgumentList @(''/c'',''start wt.exe'',''-p'',''"""PowerShell Core"""'',''-d'',''"""%V\."""'')"', $ValueKind)
	$CommandKey.Close()

	$SubKey.Close()
	$ShellKey.Close()
	$BackgroundKey.Close()
	$RootKey.Close()
	$BaseKey.Dispose()
}

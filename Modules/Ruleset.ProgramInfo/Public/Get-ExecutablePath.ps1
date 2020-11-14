
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

<#
.SYNOPSIS
Get list of install locations for executables and executable names

.DESCRIPTION
Returns a table of installed programs, with executable name, installation path,
registry path and child registry key name for target computer

.PARAMETER ComputerName
Computer name which to check

.EXAMPLE
PS> Get-ExecutablePath "COMPUTERNAME"

.INPUTS
None. You cannot pipe objects to Get-ExecutablePath

.OUTPUTS
[PSCustomObject] list of executables, their installation path and additional information

.NOTES
TODO: Name parameter accepting wildcard, why not getting specifics out?
#>
function Get-ExecutablePath
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-ExecutablePath.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
				# NOTE: It looks like this key is exact duplicate, not used
				# even if there are both 32 and 64 bit, 32 bit applications on 64 bit system the path will point to 64 bit application
				# "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths"
			)
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		[PSCustomObject[]] $AppPaths = @()
		foreach ($HKLMRootKey in $HKLM)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLMRootKey"
			$RootKey = $RemoteKey.OpenSubkey($HKLMRootKey)

			if (!$RootKey)
			{
				Write-Warning -Message "Failed to open registry root key: HKLM:$HKLMRootKey"
				continue
			}

			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey);

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub Key: $HKLMSubKey"
					continue
				}

				# Default key can be empty
				[string] $FilePath = $SubKey.GetValue("")
				if (![string]::IsNullOrEmpty($FilePath))
				{
					# Strip away quotations from path
					$FilePath = $FilePath.Trim('"')
					$FilePath = $FilePath.Trim("'")

					# Replace double slashes with single ones
					$FilePath = $FilePath.Replace("\\", "\")

					# Get only executable name
					$Executable = Split-Path -Path $FilePath -Leaf
				}

				# Path can be empty
				$InstallLocation = $SubKey.GetValue("Path")
				if (![string]::IsNullOrEmpty($InstallLocation))
				{
					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false
				}
				elseif (![string]::IsNullOrEmpty($FilePath))
				{
					# Get install location from Default key
					$InstallLocation = Split-Path -Path $FilePath -Parent
					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false
				}

				# Some executables may have duplicate entries (keys related to executable)
				# Select only those which have a valid path (original executable keys)
				if ([string]::IsNullOrEmpty($InstallLocation))
				{
					# NOTE: Avoid spamming
					# Write-Debug -Message "Ignoring useless key: $HKLMSubKey"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

				# Get more key entries as needed
				# We want to separate leaf key name because some key names are holding alternative executable name
				$AppPaths += [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $HKLMSubKey
					#"RegPath" = $SubKey.Name
					"Name" = $Executable
					"InstallLocation" = $InstallLocation
				}
			}
		}

		Write-Output $AppPaths
	}
}

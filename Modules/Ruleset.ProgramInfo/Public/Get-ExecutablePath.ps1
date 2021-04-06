
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
Get a list of install locations for executable files

.DESCRIPTION
Returns a table of installed programs, with executable name, installation path,
registry path and child registry key name for target computer

.PARAMETER Domain
Computer name which to check

.EXAMPLE
PS> Get-ExecutablePath

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
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-TargetComputer $Domain)
	{
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				# https://docs.microsoft.com/en-us/windows/win32/shell/app-registration
				"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
				# TODO: It looks like WOW6432Node key contains exact duplicate, maybe -Unique sort?
				# TODO: Not clear whether we need Registry32 view for this key?
				# "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths"
			)
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return
		}

		foreach ($HKLMRootKey in $HKLM)
		{
			try
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLMRootKey"
				$RootKey = $RemoteKey.OpenSubkey($HKLMRootKey, $RegistryPermission, $RegistryRights)
			}
			catch
			{
				Write-Warning -Message "Failed to open registry root key: HKLM:$HKLMRootKey"
				continue
			}

			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey);

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
					# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key: $HKLMSubKey"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

				# Getting more key entries not possible in this leaf key
				# NOTE: Some key names are named as alternative executable name
				[PSCustomObject]@{
					Domain = $Domain
					Name = $Executable
					InstallLocation = $InstallLocation
					RegistryKey = $SubKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}
		}

		$RemoteKey.Dispose()
	}
}

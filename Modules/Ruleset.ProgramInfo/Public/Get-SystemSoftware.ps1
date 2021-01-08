
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Search installed programs for all users, system wide

.DESCRIPTION
Get a list of software installed system wide, for all users.

.PARAMETER Domain
Computer name which to check

.EXAMPLE
PS> Get-SystemSoftware

.EXAMPLE
PS> Get-SystemSoftware "Server01"

.INPUTS
None. You cannot pipe objects to Get-SystemSoftware

.OUTPUTS
[PSCustomObject] list of programs installed for all users

.NOTES
We should return empty PSCustomObject if test computer fails
TODO: Parameter for x64 vs x86 software, then update Search-Installation switch as needed
#>
function Get-SystemSoftware
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemSoftware.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-TargetComputer $Domain)
	{
		# TODO: Test-Path those keys first?
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = @(
				"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
				"SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
			)
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain)

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
				# NOTE: Avoid spamming
				# Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey);

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub Key: $HKLMSubKey"
					continue
				}

				# First we get InstallLocation by normal means
				# Strip away quotations and ending backslash
				$InstallLocation = $SubKey.GetValue("InstallLocation")

				# NOTE: Avoid spamming
				$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

				if ([string]::IsNullOrEmpty($InstallLocation))
				{
					# Some programs don't install InstallLocation entry
					# so let's take a look at DisplayIcon which is the path to executable
					# then strip off all of the junk to get clean and relevant directory output
					$InstallLocation = $SubKey.GetValue("DisplayIcon")

					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

					# regex to remove: \whatever.exe at the end
					$InstallLocation = $InstallLocation -Replace "\\(?:.(?!\\))+exe$", ""
					# once exe is removed, remove uninstall folder too if needed
					#$InstallLocation = $InstallLocation -Replace "\\uninstall$", ""

					if ([string]::IsNullOrEmpty($InstallLocation) -or
						$InstallLocation -like "*{*}*" -or
						$InstallLocation -like "*.exe*")
					{
						# NOTE: Avoid spamming
						# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key: $HKLMSubKey"
						continue
					}
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

				# Get more key entries as needed
				[PSCustomObject]@{
					Domain = $Domain
					Name = $SubKey.GetValue("DisplayName")
					Version = $SubKey.GetValue("DisplayVersion")
					Publisher = $SubKey.GetValue("Publisher")
					InstallLocation = $InstallLocation
					RegistryKey = $SubKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}
		}
	}
}

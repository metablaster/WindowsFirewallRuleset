
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
Search program install properties for all users, system wide

.DESCRIPTION
Search separate location in the registry for programs installed for all users.

.PARAMETER Domain
Computer name which to check

.EXAMPLE
PS> Get-InstallProperties

.EXAMPLE
PS> Get-InstallProperties "COMPUTERNAME"

.INPUTS
None. You cannot pipe objects to Get-InstallProperties

.OUTPUTS
[PSCustomObject] list of programs installed for all users

.NOTES
TODO: Should be renamed to something that best describes target registry key
#>
function Get-InstallProperties
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-InstallProperties.md")]
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
		# TODO: this key may not exist on fresh installed systems, tested in fresh installed Windows Server 2019
		$HKLM = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($HKLSubMKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLSubMKey\Products"
				$UserProducts = $RootKey.OpenSubkey("$HKLSubMKey\Products")

				if (!$UserProducts)
				{
					Write-Warning -Message "Failed to open UserKey: $HKLSubMKey\Products"
					continue
				}

				foreach ($HKLMKey in $UserProducts.GetSubKeyNames())
				{
					# NOTE: Avoid spamming (set to debug from verbose)
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMKey\InstallProperties"
					$ProductKey = $UserProducts.OpenSubkey("$HKLMKey\InstallProperties")

					if (!$ProductKey)
					{
						Write-Warning -Message "Failed to open ProductKey: $HKLMKey\InstallProperties"
						continue
					}

					$InstallLocation = $ProductKey.GetValue("InstallLocation")

					if ([string]::IsNullOrEmpty($InstallLocation))
					{
						# NOTE: Avoid spamming
						# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key: $HKLMKey\InstallProperties"
						continue
					}

					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMKey\InstallProperties"

					# NOTE: Avoid spamming
					$InstallLocation = Format-Path $InstallLocation -Verbose:$false -Debug:$false

					# TODO: generate Principal entry in all registry functions
					# Get more key entries as needed
					[PSCustomObject]@{
						Domain = $Domain
						Name = $ProductKey.GetValue("DisplayName")
						Version = $ProductKey.GetValue("DisplayVersion")
						Publisher = $ProductKey.GetValue("Publisher")
						InstallLocation = $InstallLocation
						RegistryKey = $ProductKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
						# SIDKey = $HKLSubMKey
						PSTypeName = "Ruleset.ProgramInfo"
					}
				}
			}
		}
	}
}

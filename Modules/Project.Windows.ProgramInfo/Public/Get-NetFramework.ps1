
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
Get installed NET Frameworks
.DESCRIPTION
Get-NetFramework will return all NET frameworks installed regardless if
installation directory exists or not, since some versions are built in
.PARAMETER ComputerName
Computer name for which to list installed installed framework
.EXAMPLE
PS> Get-NetFramework COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-NetFramework
.OUTPUTS
[PSCustomObject[]] for installed NET Frameworks and install paths
.NOTES
None.
#>
function Get-NetFramework
{
	[OutputType([PSCustomObject[]])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-NetFramework.md")]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		$HKLM = "SOFTWARE\Microsoft\NET Framework Setup\NDP"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
		$RootKey = $RemoteKey.OpenSubkey($HKLM)

		[PSCustomObject[]] $NetFramework = @()
		if (!$RootKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKLM:$HKLM"
		}
		else
		{
			foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
				$SubKey = $RootKey.OpenSubkey($HKLMSubKey)

				if (!$SubKey)
				{
					Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
					continue
				}

				$Version = $SubKey.GetValue("Version")
				if (![string]::IsNullOrEmpty($Version))
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey"

					$InstallLocation = $SubKey.GetValue("InstallPath")

					# else not warning because some versions are built in
					if (![string]::IsNullOrEmpty($InstallLocation))
					{
						$InstallLocation = Format-Path $InstallLocation
					}

					# we add entry regardless of presence of install path
					$NetFramework += [PSCustomObject]@{
						"ComputerName" = $ComputerName
						"RegKey" = $HKLMSubKey
						"Version" = $Version
						"InstallLocation" = $InstallLocation
					}
				}
				else # go one key down
				{
					foreach ($HKLMKey in $SubKey.GetSubKeyNames())
					{
						Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMKey"
						$Key = $SubKey.OpenSubkey($HKLMKey)

						if (!$Key)
						{
							Write-Warning -Message "Failed to open registry sub Key: $HKLMKey"
							continue
						}

						$Version = $Key.GetValue("Version")
						if ([string]::IsNullOrEmpty($Version))
						{
							Write-Warning -Message "Failed to read registry key entry: $HKLMKey\Version"
							continue
						}

						Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMKey"

						$InstallLocation = $Key.GetValue("InstallPath")

						# else not warning because some versions are built in
						if (![string]::IsNullOrEmpty($InstallLocation))
						{
							$InstallLocation = Format-Path $InstallLocation
						}

						# we add entry regardless of presence of install path
						$NetFramework += [PSCustomObject]@{
							"ComputerName" = $ComputerName
							"RegKey" = $HKLMKey
							"Version" = $Version
							"InstallLocation" = $InstallLocation
						}
					}
				}
			}
		}

		Write-Output $NetFramework
	}
}


<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Get installed .NET Frameworks

.DESCRIPTION
Get-NetFramework will return all NET frameworks installed regardless if
installation directory exists or not, since some versions are built in

.PARAMETER Domain
Computer name for which to list installed installed framework

.EXAMPLE
PS> Get-NetFramework

.EXAMPLE
PS> Get-NetFramework COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Get-NetFramework

.OUTPUTS
[PSCustomObject] for installed NET Frameworks and install paths

.NOTES
None.
#>
function Get-NetFramework
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-NetFramework.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	# Replace localhost and dot with NETBIOS computer name
	if (($Domain -eq "localhost") -or ($Domain -eq "."))
	{
		$Domain = [System.Environment]::MachineName
	}

	if (Test-Computer $Domain)
	{
		$HKLM = "SOFTWARE\Microsoft\NET Framework Setup\NDP"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
			$RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $RegistryRights)

			if (!$RootKey)
			{
				throw [System.Data.ObjectNotFoundException]::new("Following registry key does not exist: $HKLM")
			}
		}
		catch
		{
			if ($RemoteKey)
			{
				$RemoteKey.Dispose()
			}

			Write-Error -ErrorRecord $_
			return
		}

		foreach ($HKLMSubKey in $RootKey.GetSubKeyNames())
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey"
			$SubKey = $RootKey.OpenSubkey($HKLMSubKey)

			if (!$SubKey)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to open registry sub key: $HKLMSubKey"
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
				[PSCustomObject]@{
					Domain = $Domain
					Version = $Version
					InstallLocation = $InstallLocation
					RegistryKey = $SubKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}
			else # go one key down
			{
				$SubkeyNames = $SubKey.GetSubKeyNames()
				if (($SubkeyNames -contains "Full") -and ($SubkeyNames -contains "Client"))
				{
					$SubkeyNames = $SubkeyNames | Where-Object { $_ -ne "Client" }
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Removing sub key: $HKLMSubKey\Client to avoid duplicate entries"
				}

				foreach ($HKLMKey in $SubkeyNames)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: $HKLMSubKey\$HKLMKey"
					$Key = $SubKey.OpenSubkey($HKLMKey)

					if (!$Key)
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to open registry sub Key: $HKLMSubKey\$HKLMKey"
						continue
					}

					$Version = $Key.GetValue("Version")
					if ([string]::IsNullOrEmpty($Version))
					{
						# NOTE: CDF subkeys never contain version
						if ($HKLMSubKey -ne "CDF")
						{
							Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to read registry key entry: $HKLMSubKey\$HKLMKey\Version"
						}

						continue
					}

					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $HKLMSubKey\$HKLMKey"

					$InstallLocation = $Key.GetValue("InstallPath")

					# else not warning because some versions are built in
					if (![string]::IsNullOrEmpty($InstallLocation))
					{
						$InstallLocation = Format-Path $InstallLocation
					}

					# we add entry regardless of presence of install path
					[PSCustomObject]@{
						Domain = $Domain
						Name = ".NET Framework"
						Version = $Version
						Publisher = "Microsoft Corporation"
						InstallLocation = $InstallLocation
						RegistryKey = $Key.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
						PSTypeName = "Ruleset.ProgramInfo"
					}
				}
			}
		}

		$RemoteKey.Dispose()
	}
}

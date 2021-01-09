
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
Get installed Windows Kits

.DESCRIPTION
Get installation information about installed Windows Kit's

.PARAMETER Domain
Computer name for which to list installed installed windows kits

.EXAMPLE
PS> Get-WindowsKit

.EXAMPLE
PS> Get-WindowsKit Server01

.INPUTS
None. You cannot pipe objects to Get-WindowsKit

.OUTPUTS
[PSCustomObject] for installed Windows Kits versions and install paths

.NOTES
None.
#>
function Get-WindowsKit
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-WindowsKit.md")]
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
		if ([System.Environment]::Is64BitOperatingSystem)
		{
			# 64 bit system
			$HKLM = "SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Windows Kits\Installed Roots"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
		# TODO: try catch for remote registry access
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
			foreach ($RootKeyEntry in $RootKey.GetValueNames())
			{
				$RootKeyLeaf = Split-Path $RootKey.ToString() -Leaf
				$InstallLocation = $RootKey.GetValue($RootKeyEntry)

				if ([string]::IsNullOrEmpty($InstallLocation))
				{
					Write-Warning -Message "Failed to read registry key entry: $RootKeyLeaf\$RootKeyEntry"
					continue
				}
				elseif ($InstallLocation -notlike "C:\Program Files*")
				{
					# NOTE: Avoid spamming
					# Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring useless key entry: $RootKeyLeaf\$RootKeyEntry"
					continue
				}

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key entry: $RootKeyLeaf\$RootKeyEntry"
				$InstallLocation = Format-Path $InstallLocation

				[PSCustomObject]@{
					Domain = $Domain
					Name = "Windows Kits"
					# TODO: Version unknown
					Publisher = "Microsoft Corporation"
					InstallLocation = $InstallLocation
					RegistryKey = "$($RootKey.ToString())\$RootKeyEntry" -replace "HKEY_LOCAL_MACHINE", "HKLM:"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}
		}
	}
}

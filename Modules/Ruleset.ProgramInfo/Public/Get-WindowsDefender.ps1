
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
Get installed Windows Defender

.DESCRIPTION
Gets installation information about Windows defender.

.PARAMETER Domain
Computer name for which to list installed Windows Defender

.EXAMPLE
PS> Get-WindowsDefender

.EXAMPLE
PS> Get-WindowsDefender Server01

.INPUTS
None. You cannot pipe objects to Get-WindowsDefender

.OUTPUTS
[PSCustomObject] for installed Windows Defender, version and install paths

.NOTES
None.
#>
function Get-WindowsDefender
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-WindowsDefender.md")]
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
		$HKLM = "SOFTWARE\Microsoft\Windows Defender"

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
			$RootKeyLeaf = Split-Path $RootKey.ToString() -Leaf
			$InstallLocation = $RootKey.GetValue("InstallLocation")

			if ([string]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "Failed to read registry key entry: $RootKeyLeaf\InstallLocation"
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $RootKeyLeaf"

				[PSCustomObject]@{
					Domain = $Domain
					Name = "Windows Defender"
					Version = (Split-Path $InstallLocation -Leaf)
					Publisher = "Microsoft Corporation"
					InstallLocation = Format-Path $InstallLocation
					RegistryKey = $RootKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}
		}
	}
}

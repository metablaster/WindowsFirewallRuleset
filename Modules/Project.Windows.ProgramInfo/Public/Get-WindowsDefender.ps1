
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
Get installed Windows Defender
.DESCRIPTION
TODO: add description
.PARAMETER ComputerName
Computer name for which to list installed Windows Defender
.EXAMPLE
PS> Get-WindowsDefender COMPUTERNAME
.INPUTS
None. You cannot pipe objects to Get-WindowsDefender
.OUTPUTS
[PSCustomObject] for installed Windows Defender, version and install paths
.NOTES
None.
#>
function Get-WindowsDefender
{
	[OutputType([System.Management.Automation.PSCustomObject])]
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-WindowsDefender.md")]
	param (
		[Alias("Computer", "Server", "Domain", "Host", "Machine")]
		[Parameter()]
		[string] $ComputerName = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $ComputerName"

	if (Test-TargetComputer $ComputerName)
	{
		$HKLM = "SOFTWARE\Microsoft\Windows Defender"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $ComputerName"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

		[PSCustomObject] $WindowsDefender = $null
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

				$WindowsDefender = [PSCustomObject]@{
					"ComputerName" = $ComputerName
					"RegKey" = $RootKeyLeaf
					"InstallLocation" = Format-Path $InstallLocation
				}
			}
		}

		return $WindowsDefender
	}
}

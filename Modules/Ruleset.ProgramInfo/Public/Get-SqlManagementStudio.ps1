
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
Get installed Microsoft SQL Server Management Studios

.DESCRIPTION
Get all instances of installed Microsoft SQL Server Management Studios from local
or remote machine.

.PARAMETER Domain
Computer name for which to list installed installed framework

.EXAMPLE
PS> Get-SqlManagementStudio SERVER01

Domain       Name                                       InstallLocation
------       ----                                       ---------------
SERVER01     Microsoft SQL Server Management Studio     %ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18

.INPUTS
None. You cannot pipe objects to Get-SqlManagementStudio

.OUTPUTS
[PSCustomObject] for installed Microsoft SQL Server Management Studio's

.NOTES
None.
#>
function Get-SqlManagementStudio
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlManagementStudio.md")]
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
			# NOTE: in the far future this might need to be updated, if SSMS becomes x64 bit
			$HKLM = "SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server Management Studio"
		}
		else
		{
			# 32 bit system
			$HKLM = "SOFTWARE\Microsoft\Microsoft SQL Server Management Studio"
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:$HKLM"
			$RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $RegistryRights)
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
				Write-Warning -Message "Failed to open registry sub key: $HKLMSubKey"
				continue
			}

			$InstallLocation = $SubKey.GetValue("SSMSInstallRoot")

			if ([string]::IsNullOrEmpty($InstallLocation))
			{
				Write-Warning -Message "Failed to read registry key entry $HKLMSubKey\SSMSInstallRoot"
				continue
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing registry key: $HKLMSubKey"

			[PSCustomObject]@{
				Domain = $Domain
				Name = "Microsoft SQL Server Management Studio"
				Version = $SubKey.GetValue("Version")
				Publisher = "Microsoft Corporation"
				InstallLocation = Format-Path $InstallLocation
				RegistryKey = $SubKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
				PSTypeName = "Ruleset.ProgramInfo"
			}
		}

		$RemoteKey.Dispose()
	}
}

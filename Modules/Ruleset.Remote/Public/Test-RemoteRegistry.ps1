
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022 metablaster zebal@protonmail.ch

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
Test remote registry service

.DESCRIPTION
Test-RemoteRegistry tests for functioning remote registry

.PARAMETER Domain
Remote computer name against which remote registry is to be tested

.PARAMETER Quiet
If specified, no warning is shown, only true or false is returned

.EXAMPLE
PS> Test-RemoteRegistry -Domain Server01

.INPUTS
None. You cannot pipe objects to Test-RemoteRegistry

.OUTPUTS
[bool]

.NOTES
TODO: Need to test if there is authentication with PSDrive

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-RemoteRegistry.md
#>
function Test-RemoteRegistry
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-RemoteRegistry.md")]
	[OutputType([bool])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName,

		[Parameter()]
		[switch] $Quiet
	)

	if ($PSCmdlet.ShouldProcess($Domain, "Test remote registry service"))
	{
		if ($Quiet)
		{
			$ErrorActionPreference = "SilentlyContinue"
			$WarningPreference = "SilentlyContinue"
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking remote registry service"
		$StartupType = Get-Service -Name RemoteRegistry | Select-Object -ExpandProperty StartType

		# Manual and automatic will trigger service start
		if ($StartupType -eq "Disabled")
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Remote registry service is disabled"
			return $false
		}

		$HKLM = "SOFTWARE\Microsoft\Windows"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer '$Domain'"
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)
		}
		catch [System.UnauthorizedAccessException]
		{
			Write-Error -Category AuthenticationError -TargetObject $RegistryHive -Message $_.Exception.Message
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Remote registry access was denied by $Domain"
			return $false
		}
		catch [System.Security.SecurityException]
		{
			Write-Error -Category SecurityError -TargetObject $RegistryHive -Message $_.Exception.Message
			Write-Warning -Message "[$($MyInvocation.InvocationName)] $($RemotingCredential.UserName) does not have the requested ACL permissions for $RegistryHive hive"
			return $false
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return $false
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:\$HKLM"
			$RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $RegistryRights)

			if (!$RootKey)
			{
				throw [System.Data.ObjectNotFoundException]::new("The following registry key does not exist: HKLM:\$HKLM")
			}
		}
		catch [System.Security.SecurityException]
		{
			Write-Error -Category SecurityError -TargetObject $HKLM -Message $_.Exception.Message
			Write-Warning -Message "[$($MyInvocation.InvocationName)] $($RemotingCredential.UserName) does not have the requested ACL permissions for $HKLM key"
			return $false
		}
		catch
		{
			Write-Error -ErrorRecord $_
			return $false
		}
		finally
		{
			$RemoteKey.Dispose()
		}

		return $true
	}
}
